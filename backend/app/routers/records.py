from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from pydantic import BaseModel
from typing import Optional, List
from datetime import date

from app.database import get_db
from app.models import BowelRecord, User
from app.routers.auth import get_current_user

router = APIRouter()

class RecordCreate(BaseModel):
    record_date: str
    record_time: str
    duration_minutes: Optional[int] = None
    stool_type: Optional[int] = None
    color: Optional[str] = None
    smell_level: Optional[int] = None
    feeling: Optional[str] = None
    symptoms: Optional[List[str]] = None
    notes: Optional[str] = None

class RecordUpdate(BaseModel):
    record_date: Optional[str] = None
    record_time: Optional[str] = None
    duration_minutes: Optional[int] = None
    stool_type: Optional[int] = None
    color: Optional[str] = None
    smell_level: Optional[int] = None
    feeling: Optional[str] = None
    symptoms: Optional[List[str]] = None
    notes: Optional[str] = None

class RecordResponse(BaseModel):
    record_id: str
    record_date: str
    record_time: str
    duration_minutes: Optional[int]
    stool_type: Optional[int]
    color: Optional[str]
    smell_level: Optional[int]
    feeling: Optional[str]
    symptoms: Optional[str]
    notes: Optional[str]
    created_at: str

@router.post("", response_model=dict)
async def create_record(
    record_data: RecordCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    record = BowelRecord(
        user_id=current_user.id,
        record_date=record_data.record_date,
        record_time=record_data.record_time,
        duration_minutes=record_data.duration_minutes,
        stool_type=record_data.stool_type,
        color=record_data.color,
        smell_level=record_data.smell_level,
        feeling=record_data.feeling,
        symptoms=",".join(record_data.symptoms) if record_data.symptoms else None,
        notes=record_data.notes
    )
    db.add(record)
    await db.commit()
    await db.refresh(record)
    
    return {"code": 200, "data": {"record_id": record.id, "created_at": str(record.created_at)}}

@router.get("", response_model=dict)
async def get_records(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    page: int = 1,
    limit: int = 20,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
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
                    "record_date": r.record_date,
                    "record_time": r.record_time,
                    "duration_minutes": r.duration_minutes,
                    "stool_type": r.stool_type,
                    "color": r.color,
                    "smell_level": r.smell_level,
                    "feeling": r.feeling,
                    "symptoms": r.symptoms,
                    "notes": r.notes,
                    "created_at": str(r.created_at)
                }
                for r in records
            ],
            "pagination": {"page": page, "limit": limit}
        }
    }

@router.put("/{record_id}", response_model=dict)
async def update_record(
    record_id: str,
    record_data: RecordUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(BowelRecord).where(BowelRecord.id == record_id, BowelRecord.user_id == current_user.id)
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

@router.delete("/{record_id}", response_model=dict)
async def delete_record(
    record_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(BowelRecord).where(BowelRecord.id == record_id, BowelRecord.user_id == current_user.id)
    )
    record = result.scalar_one_or_none()
    
    if not record:
        raise HTTPException(status_code=404, detail="记录不存在")
    
    await db.delete(record)
    await db.commit()
    return {"code": 200, "data": {"message": "删除成功"}}
