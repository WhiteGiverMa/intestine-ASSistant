"""LLM服务封装模块。

@module: llm_service
@type: service
@layer: backend
@depends: [httpx]
@exports: [llm_service, LLMService]
@features:
  - chat: 多轮对话（支持思考模式）
  - chat_stream: 流式对话
  - generate_conversation_title: 生成对话标题
"""
import json

import httpx

DEFAULT_SYSTEM_PROMPT = """You are a professional gut health consultant. You can have friendly conversations with users, answer questions about gut health, and provide professional advice.

If the user shares bowel record data, please analyze and provide suggestions based on this data.

Please reply in Chinese, maintaining a professional yet friendly tone."""

THINKING_PARAMS = {
    "low": {"temperature": 0.7, "max_tokens": 1500},
    "medium": {"temperature": 0.5, "max_tokens": 2000},
    "high": {"temperature": 0.3, "max_tokens": 3000},
}


class LLMService:
    """LLM服务类：负责调用外部AI API进行AI对话

    说明：
    - 本服务仅用于AI对话功能（chat方法）
    - 本地分析功能完全独立于本服务，在ai.py中直接实现
    - 两个功能完全分离，互不影响
    """

    async def chat(
        self,
        messages: list[dict[str, str]],
        user_api_key: str | None = None,
        user_api_url: str | None = None,
        user_model: str | None = None,
        records_context: str | None = None,
        system_prompt: str | None = None,
        thinking_intensity: str | None = None,
    ) -> dict[str, str | None]:
        """Multi-turn conversation with deep thinking support

        Args:
            messages: List of conversation messages, each containing role and content
            user_api_key: User's custom API key
            user_api_url: User's custom API URL
            user_model: User's custom model name
            records_context: Bowel records context (optional)
            system_prompt: Custom system prompt (optional, uses default if not provided)
            thinking_intensity: Thinking intensity level: low/medium/high (optional)

        Returns:
            Dict with 'content' and 'thinking_content' keys, or None values if API call fails
        """
        if not user_api_key:
            return {"content": None, "thinking_content": None}

        if not user_api_url or not user_model:
            return {"content": None, "thinking_content": None}

        system_content = system_prompt if system_prompt else DEFAULT_SYSTEM_PROMPT

        if records_context:
            system_content += f"""

Here is the user's bowel record data for reference:
{records_context}"""

        formatted_messages = [{"role": "system", "content": system_content}]

        for msg in messages:
            formatted_messages.append(
                {"role": msg.get("role", "user"), "content": msg.get("content", "")}
            )

        request_params = {"model": user_model, "messages": formatted_messages}

        if thinking_intensity and thinking_intensity in THINKING_PARAMS:
            params = THINKING_PARAMS[thinking_intensity]
            request_params["temperature"] = params["temperature"]
            request_params["max_tokens"] = params["max_tokens"]
        else:
            request_params["temperature"] = 0.7
            request_params["max_tokens"] = 2000

        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                response = await client.post(
                    f"{user_api_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {user_api_key}",
                        "Content-Type": "application/json",
                    },
                    json=request_params,
                )

                if response.status_code == 200:
                    result = response.json()
                    message = result["choices"][0]["message"]
                    content = message.get("content")
                    thinking_content = message.get("reasoning_content")
                    return {"content": content, "thinking_content": thinking_content}
                print(f"LLM API error: {response.status_code} - {response.text}")
                return {"content": None, "thinking_content": None}

        except Exception as e:
            print(f"LLM chat exception: {e}")
            return {"content": None, "thinking_content": None}

    async def chat_stream(
        self,
        messages: list[dict[str, str]],
        user_api_key: str | None = None,
        user_api_url: str | None = None,
        user_model: str | None = None,
        records_context: str | None = None,
        system_prompt: str | None = None,
        thinking_intensity: str | None = None,
    ):
        """Multi-turn conversation with streaming support

        Args:
            messages: List of conversation messages, each containing role and content
            user_api_key: User's custom API key
            user_api_url: User's custom API URL
            user_model: User's custom model name
            records_context: Bowel records context (optional)
            system_prompt: Custom system prompt (optional, uses default if not provided)
            thinking_intensity: Thinking intensity level: low/medium/high (optional)

        Yields:
            Dict with 'content', 'reasoning_content', and 'done' keys
            Format: {"content": str, "reasoning_content": str, "done": bool}
        """
        if not user_api_key or not user_api_url or not user_model:
            yield {"content": None, "reasoning_content": None, "done": True}
            return

        system_content = system_prompt if system_prompt else DEFAULT_SYSTEM_PROMPT

        if records_context:
            system_content += f"""

Here is the user's bowel record data for reference:
{records_context}"""

        formatted_messages = [{"role": "system", "content": system_content}]

        for msg in messages:
            formatted_messages.append(
                {"role": msg.get("role", "user"), "content": msg.get("content", "")}
            )

        request_params = {"model": user_model, "messages": formatted_messages, "stream": True}

        if thinking_intensity and thinking_intensity in THINKING_PARAMS:
            params = THINKING_PARAMS[thinking_intensity]
            request_params["temperature"] = params["temperature"]
            request_params["max_tokens"] = params["max_tokens"]
        else:
            request_params["temperature"] = 0.7
            request_params["max_tokens"] = 2000

        try:
            async with (
                httpx.AsyncClient(timeout=60.0) as client,
                client.stream(
                    "POST",
                    f"{user_api_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {user_api_key}",
                        "Content-Type": "application/json",
                    },
                    json=request_params,
                ) as response,
            ):
                if response.status_code != 200:
                    error_text = await response.aread()
                    print(f"LLM API error: {response.status_code} - {error_text}")
                    yield {"content": None, "reasoning_content": None, "done": True}
                    return

                async for line in response.aiter_lines():
                    line = line.strip()
                    if not line:
                        continue
                    if not line.startswith("data: "):
                        continue

                    data = line[6:]
                    if data == "[DONE]":
                        yield {"content": "", "reasoning_content": "", "done": True}
                        return

                    try:
                        chunk = json.loads(data)
                        delta = chunk.get("choices", [{}])[0].get("delta", {})
                        content = delta.get("content", "") or ""
                        reasoning_content = delta.get("reasoning_content", "") or ""

                        if content or reasoning_content:
                            yield {
                                "content": content,
                                "reasoning_content": reasoning_content,
                                "done": False,
                            }
                    except json.JSONDecodeError:
                        continue

            yield {"content": "", "reasoning_content": "", "done": True}

        except Exception as e:
            print(f"LLM chat stream exception: {e}")
            yield {"content": None, "reasoning_content": None, "done": True}

    async def generate_conversation_title(
        self,
        user_message: str,
        ai_response: str,
        user_api_key: str | None = None,
        user_api_url: str | None = None,
        user_model: str | None = None,
    ) -> str | None:
        """Generate a concise title for the conversation based on the first exchange

        Args:
            user_message: The user's first message
            ai_response: The AI's response
            user_api_key: User's custom API key
            user_api_url: User's custom API URL
            user_model: User's custom model name

        Returns:
            A concise title (max 20 chars) or None if generation fails
        """
        if not user_api_key or not user_api_url or not user_model:
            return None

        title_prompt = f"""Based on the following conversation, generate a concise title (maximum 20 characters, in Chinese) that summarizes the main topic.

User: {user_message}

Assistant: {ai_response[:200]}...

Please provide only the title without any explanation or punctuation."""

        request_params = {
            "model": user_model,
            "messages": [
                {
                    "role": "system",
                    "content": "You are a helpful assistant that generates concise conversation titles.",
                },
                {"role": "user", "content": title_prompt},
            ],
            "temperature": 0.5,
            "max_tokens": 50,
        }

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(
                    f"{user_api_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {user_api_key}",
                        "Content-Type": "application/json",
                    },
                    json=request_params,
                )

                if response.status_code == 200:
                    result = response.json()
                    title = result["choices"][0]["message"].get("content", "").strip()
                    # Clean up the title
                    title = (
                        title.replace('"', "").replace("'", "").replace("「", "").replace("」", "")
                    )
                    title = title.replace("标题：", "").replace("标题:", "").replace("Title: ", "")
                    # Limit to 20 characters
                    if len(title) > 20:
                        title = title[:20]
                    return title if title else None
                return None

        except Exception as e:
            print(f"Generate title exception: {e}")
            return None


llm_service = LLMService()
