from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel
from typing import Optional
import json

from app.database import get_db
from app.models import BowelRecord, AIAnalysis, User
from app.routers.records import get_current_user
from app.config import settings
from app.services.llm_service import llm_service

router = APIRouter()

class AnalyzeRequest(BaseModel):
    analysis_type: str = "weekly"
    start_date: Optional[str] = None
    end_date: Optional[str] = None

@router.post("/analyze", response_model=dict)
async def analyze(
    request: AnalyzeRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
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
            BowelRecord.record_date <= end_date
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
                "analysis_source": "none"
            }
        }
    
    stats_data = calculate_stats(records, start_date, end_date)
    records_data = [
        {
            "record_date": r.record_date,
            "record_time": r.record_time,
            "duration_minutes": r.duration_minutes,
            "stool_type": r.stool_type,
            "feeling": r.feeling,
            "notes": r.notes
        }
        for r in records
    ]
    
    llm_result = await llm_service.analyze_bowel_health(
        records_data, stats_data, request.analysis_type
    )
    
    if llm_result:
        analysis_result = llm_result
        analysis_source = "deepseek"
    else:
        analysis_result = await perform_local_analysis(records, start_date, end_date)
        analysis_source = "local"
    
    analysis = AIAnalysis(
        user_id=current_user.id,
        analysis_type=request.analysis_type,
        period_start=start_date,
        period_end=end_date,
        health_score=analysis_result["health_score"],
        insights=json.dumps(analysis_result["insights"], ensure_ascii=False),
        suggestions=json.dumps(analysis_result["suggestions"], ensure_ascii=False),
        warnings=json.dumps(analysis_result.get("warnings", []), ensure_ascii=False),
        model_version=f"1.0-{analysis_source}"
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
            "analysis_source": analysis_source
        }
    }

@router.get("/analyses", response_model=dict)
async def get_analyses(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(AIAnalysis).where(AIAnalysis.user_id == current_user.id)
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
                    "model_version": a.model_version
                }
                for a in analyses
            ]
        }
    }

def calculate_stats(records, start_date, end_date) -> dict:
    from collections import Counter
    from datetime import datetime
    
    total_records = len(records)
    days = (datetime.fromisoformat(end_date) - datetime.fromisoformat(start_date)).days or 1
    avg_frequency = round(total_records / days, 2)
    
    durations = [r.duration_minutes for r in records if r.duration_minutes]
    avg_duration = round(sum(durations) / len(durations), 1) if durations else 0
    
    stool_types = [r.stool_type for r in records if r.stool_type]
    type_dist = dict(Counter(stool_types))
    
    feelings = [r.feeling for r in records if r.feeling]
    feeling_dist = dict(Counter(feelings))
    
    time_dist = {"morning": 0, "afternoon": 0, "evening": 0}
    for r in records:
        hour = int(r.record_time.split(":")[0])
        if 6 <= hour < 12:
            time_dist["morning"] += 1
        elif 12 <= hour < 18:
            time_dist["afternoon"] += 1
        else:
            time_dist["evening"] += 1
    
    return {
        "total_records": total_records,
        "days": days,
        "avg_frequency": avg_frequency,
        "avg_duration": avg_duration,
        "type_dist": type_dist,
        "feeling_dist": feeling_dist,
        "time_dist": time_dist
    }

async def perform_local_analysis(records, start_date, end_date) -> dict:
    stats = calculate_stats(records, start_date, end_date)
    
    health_score = calculate_health_score(
        stats["avg_frequency"], 
        stats["avg_duration"], 
        stats["type_dist"], 
        stats["feeling_dist"]
    )
    
    insights = generate_insights(
        stats["avg_frequency"], 
        stats["avg_duration"], 
        stats["type_dist"], 
        stats["time_dist"], 
        stats["feeling_dist"]
    )
    suggestions = generate_suggestions(
        stats["avg_frequency"], 
        stats["avg_duration"], 
        stats["type_dist"], 
        stats["feeling_dist"]
    )
    warnings = generate_warnings(
        stats["avg_frequency"], 
        stats["avg_duration"], 
        stats["type_dist"], 
        stats["feeling_dist"]
    )
    
    return {
        "health_score": health_score,
        "insights": insights,
        "suggestions": suggestions,
        "warnings": warnings
    }

