"""统计数据路由模块。

@module: stats
@type: router
@layer: backend
@prefix: /stats
@depends: [models.BowelRecord, routers.auth.get_current_user]
@exports: [router]
@api:
  - GET /summary - 获取统计摘要
  - GET /trends - 获取趋势数据
"""
from collections import Counter

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import BowelRecord, User
from app.routers.records import get_current_user

router = APIRouter()


@router.get("/summary", response_model=dict)
async def get_summary(
    period: str = "week",
    start_date: str | None = None,
    end_date: str | None = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from datetime import datetime, timedelta

    today = datetime.now().date()

    if start_date and end_date:
        start = start_date
        end_date_obj = datetime.fromisoformat(end_date).date()
        period_days = (end_date_obj - datetime.fromisoformat(start_date).date()).days + 1
    else:
        if period == "week":
            start = (today - timedelta(days=7)).isoformat()
        elif period == "month":
            start = (today - timedelta(days=30)).isoformat()
        else:
            start = (today - timedelta(days=365)).isoformat()
        period_days = (today - datetime.fromisoformat(start).date()).days

    result = await db.execute(
        select(BowelRecord).where(
            BowelRecord.user_id == current_user.id,
            BowelRecord.record_date >= start,
            BowelRecord.record_date <= (end_date if end_date else today.isoformat()),
        )
    )
    records = result.scalars().all()

    if not records:
        return {
            "code": 200,
            "data": {
                "total_records": 0,
                "days": period_days,
                "recorded_days": 0,
                "coverage_rate": 0,
                "avg_frequency_per_day": 0,
                "avg_duration_minutes": 0,
                "stool_type_distribution": {},
                "time_distribution": {},
                "health_score": 0,
            },
        }

    normal_records = [r for r in records if not r.is_no_bowel]
    total_records = len(normal_records)

    recorded_dates = {r.record_date for r in records}
    recorded_days = len(recorded_dates)

    coverage_rate = round(recorded_days / period_days, 2) if period_days > 0 else 0

    avg_frequency = round(total_records / recorded_days, 2) if recorded_days > 0 else 0

    durations = [r.duration_minutes for r in normal_records if r.duration_minutes]
    avg_duration = round(sum(durations) / len(durations), 1) if durations else 0

    stool_types = [r.stool_type for r in normal_records if r.stool_type]
    type_dist = dict(Counter(stool_types))

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

    health_score = calculate_health_score(avg_frequency, avg_duration, type_dist)

    return {
        "code": 200,
        "data": {
            "total_records": total_records,
            "days": period_days,
            "recorded_days": recorded_days,
            "coverage_rate": coverage_rate,
            "avg_frequency_per_day": avg_frequency,
            "avg_duration_minutes": avg_duration,
            "stool_type_distribution": type_dist,
            "time_distribution": time_dist,
            "health_score": health_score,
        },
    }


@router.get("/trends", response_model=dict)
async def get_trends(
    metric: str = "frequency",
    period: str = "month",
    start_date: str | None = None,
    end_date: str | None = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from datetime import datetime, timedelta

    today = datetime.now().date()

    if start_date and end_date:
        start = start_date
        end_date_obj = datetime.fromisoformat(end_date).date()
        days = (end_date_obj - datetime.fromisoformat(start_date).date()).days + 1
    else:
        if period == "week":
            start = (today - timedelta(days=7)).isoformat()
            days = 7
        elif period == "month":
            start = (today - timedelta(days=30)).isoformat()
            days = 30
        else:
            start = (today - timedelta(days=90)).isoformat()
            days = 90
        end_date_obj = today

    result = await db.execute(
        select(BowelRecord)
        .where(
            BowelRecord.user_id == current_user.id,
            BowelRecord.record_date >= start,
            BowelRecord.record_date <= end_date_obj.isoformat(),
        )
        .order_by(BowelRecord.record_date)
    )
    records = result.scalars().all()

    daily_counts = {}
    recorded_dates = set()
    for r in records:
        if not r.is_no_bowel:
            daily_counts[r.record_date] = daily_counts.get(r.record_date, 0) + 1
        else:
            daily_counts[r.record_date] = daily_counts.get(r.record_date, 0)
        recorded_dates.add(r.record_date)

    trends = []
    for i in range(days):
        date = (end_date_obj - timedelta(days=days - 1 - i)).isoformat()
        trends.append(
            {
                "date": date,
                "value": daily_counts.get(date, 0),
                "is_recorded": date in recorded_dates,
            }
        )

    return {"code": 200, "data": {"trends": trends, "metric": metric}}


def calculate_health_score(avg_frequency: float, avg_duration: float, type_dist: dict) -> int:
    score = 70

    if 0.8 <= avg_frequency <= 2.5:
        score += 10
    elif avg_frequency > 3 or avg_frequency < 0.3:
        score -= 10

    if 3 <= avg_duration <= 15:
        score += 10
    elif avg_duration > 20:
        score -= 5

    healthy_types = type_dist.get(3, 0) + type_dist.get(4, 0)
    total_types = sum(type_dist.values()) or 1
    healthy_ratio = healthy_types / total_types
    score += int(healthy_ratio * 10)

    return min(100, max(0, score))
