"""排便记录CRUD路由模块。

@module: records
@type: router
@layer: backend
@prefix: /records
@depends: [models.BowelRecord, models.User, routers.auth.get_current_user]
@exports: [router]
@api:
  - POST / - 创建排便记录
  - GET / - 获取记录列表
  - PUT /{id} - 更新记录
  - DELETE /{id} - 删除记录
  - DELETE /batch - 批量删除
  - POST /no-bowel - 标注无排便
  - DELETE /no-bowel/{date} - 取消无排便标注
  - GET /daily-counts - 获取每日统计
"""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import BowelRecord, User, generate_lid_from_date
from app.routers.auth import get_current_user

router = APIRouter()


class RecordCreate(BaseModel):
    record_date: str
    record_time: str
    duration_minutes: int | None = None
    stool_type: int | None = None
    color: str | None = None
    smell_level: int | None = None
    feeling: str | None = None
    symptoms: list[str] | None = None
    notes: str | None = None


class RecordUpdate(BaseModel):
    record_date: str | None = None
    record_time: str | None = None
    duration_minutes: int | None = None
    stool_type: int | None = None
    color: str | None = None
    smell_level: int | None = None
    feeling: str | None = None
    symptoms: list[str] | None = None
    notes: str | None = None


class RecordResponse(BaseModel):
    record_id: str
    lid: str | None
    record_date: str
    record_time: str | None
    duration_minutes: int | None
    stool_type: int | None
    color: str | None
    smell_level: int | None
    feeling: str | None
    symptoms: str | None
    notes: str | None
    is_no_bowel: bool
    created_at: str


class NoBowelRequest(BaseModel):
    date: str


class BatchDateRangeRequest(BaseModel):
    start_date: str
    end_date: str


