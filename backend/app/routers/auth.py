from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm, HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from passlib.context import CryptContext
from jose import jwt, JWTError
from datetime import datetime, timedelta
from pydantic import BaseModel, EmailStr
from typing import Optional

from app.database import get_db
from app.models import User
from app.config import settings

router = APIRouter()
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")
security = HTTPBearer()

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    nickname: Optional[str] = None

class UserResponse(BaseModel):
    user_id: str
    email: str
    nickname: Optional[str]
    token: str

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class UserLogin(BaseModel):
    email: EmailStr
    password: str

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    if len(password.encode('utf-8')) > 72:
        password = password.encode('utf-8')[:72].decode('utf-8', errors='ignore')
    return pwd_context.hash(password)

def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

@router.post("/register", response_model=UserResponse)
async def register(user_data: UserCreate, db: AsyncSession = Depends(get_db)):
    try:
        result = await db.execute(select(User).where(User.email == user_data.email))
        if result.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="邮箱已被注册")

        user = User(
            email=user_data.email,
            password_hash=get_password_hash(user_data.password),
            nickname=user_data.nickname
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

        token = create_access_token({"sub": user.id})
        return UserResponse(
            user_id=user.id,
            email=user.email,
            nickname=user.nickname,
            token=token
        )
    except Exception as e:
        import traceback
        print(f"注册错误: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"服务器内部错误: {str(e)}")

@router.post("/login", response_model=UserResponse)
async def login(user_data: UserLogin, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == user_data.email))
    user = result.scalar_one_or_none()

    if not user or not verify_password(user_data.password, user.password_hash):
        raise HTTPException(status_code=401, detail="邮箱或密码错误")

    token = create_access_token({"sub": user.id})
    return UserResponse(
        user_id=user.id,
        email=user.email,
        nickname=user.nickname,
        token=token
    )

@router.post("/token", response_model=Token)
async def login_for_token(form_data: OAuth2PasswordRequestForm = Depends(), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == form_data.username))
    user = result.scalar_one_or_none()

    if not user or not verify_password(form_data.password, user.password_hash):
        raise HTTPException(status_code=401, detail="邮箱或密码错误")

    token = create_access_token({"sub": user.id})
    return Token(access_token=token)

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db)
) -> User:
    try:
        payload = jwt.decode(credentials.credentials, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail="无效的认证令牌")
    except JWTError:
        raise HTTPException(status_code=401, detail="无效的认证令牌")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=401, detail="用户不存在")
    return user

class UserSettingsResponse(BaseModel):
    dev_mode: bool
    ai_api_key: Optional[str] = None
    ai_api_url: Optional[str] = None
    ai_model: Optional[str] = None

class UserSettingsUpdate(BaseModel):
    dev_mode: Optional[bool] = None
    ai_api_key: Optional[str] = None
    ai_api_url: Optional[str] = None
    ai_model: Optional[str] = None

@router.get("/settings", response_model=dict)
async def get_settings(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    return {
        "code": 200,
        "data": {
            "dev_mode": current_user.dev_mode or False,
            "ai_api_key": current_user.ai_api_key,
            "ai_api_url": current_user.ai_api_url,
            "ai_model": current_user.ai_model
        }
    }

@router.put("/settings", response_model=dict)
async def update_settings(
    settings_data: UserSettingsUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    if settings_data.dev_mode is not None:
        current_user.dev_mode = settings_data.dev_mode
    if settings_data.ai_api_key is not None:
        current_user.ai_api_key = settings_data.ai_api_key
    if settings_data.ai_api_url is not None:
        current_user.ai_api_url = settings_data.ai_api_url
    if settings_data.ai_model is not None:
        current_user.ai_model = settings_data.ai_model

    await db.commit()
    await db.refresh(current_user)

    return {
        "code": 200,
        "data": {
            "dev_mode": current_user.dev_mode or False,
            "ai_api_key": current_user.ai_api_key,
            "ai_api_url": current_user.ai_api_url,
            "ai_model": current_user.ai_model,
            "message": "设置更新成功"
        }
    }
