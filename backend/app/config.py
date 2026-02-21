from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = "sqlite+aiosqlite:///./intestine_assistant.db"
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 43200
    ACCESS_TOKEN_EXPIRE_REMEMBER_DAYS: int = 90

    class Config:  # noqa: D106
        env_file = ".env"


settings = Settings()
