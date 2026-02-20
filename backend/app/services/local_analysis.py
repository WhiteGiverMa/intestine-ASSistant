"""本地健康分析服务模块。

@module: local_analysis
@type: service
@layer: backend
@depends: [models.BowelRecord]
@exports: [perform_local_analysis, calculate_stats]
@features:
  - 本地规则分析: 基于布里斯托分类的健康评分
  - 统计计算: 频率、时长、形态分布等
  - 洞察生成: 基于数据的健康洞察
  - 建议生成: 个性化健康建议
  - 警告生成: 健康异常警告
"""

from collections import Counter
from datetime import datetime


def calculate_stats(records: list, start_date: str, end_date: str) -> dict:
    """计算排便记录的统计数据

    参数：
        records: 排便记录列表
        start_date: 开始日期
        end_date: 结束日期

    返回：
        包含以下统计数据的字典：
        - total_records: 总记录数
        - days: 分析周期天数
        - recorded_days: 实际记录天数
        - coverage_rate: 数据覆盖率
        - avg_frequency: 平均每日排便次数（基于实际记录天数）
        - avg_duration: 平均排便时长（分钟）
        - type_dist: 粪便类型分布
        - feeling_dist: 排便感受分布
        - time_dist: 时间段分布
    """
    normal_records = [r for r in records if not r.is_no_bowel]
    total_records = len(normal_records)

    recorded_dates = {r.record_date for r in records}
    recorded_days = len(recorded_dates)

    period_days = (datetime.fromisoformat(end_date) - datetime.fromisoformat(start_date)).days or 1
    coverage_rate = round(recorded_days / period_days, 2) if period_days > 0 else 0

    avg_frequency = round(total_records / recorded_days, 2) if recorded_days > 0 else 0

    durations = [r.duration_minutes for r in normal_records if r.duration_minutes]
    avg_duration = round(sum(durations) / len(durations), 1) if durations else 0

    stool_types = [r.stool_type for r in normal_records if r.stool_type]
    type_dist = dict(Counter(stool_types))

    feelings = [r.feeling for r in normal_records if r.feeling]
    feeling_dist = dict(Counter(feelings))

    time_dist = {"morning": 0, "afternoon": 0, "evening": 0}
    for r in normal_records:
        if r.record_time:
            hour = int(r.record_time.split(":")[0])
            if 6 <= hour < 12:
                time_dist["morning"] += 1
            elif 12 <= hour < 18:
                time_dist["afternoon"] += 1
            else:
                time_dist["evening"] += 1

    return {
        "total_records": total_records,
        "days": period_days,
        "recorded_days": recorded_days,
        "coverage_rate": coverage_rate,
        "avg_frequency": avg_frequency,
        "avg_duration": avg_duration,
        "type_dist": type_dist,
        "feeling_dist": feeling_dist,
        "time_dist": time_dist,
    }


def calculate_health_score(
    avg_frequency: float, avg_duration: float, type_dist: dict, feeling_dist: dict
) -> int:
    """计算肠道健康评分

    评分规则（满分100分，基础60分）：
    1. 排便频率评分（+15分）：
       - 正常范围(0.8-2.5次/天): +15分
       - 轻度异常(0.5-0.8或2.5-3次/天): +5分
       - 明显异常: -10分
    2. 排便时长评分（+10分）：
       - 正常范围(3-15分钟): +10分
       - 轻度异常(1-3或15-20分钟): +5分
       - 明显异常: -5分
    3. 粪便形态评分（+15分）：
       - 根据健康形态（类型3-4）占比加分
    4. 排便感受评分（+10分）：
       - 根据顺畅感受占比加分

    参数：
        avg_frequency: 平均每日排便次数
        avg_duration: 平均排便时长
        type_dist: 粪便类型分布
        feeling_dist: 排便感受分布

    返回：
        0-100的健康评分
    """
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


def generate_insights(
    avg_frequency: float, avg_duration: float, type_dist: dict, time_dist: dict, feeling_dist: dict
) -> list:
    """生成分析洞察

    基于统计数据生成有价值的健康洞察，包括：
    - 排便时间规律
    - 粪便形态分析
    - 排便频率分析

    参数：
        avg_frequency: 平均每日排便次数
        avg_duration: 平均排便时长
        type_dist: 粪便类型分布
        time_dist: 时间段分布
        feeling_dist: 排便感受分布

    返回：
        洞察列表，每个洞察包含 type, title, description
    """
    insights = []

    peak_time = max(time_dist, key=time_dist.get)
    time_names = {"morning": "早晨", "afternoon": "下午", "evening": "晚上"}
    insights.append(
        {
            "type": "pattern",
            "title": "排便时间规律",
            "description": f"您的排便时间主要集中在{time_names[peak_time]}，这是{'健康' if peak_time == 'morning' else '正常'}的排便习惯",
        }
    )

    if type_dist:
        most_common_type = max(type_dist, key=type_dist.get)
        type_descriptions = {
            1: "便秘倾向（硬块状）",
            2: "轻度便秘（结块状）",
            3: "正常（有裂纹）",
            4: "理想状态（光滑柔软）",
            5: "缺乏纤维（断块状）",
            6: "轻度腹泻（糊状）",
            7: "腹泻（液体状）",
        }
        insights.append(
            {
                "type": "stool_type",
                "title": "粪便形态分析",
                "description": f"您最常见的粪便形态为类型{most_common_type}（{type_descriptions.get(most_common_type, '未知')}）",
            }
        )

    if avg_frequency:
        if avg_frequency < 0.5:
            freq_status = "排便频率较低"
        elif avg_frequency > 3:
            freq_status = "排便频率较高"
        else:
            freq_status = "排便频率正常"
        insights.append(
            {
                "type": "frequency",
                "title": "排便频率",
                "description": f"您平均每日排便{avg_frequency}次，{freq_status}",
            }
        )

    return insights