@router.post("", response_model=dict)
async def create_record(
    record_data: RecordCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    no_bowel_records = await db.execute(
        select(BowelRecord).where(
            BowelRecord.user_id == current_user.id,
            BowelRecord.record_date == record_data.record_date,
            BowelRecord.is_no_bowel.is_(True),
        )
    )
    for record in no_bowel_records.scalars().all():
        await db.delete(record)

    count_result = await db.execute(
        select(func.count()).where(
            BowelRecord.user_id == current_user.id,
            BowelRecord.record_date == record_data.record_date,
        )
    )
    daily_count = count_result.scalar() or 0

    lid = generate_lid_from_date(record_data.record_date, daily_count)

    record = BowelRecord(
        user_id=current_user.id,
        lid=lid,
        record_date=record_data.record_date,
        record_time=record_data.record_time,
        duration_minutes=record_data.duration_minutes,
        stool_type=record_data.stool_type,
        color=record_data.color,
        smell_level=record_data.smell_level,
        feeling=record_data.feeling,
        symptoms=",".join(record_data.symptoms) if record_data.symptoms else None,
        notes=record_data.notes,
    )
    db.add(record)
    await db.commit()
    await db.refresh(record)

    return {
        "code": 200,
        "data": {"record_id": record.id, "lid": record.lid, "created_at": str(record.created_at)},
    }


@router.get("", response_model=dict)
async def get_records(
    start_date: str | None = None,
    end_date: str | None = None,
    page: int = 1,
    limit: int = 20,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    query = select(BowelRecord).where(BowelRecord.user_id == current_user.id)

    if start_date:
        query = query.where(BowelRecord.record_date >= start_date)
    if end_date:
        query = query.where(BowelRecord.record_date <= end_date)

    query = query.order_by(BowelRecord.record_date.desc(), BowelRecord.record_time.desc())
    query = query.offset((page - 1) * limit).limit(limit)

    result = await db.execute(query)
    records = result.scalars().all()

    return {
        "code": 200,
        "data": {
            "records": [
                {
                    "record_id": r.id,
                    "lid": r.lid,
                    "record_date": r.record_date,
                    "record_time": r.record_time,
                    "duration_minutes": r.duration_minutes,
                    "stool_type": r.stool_type,
                    "color": r.color,
                    "smell_level": r.smell_level,
                    "feeling": r.feeling,
                    "symptoms": r.symptoms,
                    "notes": r.notes,
                    "is_no_bowel": r.is_no_bowel,
                    "created_at": str(r.created_at),
                }
                for r in records
            ],
            "pagination": {"page": page, "limit": limit},
        },
    }


@router.put("/{record_id}", response_model=dict)
async def update_record(
    record_id: str,
    record_data: RecordUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(BowelRecord).where(
            BowelRecord.id == record_id, BowelRecord.user_id == current_user.id
        )
    )
    record = result.scalar_one_or_none()

    if not record:
        raise HTTPException(status_code=404, detail="记录不存在")

    update_data = record_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if key == "symptoms" and isinstance(value, list):
            value = ",".join(value)
        setattr(record, key, value)

    await db.commit()
    return {"code": 200, "data": {"message": "更新成功"}}


@router.delete("/batch", response_model=dict)
async def delete_records_batch(
    request: BatchDateRangeRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from datetime import datetime

    try:
        start = datetime.strptime(request.start_date, "%Y-%m-%d").date()
        end = datetime.strptime(request.end_date, "%Y-%m-%d").date()
    except ValueError as e:
        raise HTTPException(status_code=400, detail="日期格式错误，请使用 YYYY-MM-DD 格式") from e

    if start > end:
        raise HTTPException(status_code=400, detail="开始日期不能晚于结束日期")

    result = await db.execute(
        select(BowelRecord).where(
            BowelRecord.user_id == current_user.id,
            BowelRecord.record_date >= request.start_date,
            BowelRecord.record_date <= request.end_date,
        )
    )
    records = result.scalars().all()

    deleted_count = len(records)
    bowel_count = sum(1 for r in records if not r.is_no_bowel)
    no_bowel_count = sum(1 for r in records if r.is_no_bowel)

    for record in records:
        await db.delete(record)

    await db.commit()

    return {
        "code": 200,
        "data": {
            "deleted_count": deleted_count,
            "bowel_count": bowel_count,
            "no_bowel_count": no_bowel_count,
            "message": f"已删除 {deleted_count} 条记录（{bowel_count} 条排便记录，{no_bowel_count} 条无排便标注）",
        },
    }


@router.delete("/no-bowel/batch", response_model=dict)
async def unmark_no_bowel_batch(
    request: BatchDateRangeRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from datetime import datetime

    try:
        start = datetime.strptime(request.start_date, "%Y-%m-%d").date()
        end = datetime.strptime(request.end_date, "%Y-%m-%d").date()
    except ValueError as e:
        raise HTTPException(status_code=400, detail="日期格式错误，请使用 YYYY-MM-DD 格式") from e

    if start > end:
        raise HTTPException(status_code=400, detail="开始日期不能晚于结束日期")

    result = await db.execute(
        select(BowelRecord).where(
            BowelRecord.user_id == current_user.id,
            BowelRecord.record_date >= request.start_date,
            BowelRecord.record_date <= request.end_date,
            BowelRecord.is_no_bowel.is_(True),
        )
    )
    records = result.scalars().all()

    unmarked_count = len(records)

    for record in records:
        await db.delete(record)

    await db.commit()

    return {
        "code": 200,
        "data": {
            "unmarked_count": unmarked_count,
            "message": f"已取消 {unmarked_count} 天的无排便标注",
        },
    }


@router.delete("/{record_id}", response_model=dict)
async def delete_record(
    record_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(BowelRecord).where(
            BowelRecord.id == record_id, BowelRecord.user_id == current_user.id
        )
    )
    record = result.scalar_one_or_none()

    if not record:
        raise HTTPException(status_code=404, detail="记录不存在")

    await db.delete(record)
    await db.commit()
    return {"code": 200, "data": {"message": "删除成功"}}


@router.post("/no-bowel", response_model=dict)
async def mark_no_bowel(
    request: NoBowelRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        result = await db.execute(
            select(BowelRecord).where(
                BowelRecord.user_id == current_user.id,
                BowelRecord.record_date == request.date,
                BowelRecord.is_no_bowel.is_(True),
            )
        )
        existing = result.scalar_one_or_none()

        if existing:
            return {
                "code": 200,
                "data": {
                    "record_id": existing.id,
                    "lid": existing.lid,
                    "message": "该日期已标注无排便",
                },
            }

        normal_records = await db.execute(
            select(BowelRecord).where(
                BowelRecord.user_id == current_user.id,
                BowelRecord.record_date == request.date,
                BowelRecord.is_no_bowel.is_(False),
            )
        )
        for record in normal_records.scalars().all():
            await db.delete(record)

        count_result = await db.execute(
            select(func.count()).where(
                BowelRecord.user_id == current_user.id, BowelRecord.record_date == request.date
            )
        )
        daily_count = count_result.scalar() or 0

        lid = generate_lid_from_date(request.date, daily_count)

        no_bowel_record = BowelRecord(
            user_id=current_user.id,
            lid=lid,
            record_date=request.date,
            record_time=None,
            is_no_bowel=True,
        )
        db.add(no_bowel_record)
        await db.commit()
        await db.refresh(no_bowel_record)

        return {
            "code": 200,
            "data": {
                "record_id": no_bowel_record.id,
                "lid": no_bowel_record.lid,
                "message": "已标注无排便",
            },
        }
    except Exception as e:
        await db.rollback()
        print(f"Error in mark_no_bowel: {e}")
        raise HTTPException(status_code=500, detail=f"标注失败: {str(e)}") from e


@router.delete("/no-bowel/{date}", response_model=dict)
async def unmark_no_bowel(
    date: str, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(BowelRecord).where(
            BowelRecord.user_id == current_user.id,
            BowelRecord.record_date == date,
            BowelRecord.is_no_bowel.is_(True),
        )
    )
    record = result.scalar_one_or_none()

    if not record:
        return {"code": 200, "data": {"message": "该日期未标注无排便"}}

    await db.delete(record)
    await db.commit()
    return {"code": 200, "data": {"message": "已取消无排便标注"}}


@router.post("/no-bowel/batch", response_model=dict)
async def mark_no_bowel_batch(
    request: BatchDateRangeRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from datetime import datetime, timedelta

    try:
        start = datetime.strptime(request.start_date, "%Y-%m-%d").date()
        end = datetime.strptime(request.end_date, "%Y-%m-%d").date()
    except ValueError as e:
        raise HTTPException(status_code=400, detail="日期格式错误，请使用 YYYY-MM-DD 格式") from e

    if start > end:
        raise HTTPException(status_code=400, detail="开始日期不能晚于结束日期")

    success_count = 0
    skipped_count = 0
    current_date = start

    while current_date <= end:
        date_str = current_date.strftime("%Y-%m-%d")

        result = await db.execute(
            select(BowelRecord).where(
                BowelRecord.user_id == current_user.id,
                BowelRecord.record_date == date_str,
                BowelRecord.is_no_bowel.is_(True),
            )
        )
        existing = result.scalar_one_or_none()

        if existing:
            skipped_count += 1
        else:
            normal_records = await db.execute(
                select(BowelRecord).where(
                    BowelRecord.user_id == current_user.id,
                    BowelRecord.record_date == date_str,
                    BowelRecord.is_no_bowel.is_(False),
                )
            )
            for record in normal_records.scalars().all():
                await db.delete(record)

            count_result = await db.execute(
                select(func.count()).where(
                    BowelRecord.user_id == current_user.id, BowelRecord.record_date == date_str
                )
            )
            daily_count = count_result.scalar() or 0
            lid = generate_lid_from_date(date_str, daily_count)

            no_bowel_record = BowelRecord(
                user_id=current_user.id,
                lid=lid,
                record_date=date_str,
                record_time=None,
                is_no_bowel=True,
            )
            db.add(no_bowel_record)
            success_count += 1

        current_date += timedelta(days=1)

    await db.commit()

    return {
        "code": 200,
        "data": {
            "success_count": success_count,
            "skipped_count": skipped_count,
            "message": f"已标注 {success_count} 天为无排便，跳过 {skipped_count} 天（已标注）",
        },
    }


@router.get("/daily-counts", response_model=dict)
async def get_daily_counts(
    start_date: str | None = None,
    end_date: str | None = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    query = select(BowelRecord).where(BowelRecord.user_id == current_user.id)

    if start_date:
        query = query.where(BowelRecord.record_date >= start_date)
    if end_date:
        query = query.where(BowelRecord.record_date <= end_date)

    query = query.order_by(BowelRecord.record_date)

    result = await db.execute(query)
    records = result.scalars().all()

    daily_counts = {}
    no_bowel_dates = set()

    for r in records:
        if r.is_no_bowel:
            no_bowel_dates.add(r.record_date)
        else:
            daily_counts[r.record_date] = daily_counts.get(r.record_date, 0) + 1

    for date in no_bowel_dates:
        if date not in daily_counts:
            daily_counts[date] = 0

    return {
        "code": 200,
        "data": {"daily_counts": daily_counts, "no_bowel_dates": list(no_bowel_dates)},
    }
