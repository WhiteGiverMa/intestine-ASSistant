import httpx
import json
from typing import Optional, List, Dict, Any

class LLMService:
    """
    LLM服务类：负责调用外部AI API进行排便健康分析

    降级机制说明�?    1. 如果用户在设置页面配置了自己的API（api_key, api_url, model），则调用用户配置的API
    2. 如果用户未配置或API调用失败，返回None，由调用方进行本地规则分�?
    注意：系统不再提供默认API配置，用户需要自行配置API才能使用AI分析功能
    """

    async def analyze_bowel_health(
        self,
        records_data: List[Dict[str, Any]],
        stats_data: Dict[str, Any],
        analysis_type: str = "weekly",
        user_api_key: Optional[str] = None,
        user_api_url: Optional[str] = None,
        user_model: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        分析排便健康数据

        参数:
            records_data: 排便记录数据列表
            stats_data: 统计数据字典
            analysis_type: 分析类型 (weekly/monthly)
            user_api_key: 用户自定义的API密钥（可选）
            user_api_url: 用户自定义的API URL（可选）
            user_model: 用户自定义的模型名称（可选）

        返回:
            分析结果字典，如果无法调用API则返回None

        降级逻辑:
            1. 检查用户是否配置了API密钥
            2. 如果配置了则调用用户指定的API
            3. 如果未配置或调用失败，返回None触发本地分析
        """
        if not user_api_key:
            return None

        if not user_api_url or not user_model:
            return None

        prompt = self._build_analysis_prompt(records_data, stats_data, analysis_type)

        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                response = await client.post(
                    f"{user_api_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {user_api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": user_model,
                        "messages": [
                            {
                                "role": "system",
                                "content": """你是一位专业的肠道健康顾问。你需要根据用户的排便记录数据，提供专业的健康分析和建议�?
请以JSON格式返回分析结果，格式如下：
{
    "health_score": 0-100的整�?
    "insights": [
        {"type": "pattern|stool_type|frequency|other", "title": "标题", "description": "详细描述"}
    ],
    "suggestions": [
        {"category": "diet|habit|lifestyle|health|general", "suggestion": "具体建议"}
    ],
    "warnings": [
        {"type": "warning_type", "message": "警告信息"}
    ]
}

注意�?1. health_score 基于排便频率、时长、粪便形态、感受等综合评估
2. insights 应包�?-4条有价值的洞察
3. suggestions 应包�?-3条实用的改善建议
4. warnings 仅在发现明显健康问题时添�?5. 请用中文回复"""
                            },
                            {
                                "role": "user",
                                "content": prompt
                            }
                        ],
                        "temperature": 0.7,
                        "max_tokens": 2000
                    }
                )

                if response.status_code == 200:
                    result = response.json()
                    content = result["choices"][0]["message"]["content"]
                    return self._parse_llm_response(content)
                else:
                    print(f"LLM API错误: {response.status_code} - {response.text}")
                    return None

        except Exception as e:
            print(f"LLM分析异常: {e}")
            return None

    def _build_analysis_prompt(
        self,
        records_data: List[Dict[str, Any]],
        stats_data: Dict[str, Any],
        analysis_type: str
    ) -> str:
        """
        构建发送给LLM的分析提示词

        参数:
            records_data: 排便记录数据列表
            stats_data: 统计数据字典
            analysis_type: 分析类型

        返回:
            格式化的提示词字符串
        """
        period = "近一�? if analysis_type == "weekly" else "近一�?

        prompt = f"""请分析以下{period}的排便记录数据：

## 统计概览
- 记录总数: {stats_data.get('total_records', 0)}�?- 分析周期: {stats_data.get('days', 0)}�?- 平均排便频率: {stats_data.get('avg_frequency', 0)}�?�?- 平均排便时长: {stats_data.get('avg_duration', 0)}分钟

## 粪便类型分布（布里斯托分类）
"""
        type_dist = stats_data.get('type_dist', {})
        type_names = {
            1: "硬块状（便秘�?,
            2: "结块状（轻度便秘�?,
            3: "有裂纹（正常�?,
            4: "光滑柔软（理想）",
            5: "断块状（缺乏纤维�?,
            6: "糊状（轻度腹泻）",
            7: "液体状（腹泻�?
        }
        for type_id, count in type_dist.items():
            prompt += f"- 类型{type_id} ({type_names.get(int(type_id), '未知')}): {count}次\n"

        prompt += f"""
## 排便感受分布
"""
        feeling_dist = stats_data.get('feeling_dist', {})
        feeling_names = {
            "smooth": "顺畅",
            "difficult": "困难",
            "painful": "疼痛",
            "urgent": "急迫",
            "incomplete": "未排�?
        }
        for feeling, count in feeling_dist.items():
            prompt += f"- {feeling_names.get(feeling, feeling)}: {count}次\n"

        prompt += f"""
## 时间段分�?"""
        time_dist = stats_data.get('time_dist', {})
        time_names = {"morning": "早晨(6-12�?", "afternoon": "下午(12-18�?", "evening": "晚上(18-6�?"}
        for time_period, count in time_dist.items():
            prompt += f"- {time_names.get(time_period, time_period)}: {count}次\n"

        prompt += """
## 详细记录（最�?条）
"""
        for i, record in enumerate(records_data[:5], 1):
            prompt += f"""
{i}. 日期: {record.get('record_date', '未知')} {record.get('record_time', '未知')}
   时长: {record.get('duration_minutes', '未知')}分钟
   类型: {record.get('stool_type', '未知')}
   感受: {feeling_names.get(record.get('feeling', ''), record.get('feeling', '未知'))}
   备注: {record.get('notes', '�?)}
"""

        prompt += """
请根据以上数据，提供专业的肠道健康分析�?""

        return prompt

    def _parse_llm_response(self, content: str) -> Optional[Dict[str, Any]]:
        """
        解析LLM返回的JSON响应

        参数:
            content: LLM返回的原始内容字符串

        返回:
            解析后的字典，解析失败返回None
        """
        try:
            if "```json" in content:
                content = content.split("```json")[1].split("```")[0]
            elif "```" in content:
                content = content.split("```")[1].split("```")[0]

            result = json.loads(content.strip())

            if "health_score" not in result:
                result["health_score"] = 60
            if "insights" not in result:
                result["insights"] = []
            if "suggestions" not in result:
                result["suggestions"] = []
            if "warnings" not in result:
                result["warnings"] = []

            return result

        except json.JSONDecodeError as e:
            print(f"JSON解析错误: {e}")
            print(f"原始内容: {content}")
            return None

llm_service = LLMService()
