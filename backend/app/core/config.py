"""
Application Configuration
"""
from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import Optional


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""

    # Application
    ENVIRONMENT: str = "development"
    SECRET_KEY: str
    LOG_LEVEL: str = "INFO"

    # Database
    DATABASE_URL: str
    DB_POOL_SIZE: int = 20
    DB_MAX_OVERFLOW: int = 40

    # Redis
    REDIS_URL: str
    REDIS_MAX_CONNECTIONS: int = 50
    REDIS_DECODE_RESPONSES: bool = True

    # Cache TTL (in seconds)
    CACHE_GAMES_LIST_TTL: int = 300
    CACHE_GAME_DETAIL_TTL: int = 60
    CACHE_PLAYER_STATS_TTL: int = 1800
    CACHE_PREDICTION_TTL: int = 3600
    CACHE_STANDINGS_TTL: int = 3600

    # JWT
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # API Rate Limiting
    API_RATE_LIMIT_ENABLED: bool = True
    API_RATE_LIMIT_PER_MINUTE: int = 60

    # CORS
    CORS_ORIGINS: str = "http://localhost:3000"

    # MLflow
    MLFLOW_TRACKING_URI: Optional[str] = None

    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()
