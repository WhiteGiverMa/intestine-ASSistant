"""AI分析路由模块。

@module: ai
@type: router
@layer: backend
@prefix: /ai
@depends: [models.BowelRecord, models.AIConversation, models.AIMessage, services.llm_service, services.local_analysis, routers.auth.get_current_user]
@exports: [router]
@api:
  - POST /analyze - 本地健康分析
  - GET /analyses - 获取分析历史
  - POST /chat - AI对话
  - POST /chat/stream - 流式AI对话
  - GET /chat/history - 获取对话历史
  - DELETE /chat - 清除对话
  - GET /conversations - 获取对话列表
  - PATCH /conversations/{id} - 更新对话
  - DELETE /conversations/{id} - 删除对话
  - GET /status - 获取AI配置状态
@features:
  - 本地规则分析: 基于布里斯托分类的健康评分
  - AI对话: 调用外部API的智能对话
  - 流式响应: 支持SSE流式输出
"""

import json
from collections.abc import AsyncIterator

from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from sqlalchemy import delete, select
from sqlalchemy import func as sql_func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import AIAnalysis, AIConversation, AIMessage, BowelRecord, User
from app.routers.records import get_current_user
from app.services.llm_service import llm_service
from app.services.local_analysis import build_records_context, perform_local_analysis

router = APIRouter()


class AnalyzeRequest(BaseModel):
    analysis_type: str = "weekly"
    start_date: str | None = None
    end_date: str | None = None


class ChatRequest(BaseModel):
    message: str
    conversation_id: str | None = None
    records_start_date: str | None = None
    records_end_date: str | None = None
    system_prompt: str | None = None
    thinking_intensity: str | None = None


class ChatStreamRequest(BaseModel):
    message: str
    conversation_id: str | None = None
    records_start_date: str | None = None
    records_end_date: str | None = None
    system_prompt: str | None = None
    thinking_intensity: str | None = None


class UpdateConversationRequest(BaseModel):
    title: str | None = None
    system_prompt: str | None = None
    thinking_intensity: str | None = None


