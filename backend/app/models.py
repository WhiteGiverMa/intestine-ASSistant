from sqlalchemy import Column, String, DateTime, Integer, Text, Boolean, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import enum
import uuid
from datetime import datetime

def generate_uuid():
    return str(uuid.uuid4())

LID_CHARS = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

def encode_sequence(num: int) -> str:
    result = []
    for _ in range(4):
        result.append(LID_CHARS[num % 62])
        num //= 62
    return ''.join(reversed(result))

def generate_lid_from_date(record_date: str, sequence: int) -> str:
    date_obj = datetime.strptime(record_date, '%Y-%m-%d')
    yy = str(date_obj.year)[-2:]
    mmdd = f'{date_obj.month:02d}{date_obj.day:02d}'
    seq_str = encode_sequence(sequence)
    return f'L{yy}{mmdd}{seq_str}'

class StoolType(int, enum.Enum):
    TYPE_1 = 1
    TYPE_2 = 2
    TYPE_3 = 3
    TYPE_4 = 4
    TYPE_5 = 5
    TYPE_6 = 6
    TYPE_7 = 7

class FeelingType(str, enum.Enum):
    SMOOTH = "smooth"
    DIFFICULT = "difficult"
    PAINFUL = "painful"
    URGENT = "urgent"
    INCOMPLETE = "incomplete"

class User(Base):
    __tablename__ = "users"
    
    id = Column(String(36), primary_key=True, default=generate_uuid)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    nickname = Column(String(100))
    avatar_url = Column(String(500))
    dev_mode = Column(Boolean, default=False)
    ai_api_key = Column(String(255), nullable=True)
    ai_api_url = Column(String(500), nullable=True)
    ai_model = Column(String(100), nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    
    records = relationship("BowelRecord", back_populates="user")
    reminders = relationship("Reminder", back_populates="user")

class BowelRecord(Base):
    __tablename__ = "bowel_records"
    
    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    lid = Column(String(12), unique=True, nullable=True, index=True)
    record_date = Column(String(10), nullable=False)
    record_time = Column(String(8), nullable=True)
    duration_minutes = Column(Integer)
    stool_type = Column(Integer)
    color = Column(String(50))
    smell_level = Column(Integer)
    feeling = Column(String(50))
    symptoms = Column(Text)
    notes = Column(Text)
    is_manual = Column(Boolean, default=True)
    is_no_bowel = Column(Boolean, default=False)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    
    user = relationship("User", back_populates="records")

class Reminder(Base):
    __tablename__ = "reminders"
    
    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    reminder_type = Column(String(50), nullable=False)
    reminder_time = Column(String(8))
    reminder_days = Column(String(50))
    is_active = Column(Boolean, default=True)
    last_triggered_at = Column(DateTime)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    
    user = relationship("User", back_populates="reminders")

class AIAnalysis(Base):
    __tablename__ = "ai_analyses"
    
    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    analysis_type = Column(String(50), nullable=False)
    period_start = Column(String(10), nullable=False)
    period_end = Column(String(10), nullable=False)
    health_score = Column(Integer)
    insights = Column(Text, nullable=False)
    suggestions = Column(Text, nullable=False)
    warnings = Column(Text)
    model_version = Column(String(50))
    created_at = Column(DateTime, server_default=func.now())