def generate_suggestions(
    avg_frequency: float, avg_duration: float, type_dist: dict, feeling_dist: dict
) -> list:
    """生成健康建议

    根据分析结果生成个性化的健康改善建议，包括：
    - 饮食建议
    - 习惯建议
    - 生活方式建议
    - 健康建议

    参数：
        avg_frequency: 平均每日排便次数
        avg_duration: 平均排便时长
        type_dist: 粪便类型分布
        feeling_dist: 排便感受分布

    返回：
        建议列表，每个建议包含 category, suggestion
    """
    suggestions = []

    healthy_types = type_dist.get(3, 0) + type_dist.get(4, 0)
    total_types = sum(type_dist.values()) or 1
    if healthy_types / total_types < 0.5:
        suggestions.append(
            {
                "category": "diet",
                "suggestion": "建议增加膳食纤维摄入，多吃蔬菜、水果和全谷物，有助于改善粪便形态",
            }
        )

    if avg_duration and avg_duration > 15:
        suggestions.append(
            {
                "category": "habit",
                "suggestion": "排便时间较长可能提示便秘倾向，建议多喝水、适当运动，避免如厕时使用手机",
            }
        )

    if avg_frequency and avg_frequency < 0.8:
        suggestions.append(
            {
                "category": "lifestyle",
                "suggestion": "排便频率较低，建议增加日常活动量，保持规律作息，必要时咨询医生",
            }
        )

    difficult_ratio = (feeling_dist.get("difficult", 0) + feeling_dist.get("painful", 0)) / (
        sum(feeling_dist.values()) or 1
    )
    if difficult_ratio > 0.3:
        suggestions.append(
            {
                "category": "health",
                "suggestion": "排便困难或疼痛的情况较多，建议增加水分摄入，如症状持续请咨询医生",
            }
        )

    if not suggestions:
        suggestions.append(
            {"category": "general", "suggestion": "您的肠道健康状况良好，请继续保持健康的生活习惯"}
        )

    return suggestions


def generate_warnings(
    avg_frequency: float, _avg_duration: float, type_dist: dict, _feeling_dist: dict
) -> list:
    """生成健康警告

    当检测到明显的健康问题时生成警告信息，包括：
    - 排便频率异常警告
    - 粪便形态异常警告

    参数：
        avg_frequency: 平均每日排便次数
        avg_duration: 平均排便时长
        type_dist: 粪便类型分布
        feeling_dist: 排便感受分布

    返回：
        警告列表，每个警告包含 type, message
    """
    warnings = []

    if avg_frequency and avg_frequency > 4:
        warnings.append(
            {
                "type": "high_frequency",
                "message": "排便频率异常高，可能存在腹泻问题，建议关注饮食并咨询医生",
            }
        )

    if avg_frequency and avg_frequency < 0.3:
        warnings.append(
            {
                "type": "low_frequency",
                "message": "排便频率过低，可能存在便秘问题，建议增加膳食纤维和水分摄入",
            }
        )

    unhealthy_types = type_dist.get(1, 0) + type_dist.get(7, 0)
    total_types = sum(type_dist.values()) or 1
    if unhealthy_types / total_types > 0.3:
        warnings.append(
            {
                "type": "abnormal_stool",
                "message": "粪便形态异常比例较高，建议关注饮食健康，如持续异常请咨询医生",
            }
        )

    return warnings


async def perform_local_analysis(records: list, start_date: str, end_date: str) -> dict:
    """执行本地规则分析（降级方案）

    当AI API不可用时的备用分析方案，基于医学常识和布里斯托粪便分类进行：
    1. 计算健康评分（基于频率、时长、形态、感受）
    2. 生成分析洞察
    3. 生成健康建议
    4. 生成健康警告

    参数：
        records: 排便记录列表
        start_date: 开始日期
        end_date: 结束日期

    返回：
        包含 health_score, insights, suggestions, warnings 的字典
    """
    stats = calculate_stats(records, start_date, end_date)

    health_score = calculate_health_score(
        stats["avg_frequency"], stats["avg_duration"], stats["type_dist"], stats["feeling_dist"]
    )

    insights = generate_insights(
        stats["avg_frequency"],
        stats["avg_duration"],
        stats["type_dist"],
        stats["time_dist"],
        stats["feeling_dist"],
    )
    suggestions = generate_suggestions(
        stats["avg_frequency"], stats["avg_duration"], stats["type_dist"], stats["feeling_dist"]
    )
    warnings = generate_warnings(
        stats["avg_frequency"], stats["avg_duration"], stats["type_dist"], stats["feeling_dist"]
    )

    return {
        "health_score": health_score,
        "insights": insights,
        "suggestions": suggestions,
        "warnings": warnings,
    }


def build_records_context(records: list) -> str:
    """构建记录上下文用于AI对话

    参数：
        records: 排便记录列表

    返回：
        格式化的记录上下文字符串
    """
    context_lines = ["User's bowel records in the selected time range:"]
    for r in records:
        line = f"- Date: {r.record_date}"
        if r.record_time:
            line += f" Time: {r.record_time}"
        if r.duration_minutes:
            line += f" Duration: {r.duration_minutes}min"
        if r.stool_type:
            line += f" Type: {r.stool_type}"
        if r.feeling:
            line += f" Feeling: {r.feeling}"
        if r.notes:
            line += f" Notes: {r.notes}"
        context_lines.append(line)
    return "\n".join(context_lines)