def calculate_health_score(avg_frequency, avg_duration, type_dist, feeling_dist) -> int:
    score = 60
    
    if 0.8 <= avg_frequency <= 2.5:
        score += 15
    elif 0.5 <= avg_frequency < 0.8 or 2.5 < avg_frequency <= 3:
        score += 5
    else:
        score -= 10
    
    if 3 <= avg_duration <= 15:
        score += 10
    elif 1 <= avg_duration < 3 or 15 < avg_duration <= 20:
        score += 5
    else:
        score -= 5
    
    healthy_types = type_dist.get(3, 0) + type_dist.get(4, 0)
    total_types = sum(type_dist.values()) or 1
    healthy_ratio = healthy_types / total_types
    score += int(healthy_ratio * 15)
    
    smooth_ratio = feeling_dist.get("smooth", 0) / (sum(feeling_dist.values()) or 1)
    score += int(smooth_ratio * 10)
    
    return min(100, max(0, score))

def generate_insights(avg_frequency, avg_duration, type_dist, time_dist, feeling_dist) -> list:
    insights = []
    
    peak_time = max(time_dist, key=time_dist.get)
    time_names = {"morning": "早晨", "afternoon": "下午", "evening": "晚上"}
    insights.append({
        "type": "pattern",
        "title": "排便时间规律",
        "description": f"您的排便时间主要集中在{time_names[peak_time]}，这是{'健康的' if peak_time == 'morning' else '正常的'}排便习惯。"
    })
    
    if type_dist:
        most_common_type = max(type_dist, key=type_dist.get)
        type_descriptions = {
            1: "便秘倾向（硬块状）",
            2: "轻度便秘（结块状）",
            3: "正常（有裂纹）",
            4: "理想状态（光滑柔软）",
            5: "缺乏纤维（断块状）",
            6: "轻度腹泻（糊状）",
            7: "腹泻（液体状）"
        }
        insights.append({
            "type": "stool_type",
            "title": "粪便形态分析",
            "description": f"您最常见的粪便形态为类型{most_common_type}（{type_descriptions.get(most_common_type, '未知')}）。"
        })
    
    if avg_frequency:
        if avg_frequency < 0.5:
            freq_status = "排便频率较低"
        elif avg_frequency > 3:
            freq_status = "排便频率较高"
        else:
            freq_status = "排便频率正常"
        insights.append({
            "type": "frequency",
            "title": "排便频率",
            "description": f"您平均每日排便{avg_frequency}次，{freq_status}。"
        })
    
    return insights

def generate_suggestions(avg_frequency, avg_duration, type_dist, feeling_dist) -> list:
    suggestions = []
    
    healthy_types = type_dist.get(3, 0) + type_dist.get(4, 0)
    total_types = sum(type_dist.values()) or 1
    if healthy_types / total_types < 0.5:
        suggestions.append({
            "category": "diet",
            "suggestion": "建议增加膳食纤维摄入，多吃蔬菜、水果和全谷物，有助于改善粪便形态。"
        })
    
    if avg_duration and avg_duration > 15:
        suggestions.append({
            "category": "habit",
            "suggestion": "排便时间较长可能提示便秘倾向，建议多喝水、适当运动，避免如厕时使用手机。"
        })
    
    if avg_frequency and avg_frequency < 0.8:
        suggestions.append({
            "category": "lifestyle",
            "suggestion": "排便频率较低，建议增加日常活动量，保持规律作息，必要时咨询医生。"
        })
    
    difficult_ratio = (feeling_dist.get("difficult", 0) + feeling_dist.get("painful", 0)) / (sum(feeling_dist.values()) or 1)
    if difficult_ratio > 0.3:
        suggestions.append({
            "category": "health",
            "suggestion": "排便困难或疼痛的情况较多，建议增加水分摄入，如症状持续请咨询医生。"
        })
    
    if not suggestions:
        suggestions.append({
            "category": "general",
            "suggestion": "您的肠道健康状况良好，请继续保持健康的生活习惯。"
        })
    
    return suggestions

def generate_warnings(avg_frequency, avg_duration, type_dist, feeling_dist) -> list:
    warnings = []
    
    if avg_frequency and avg_frequency > 4:
        warnings.append({
            "type": "high_frequency",
            "message": "排便频率异常高，可能存在腹泻问题，建议关注饮食并咨询医生。"
        })
    
    if avg_frequency and avg_frequency < 0.3:
        warnings.append({
            "type": "low_frequency",
            "message": "排便频率过低，可能存在便秘问题，建议增加膳食纤维和水分摄入。"
        })
    
    unhealthy_types = type_dist.get(1, 0) + type_dist.get(7, 0)
    total_types = sum(type_dist.values()) or 1
    if unhealthy_types / total_types > 0.3:
        warnings.append({
            "type": "abnormal_stool",
            "message": "粪便形态异常比例较高，建议关注饮食健康，如持续异常请咨询医生。"
        })
    
    return warnings