@router.get("/conversations", response_model=dict)
async def get_conversations(
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    """获取用户所有对话列表。

    返回对话ID、标题、创建时间、更新时间、消息数量
    """
    result = await db.execute(
        select(
            AIConversation.id,
            AIConversation.title,
            AIConversation.system_prompt,
            AIConversation.thinking_intensity,
            AIConversation.created_at,
            AIConversation.updated_at,
            sql_func.count(AIMessage.id).label("message_count"),
        )
        .outerjoin(AIMessage, AIConversation.id == AIMessage.conversation_id)
        .where(AIConversation.user_id == current_user.id)
        .group_by(AIConversation.id)
        .order_by(AIConversation.updated_at.desc())
    )
    conversations = result.fetchall()

    return {
        "code": 200,
        "data": {
            "conversations": [
                {
                    "conversation_id": conv.id,
                    "title": conv.title,
                    "system_prompt": conv.system_prompt,
                    "thinking_intensity": conv.thinking_intensity,
                    "created_at": str(conv.created_at),
                    "updated_at": str(conv.updated_at),
                    "message_count": conv.message_count,
                }
                for conv in conversations
            ]
        },
    }


@router.patch("/conversations/{conversation_id}", response_model=dict)
async def update_conversation(
    conversation_id: str,
    request: UpdateConversationRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """更新对话信息（标题、系统提示词、思考强度）"""
    result = await db.execute(
        select(AIConversation).where(
            AIConversation.id == conversation_id, AIConversation.user_id == current_user.id
        )
    )
    conversation = result.scalar_one_or_none()

    if not conversation:
        return {"code": 404, "data": {"message": "Conversation not found"}}

    if request.title is not None:
        conversation.title = request.title
    if request.system_prompt is not None:
        conversation.system_prompt = request.system_prompt
    if request.thinking_intensity is not None:
        conversation.thinking_intensity = request.thinking_intensity

    await db.commit()
    await db.refresh(conversation)

    return {
        "code": 200,
        "data": {
            "conversation_id": conversation.id,
            "title": conversation.title,
            "system_prompt": conversation.system_prompt,
            "thinking_intensity": conversation.thinking_intensity,
            "updated_at": str(conversation.updated_at),
        },
    }


@router.delete("/conversations/{conversation_id}", response_model=dict)
async def delete_conversation(
    conversation_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """删除单个对话及其所有消息"""
    result = await db.execute(
        select(AIConversation).where(
            AIConversation.id == conversation_id, AIConversation.user_id == current_user.id
        )
    )
    conversation = result.scalar_one_or_none()

    if not conversation:
        return {"code": 404, "data": {"message": "Conversation not found"}}

    await db.execute(delete(AIMessage).where(AIMessage.conversation_id == conversation_id))
    await db.execute(delete(AIConversation).where(AIConversation.id == conversation_id))
    await db.commit()

    return {"code": 200, "data": {"message": "Conversation deleted successfully"}}


@router.post("/analyze", response_model=dict)
async def analyze(
    request: AnalyzeRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """执行本地排便健康分析

    分析流程：
    1. 根据分析类型（周/月）确定时间范围
    2. 查询用户的排便记录
    3. 计算统计数据
    4. 使用本地规则进行分析（纯本地计算，不调用外部API）
    5. 保存分析结果并返回

    注意：
    - 本地分析功能完全基于规则计算，不涉及任何外部API调用
    - 如需AI智能分析，请使用AI对话功能
    """
    from datetime import datetime, timedelta

    today = datetime.now().date()
    if request.analysis_type == "weekly":
        start_date = request.start_date or (today - timedelta(days=7)).isoformat()
        end_date = request.end_date or today.isoformat()
    elif request.analysis_type == "monthly":
        start_date = request.start_date or (today - timedelta(days=30)).isoformat()
        end_date = request.end_date or today.isoformat()
    else:
        start_date = request.start_date or (today - timedelta(days=7)).isoformat()
        end_date = request.end_date or today.isoformat()

    result = await db.execute(
        select(BowelRecord).where(
            BowelRecord.user_id == current_user.id,
            BowelRecord.record_date >= start_date,
            BowelRecord.record_date <= end_date,
        )
    )
    records = result.scalars().all()

    if not records:
        return {
            "code": 200,
            "data": {
                "analysis_id": None,
                "health_score": 0,
                "insights": [],
                "suggestions": [],
                "warnings": [{"type": "no_data", "message": "暂无数据，请先记录排便情况"}],
                "analysis_source": "none",
            },
        }

    analysis_result = await perform_local_analysis(records, start_date, end_date)

    analysis = AIAnalysis(
        user_id=current_user.id,
        analysis_type=request.analysis_type,
        period_start=start_date,
        period_end=end_date,
        health_score=analysis_result["health_score"],
        insights=json.dumps(analysis_result["insights"], ensure_ascii=False),
        suggestions=json.dumps(analysis_result["suggestions"], ensure_ascii=False),
        warnings=json.dumps(analysis_result.get("warnings", []), ensure_ascii=False),
        model_version="1.0-local",
    )
    db.add(analysis)
    await db.commit()
    await db.refresh(analysis)

    return {
        "code": 200,
        "data": {
            "analysis_id": analysis.id,
            "health_score": analysis_result["health_score"],
            "insights": analysis_result["insights"],
            "suggestions": analysis_result["suggestions"],
            "warnings": analysis_result.get("warnings", []),
            "analysis_source": "local",
        },
    }


@router.get("/analyses", response_model=dict)
async def get_analyses(
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    """获取用户的历史分析记录。

    返回最近10条分析记录，按创建时间倒序排列
    """
    result = await db.execute(
        select(AIAnalysis)
        .where(AIAnalysis.user_id == current_user.id)
        .order_by(AIAnalysis.created_at.desc())
        .limit(10)
    )
    analyses = result.scalars().all()

    return {
        "code": 200,
        "data": {
            "analyses": [
                {
                    "analysis_id": a.id,
                    "analysis_type": a.analysis_type,
                    "period_start": a.period_start,
                    "period_end": a.period_end,
                    "health_score": a.health_score,
                    "insights": json.loads(a.insights),
                    "created_at": str(a.created_at),
                    "model_version": a.model_version,
                }
                for a in analyses
            ]
        },
    }


@router.post("/chat", response_model=dict)
async def chat(
    request: ChatRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from datetime import datetime

    if request.conversation_id:
        result = await db.execute(
            select(AIConversation).where(
                AIConversation.id == request.conversation_id,
                AIConversation.user_id == current_user.id,
            )
        )
        conversation = result.scalar_one_or_none()
        if not conversation:
            return {"code": 404, "data": {"message": "Conversation not found"}}
    else:
        conversation = AIConversation(
            user_id=current_user.id,
            title=request.message[:50] if len(request.message) > 50 else request.message,
            system_prompt=request.system_prompt,
            thinking_intensity=request.thinking_intensity or "medium",
        )
        db.add(conversation)
        await db.commit()
        await db.refresh(conversation)

    user_message = AIMessage(conversation_id=conversation.id, role="user", content=request.message)
    db.add(user_message)
    await db.commit()
    await db.refresh(user_message)

    records_context = None
    if request.records_start_date and request.records_end_date:
        result = await db.execute(
            select(BowelRecord).where(
                BowelRecord.user_id == current_user.id,
                BowelRecord.record_date >= request.records_start_date,
                BowelRecord.record_date <= request.records_end_date,
            )
        )
        records = result.scalars().all()
        if records:
            records_context = build_records_context(records)

    result = await db.execute(
        select(AIMessage)
        .where(AIMessage.conversation_id == conversation.id)
        .order_by(AIMessage.created_at)
    )
    history_messages = result.scalars().all()
    messages = [{"role": msg.role, "content": msg.content} for msg in history_messages]

    system_prompt = (
        request.system_prompt or conversation.system_prompt or current_user.default_system_prompt
    )
    thinking_intensity = request.thinking_intensity or conversation.thinking_intensity

    llm_result = await llm_service.chat(
        messages=messages,
        user_api_key=current_user.ai_api_key,
        user_api_url=current_user.ai_api_url,
        user_model=current_user.ai_model,
        records_context=records_context,
        system_prompt=system_prompt,
        thinking_intensity=thinking_intensity,
    )

    ai_response = llm_result.get("content")
    thinking_content = llm_result.get("thinking_content")

    if not ai_response:
        ai_response = "Sorry, unable to connect to AI service. Please check your API configuration."

    assistant_message = AIMessage(
        conversation_id=conversation.id, role="assistant", content=ai_response
    )
    db.add(assistant_message)
    await db.commit()
    await db.refresh(assistant_message)

    conversation.updated_at = datetime.now()
    await db.commit()

    # Generate title for new conversations after first exchange
    if not request.conversation_id and ai_response:
        if current_user.ai_auto_title:
            # Use AI to generate title
            try:
                generated_title = await llm_service.generate_conversation_title(
                    user_message=request.message,
                    ai_response=ai_response,
                    user_api_key=current_user.ai_api_key,
                    user_api_url=current_user.ai_api_url,
                    user_model=current_user.ai_model,
                )
                if generated_title:
                    conversation.title = generated_title
                    await db.commit()
            except Exception as e:
                print(f"Failed to generate conversation title: {e}")
        else:
            # Use local naming: first 20 chars of user message
            local_title = request.message[:20] if len(request.message) > 20 else request.message
            conversation.title = local_title
            await db.commit()

    return {
        "code": 200,
        "data": {
            "message_id": assistant_message.id,
            "conversation_id": conversation.id,
            "role": "assistant",
            "content": ai_response,
            "thinking_content": thinking_content,
            "created_at": str(assistant_message.created_at),
        },
    }


@router.post("/chat/stream")
async def chat_stream(
    request: ChatStreamRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from datetime import datetime

    # Track if this is a new conversation for title generation
    is_new_conversation = not request.conversation_id

    async def generate_stream() -> AsyncIterator[str]:
        nonlocal conversation

        records_context = None
        if request.records_start_date and request.records_end_date:
            result = await db.execute(
                select(BowelRecord).where(
                    BowelRecord.user_id == current_user.id,
                    BowelRecord.record_date >= request.records_start_date,
                    BowelRecord.record_date <= request.records_end_date,
                )
            )
            records = result.scalars().all()
            if records:
                records_context = build_records_context(records)

        result = await db.execute(
            select(AIMessage)
            .where(AIMessage.conversation_id == conversation.id)
            .order_by(AIMessage.created_at)
        )
        history_messages = result.scalars().all()
        messages = [{"role": msg.role, "content": msg.content} for msg in history_messages]

        system_prompt = (
            request.system_prompt
            or conversation.system_prompt
            or current_user.default_system_prompt
        )
        thinking_intensity = request.thinking_intensity or conversation.thinking_intensity

        full_content = ""
        full_thinking_content = ""

        async for chunk in llm_service.chat_stream(
            messages=messages,
            user_api_key=current_user.ai_api_key,
            user_api_url=current_user.ai_api_url,
            user_model=current_user.ai_model,
            records_context=records_context,
            system_prompt=system_prompt,
            thinking_intensity=thinking_intensity,
        ):
            if chunk.get("done"):
                break

            content = chunk.get("content", "")
            reasoning_content = chunk.get("reasoning_content", "")

            if content:
                full_content += content
            if reasoning_content:
                full_thinking_content += reasoning_content

            data = json.dumps(
                {"content": content, "reasoning_content": reasoning_content, "done": False},
                ensure_ascii=False,
            )
            yield f"data: {data}\n\n"

        assistant_message = AIMessage(
            conversation_id=conversation.id,
            role="assistant",
            content=full_content
            if full_content
            else "Sorry, unable to connect to AI service. Please check your API configuration.",
        )
        db.add(assistant_message)
        await db.commit()
        await db.refresh(assistant_message)

        conversation.updated_at = datetime.now()
        await db.commit()

        # Generate title for new conversations after first exchange
        if is_new_conversation and full_content:
            if current_user.ai_auto_title:
                # Use AI to generate title
                try:
                    generated_title = await llm_service.generate_conversation_title(
                        user_message=request.message,
                        ai_response=full_content,
                        user_api_key=current_user.ai_api_key,
                        user_api_url=current_user.ai_api_url,
                        user_model=current_user.ai_model,
                    )
                    if generated_title:
                        conversation.title = generated_title
                        await db.commit()
                except Exception as e:
                    print(f"Failed to generate conversation title: {e}")
            else:
                # Use local naming: first 20 chars of user message
                local_title = request.message[:20] if len(request.message) > 20 else request.message
                conversation.title = local_title
                await db.commit()

        data = json.dumps(
            {
                "content": "",
                "reasoning_content": "",
                "done": True,
                "message_id": assistant_message.id,
                "conversation_id": conversation.id,
                "created_at": str(assistant_message.created_at),
            },
            ensure_ascii=False,
        )
        yield f"data: {data}\n\n"

    if request.conversation_id:
        result = await db.execute(
            select(AIConversation).where(
                AIConversation.id == request.conversation_id,
                AIConversation.user_id == current_user.id,
            )
        )
        conversation = result.scalar_one_or_none()
        if not conversation:
            return {"code": 404, "data": {"message": "Conversation not found"}}
    else:
        conversation = AIConversation(
            user_id=current_user.id,
            title=request.message[:50] if len(request.message) > 50 else request.message,
            system_prompt=request.system_prompt,
            thinking_intensity=request.thinking_intensity or "medium",
        )
        db.add(conversation)
        await db.commit()
        await db.refresh(conversation)

    user_message = AIMessage(conversation_id=conversation.id, role="user", content=request.message)
    db.add(user_message)
    await db.commit()
    await db.refresh(user_message)

    return StreamingResponse(
        generate_stream(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


@router.get("/chat/history", response_model=dict)
async def get_chat_history(
    conversation_id: str | None = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if conversation_id:
        result = await db.execute(
            select(AIConversation).where(
                AIConversation.id == conversation_id, AIConversation.user_id == current_user.id
            )
        )
        conversation = result.scalar_one_or_none()
        if not conversation:
            return {"code": 404, "data": {"message": "Conversation not found"}}
    else:
        result = await db.execute(
            select(AIConversation)
            .where(AIConversation.user_id == current_user.id)
            .order_by(AIConversation.updated_at.desc())
        )
        conversation = result.scalar_one_or_none()
        if not conversation:
            # Return empty response without creating a new conversation
            # Conversation will be created when user sends first message
            return {
                "code": 200,
                "data": {
                    "conversation_id": "",
                    "title": None,
                    "created_at": "",
                    "updated_at": "",
                    "messages": [],
                },
            }

    result = await db.execute(
        select(AIMessage)
        .where(AIMessage.conversation_id == conversation.id)
        .order_by(AIMessage.created_at)
    )
    messages = result.scalars().all()

    return {
        "code": 200,
        "data": {
            "conversation_id": conversation.id,
            "title": conversation.title,
            "created_at": str(conversation.created_at),
            "updated_at": str(conversation.updated_at),
            "messages": [
                {
                    "message_id": msg.id,
                    "conversation_id": msg.conversation_id,
                    "role": msg.role,
                    "content": msg.content,
                    "created_at": str(msg.created_at),
                }
                for msg in messages
            ],
        },
    }


@router.delete("/chat", response_model=dict)
async def clear_chat(
    conversation_id: str | None = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from sqlalchemy import delete

    if conversation_id:
        result = await db.execute(
            select(AIConversation).where(
                AIConversation.id == conversation_id, AIConversation.user_id == current_user.id
            )
        )
        conversation = result.scalar_one_or_none()
        if not conversation:
            return {"code": 404, "data": {"message": "Conversation not found"}}

        await db.execute(delete(AIMessage).where(AIMessage.conversation_id == conversation_id))
        await db.execute(delete(AIConversation).where(AIConversation.id == conversation_id))
        await db.commit()
    else:
        result = await db.execute(
            select(AIConversation.id).where(AIConversation.user_id == current_user.id)
        )
        conversation_ids = [row[0] for row in result.fetchall()]

        if conversation_ids:
            await db.execute(
                delete(AIMessage).where(AIMessage.conversation_id.in_(conversation_ids))
            )
            await db.execute(
                delete(AIConversation).where(AIConversation.user_id == current_user.id)
            )
            await db.commit()

    return {"code": 200, "data": {"message": "Conversation history cleared"}}


@router.get("/status", response_model=dict)
async def get_ai_status(
    current_user: User = Depends(get_current_user), _db: AsyncSession = Depends(get_db)
):
    has_api_key = bool(current_user.ai_api_key)
    has_api_url = bool(current_user.ai_api_url)
    has_model = bool(current_user.ai_model)
    is_configured = has_api_key and has_api_url and has_model

    return {
        "code": 200,
        "data": {
            "has_api_key": has_api_key,
            "has_api_url": has_api_url,
            "has_model": has_model,
            "is_configured": is_configured,
        },
    }
