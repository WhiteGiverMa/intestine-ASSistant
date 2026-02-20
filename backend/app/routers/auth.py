"""用户认证路由模块。

@module: auth
@type: router
@layer: backend
@prefix: /auth
@depends: [models.User, database.get_db, config.settings]
@exports: [router, get_current_user]
@api:
  - POST /register - 用户注册
  - POST /login - 用户登录
  - POST /token - OAuth2令牌获取
  - GET /settings - 获取用户设置
  - PUT /settings - 更新用户设置
  - PUT /password - 修改密码
  - DELETE /account - 注销账号
"""
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.models import User

router = APIRouter()
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")
security = HTTPBearer()


class UserCreate(BaseModel):
    email: EmailStr
    password: str
    nickname: str | None = None


class UserResponse(BaseModel):
    user_id: str
    email: str
    nickname: str | None
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
    if len(password.encode("utf-8")) > 72:
        password = password.encode("utf-8")[:72].decode("utf-8", errors="ignore")
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
            nickname=user_data.nickname,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

        token = create_access_token({"sub": user.id})
        return UserResponse(user_id=user.id, email=user.email, nickname=user.nickname, token=token)
    except Exception as e:
        import traceback

        print(f"注册错误: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"服务器内部错误: {str(e)}") from e


@router.post("/login", response_model=UserResponse)
async def login(user_data: UserLogin, db: AsyncSession = Depends(get_db)):
    try:
        result = await db.execute(select(User).where(User.email == user_data.email))
        user = result.scalar_one_or_none()

        if not user or not verify_password(user_data.password, user.password_hash):
            raise HTTPException(status_code=401, detail="邮箱或密码错误")

        token = create_access_token({"sub": user.id})
        return UserResponse(user_id=user.id, email=user.email, nickname=user.nickname, token=token)
    except HTTPException:
        raise
    except Exception as e:
        import traceback

        print(f"登录错误: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"服务器内部错误: {str(e)}") from e


@router.post("/token", response_model=Token)
async def login_for_token(
    form_data: OAuth2PasswordRequestForm = Depends(), db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(User).where(User.email == form_data.username))
    user = result.scalar_one_or_none()

    if not user or not verify_password(form_data.password, user.password_hash):
        raise HTTPException(status_code=401, detail="邮箱或密码错误")

    token = create_access_token({"sub": user.id})
    return Token(access_token=token)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> User:
    try:
        payload = jwt.decode(
            credentials.credentials, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail="无效的认证令牌")
    except JWTError as e:
        raise HTTPException(status_code=401, detail="无效的认证令牌") from e

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=401, detail="用户不存在")
    return user


class UserSettingsResponse(BaseModel):
    dev_mode: bool
    ai_api_key: str | None = None
    ai_api_url: str | None = None
    ai_model: str | None = None
    ai_auto_title: bool = False


class UserSettingsUpdate(BaseModel):
    dev_mode: bool | None = None
    ai_api_key: str | None = None
    ai_api_url: str | None = None
    ai_model: str | None = None
    ai_auto_title: bool | None = None


class PasswordUpdate(BaseModel):
    current_password: str
    new_password: str


@router.get("/settings", response_model=dict)
async def get_settings(
    current_user: User = Depends(get_current_user), _db: AsyncSession = Depends(get_db)
):
    return {
        "code": 200,
        "data": {
            "dev_mode": current_user.dev_mode or False,
            "ai_api_key": current_user.ai_api_key,
            "ai_api_url": current_user.ai_api_url,
            "ai_model": current_user.ai_model,
            "ai_auto_title": current_user.ai_auto_title or False,
        },
    }


@router.put("/settings", response_model=dict)
async def update_settings(
    settings_data: UserSettingsUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if settings_data.dev_mode is not None:
        current_user.dev_mode = settings_data.dev_mode
    if settings_data.ai_api_key is not None:
        current_user.ai_api_key = settings_data.ai_api_key
    if settings_data.ai_api_url is not None:
        current_user.ai_api_url = settings_data.ai_api_url
    if settings_data.ai_model is not None:
        current_user.ai_model = settings_data.ai_model
    if settings_data.ai_auto_title is not None:
        current_user.ai_auto_title = settings_data.ai_auto_title

    await db.commit()
    await db.refresh(current_user)

    return {
        "code": 200,
        "data": {
            "dev_mode": current_user.dev_mode or False,
            "ai_api_key": current_user.ai_api_key,
            "ai_api_url": current_user.ai_api_url,
            "ai_model": current_user.ai_model,
            "ai_auto_title": current_user.ai_auto_title or False,
            "message": "设置更新成功",
        },
    }


@router.put("/password", response_model=dict)
async def update_password(
    password_data: PasswordUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not verify_password(password_data.current_password, current_user.password_hash):
        raise HTTPException(status_code=400, detail="当前密码错误")

    if len(password_data.new_password) < 6:
        raise HTTPException(status_code=400, detail="新密码至少需要6个字符")

    current_user.password_hash = get_password_hash(password_data.new_password)
    await db.commit()

    return {"code": 200, "data": {"message": "密码修改成功"}}


@router.delete("/account", response_model=dict)
async def delete_account(
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    from sqlalchemy import delete

    from app.models import AIAnalysis, BowelRecord

    await db.execute(delete(AIAnalysis).where(AIAnalysis.user_id == current_user.id))
    await db.execute(delete(BowelRecord).where(BowelRecord.user_id == current_user.id))
    await db.delete(current_user)
    await db.commit()

    return {"code": 200, "data": {"message": "账号已注销"}}
