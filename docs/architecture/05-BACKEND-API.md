# Backend API Specification

## Overview

A Python FastAPI backend providing RESTful APIs for the sports prediction platform. The API handles data retrieval, ML model inference, user authentication, and serves as the gateway between the frontend and data/ML layers.

## Technology Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| Python | 3.11+ | Runtime |
| FastAPI | 0.109+ | Web framework |
| SQLAlchemy | 2.0+ | ORM |
| Pydantic | 2.0+ | Validation |
| Alembic | 1.13+ | Migrations |
| asyncpg | 0.29+ | Async PostgreSQL driver |
| Redis | 5.0+ | Caching |
| Uvicorn | 0.27+ | ASGI server |
| python-jose | 3.3+ | JWT handling |

## Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                  # FastAPI application
│   ├── config.py                # Settings/configuration
│   │
│   ├── api/
│   │   ├── __init__.py
│   │   ├── deps.py              # Dependency injection
│   │   └── v1/
│   │       ├── __init__.py
│   │       ├── router.py        # API router aggregation
│   │       └── endpoints/
│   │           ├── games.py
│   │           ├── players.py
│   │           ├── teams.py
│   │           ├── predictions.py
│   │           ├── stats.py
│   │           └── auth.py
│   │
│   ├── core/
│   │   ├── __init__.py
│   │   ├── security.py          # Auth utilities
│   │   ├── logging.py           # Logging config
│   │   └── exceptions.py        # Custom exceptions
│   │
│   ├── models/                  # SQLAlchemy models
│   │   ├── __init__.py
│   │   ├── base.py
│   │   ├── game.py
│   │   ├── player.py
│   │   ├── team.py
│   │   ├── prediction.py
│   │   └── user.py
│   │
│   ├── schemas/                 # Pydantic schemas
│   │   ├── __init__.py
│   │   ├── game.py
│   │   ├── player.py
│   │   ├── team.py
│   │   ├── prediction.py
│   │   └── common.py
│   │
│   ├── services/                # Business logic
│   │   ├── __init__.py
│   │   ├── game_service.py
│   │   ├── player_service.py
│   │   ├── team_service.py
│   │   ├── prediction_service.py
│   │   └── stats_service.py
│   │
│   ├── ml/                      # ML inference
│   │   ├── __init__.py
│   │   ├── model_loader.py
│   │   └── predictor.py
│   │
│   └── db/
│       ├── __init__.py
│       ├── session.py           # Database session
│       └── repositories/        # Data access layer
│           ├── base.py
│           ├── game_repo.py
│           ├── player_repo.py
│           └── team_repo.py
│
├── alembic/
│   ├── versions/
│   └── env.py
│
├── tests/
│   ├── conftest.py
│   ├── api/
│   ├── services/
│   └── fixtures/
│
├── alembic.ini
├── pyproject.toml
├── requirements.txt
└── Dockerfile
```

## API Endpoints

### Games API

```
GET    /api/v1/games                    # List games with filters
GET    /api/v1/games/{game_id}          # Get game details
GET    /api/v1/games/{game_id}/stats    # Get game statistics
GET    /api/v1/games/today              # Get today's games
GET    /api/v1/games/upcoming           # Get upcoming games
```

### Players API

```
GET    /api/v1/players                  # List players with filters
GET    /api/v1/players/{player_id}      # Get player details
GET    /api/v1/players/{player_id}/stats           # Get player statistics
GET    /api/v1/players/{player_id}/game-log        # Get game-by-game stats
GET    /api/v1/players/{player_id}/predictions     # Get player predictions
GET    /api/v1/players/search                      # Search players by name
```

### Teams API

```
GET    /api/v1/teams                    # List all teams
GET    /api/v1/teams/{team_id}          # Get team details
GET    /api/v1/teams/{team_id}/roster   # Get team roster
GET    /api/v1/teams/{team_id}/stats    # Get team statistics
GET    /api/v1/teams/{team_id}/schedule # Get team schedule
GET    /api/v1/teams/standings          # Get standings by sport
```

### Predictions API

```
GET    /api/v1/predictions/games/{game_id}        # Get game prediction
GET    /api/v1/predictions/players/{player_id}    # Get player prediction
GET    /api/v1/predictions/today                  # Get all predictions for today
GET    /api/v1/predictions/accuracy               # Get model accuracy stats
GET    /api/v1/predictions/history                # Get historical predictions
```

### Authentication API

```
POST   /api/v1/auth/register            # Register new user
POST   /api/v1/auth/login               # Login and get token
POST   /api/v1/auth/refresh             # Refresh access token
POST   /api/v1/auth/logout              # Logout (invalidate token)
GET    /api/v1/auth/me                  # Get current user
```

## Endpoint Implementations

### Games Endpoints

```python
# app/api/v1/endpoints/games.py
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
from datetime import date

from app.api.deps import get_db, get_current_user
from app.schemas.game import GameResponse, GameListResponse, GameStatsResponse
from app.schemas.common import PaginationParams
from app.services.game_service import GameService

router = APIRouter(prefix="/games", tags=["games"])


@router.get("", response_model=GameListResponse)
async def list_games(
    sport: Optional[str] = Query(None, regex="^(NFL|NBA|MLB)$"),
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    team_id: Optional[int] = None,
    status: Optional[str] = Query(None, regex="^(scheduled|in_progress|final)$"),
    pagination: PaginationParams = Depends(),
    db: AsyncSession = Depends(get_db),
):
    """
    List games with optional filters.

    - **sport**: Filter by sport (NFL, NBA, MLB)
    - **date_from**: Start date filter
    - **date_to**: End date filter
    - **team_id**: Filter by team
    - **status**: Filter by game status
    """
    service = GameService(db)
    games, total = await service.list_games(
        sport=sport,
        date_from=date_from,
        date_to=date_to,
        team_id=team_id,
        status=status,
        offset=pagination.offset,
        limit=pagination.limit,
    )
    return GameListResponse(
        items=games,
        total=total,
        page=pagination.page,
        page_size=pagination.limit,
    )


@router.get("/today", response_model=GameListResponse)
async def get_todays_games(
    sport: Optional[str] = Query(None, regex="^(NFL|NBA|MLB)$"),
    db: AsyncSession = Depends(get_db),
):
    """Get all games scheduled for today."""
    service = GameService(db)
    games = await service.get_games_by_date(date.today(), sport=sport)
    return GameListResponse(items=games, total=len(games))


@router.get("/{game_id}", response_model=GameResponse)
async def get_game(
    game_id: int,
    db: AsyncSession = Depends(get_db),
):
    """Get detailed information about a specific game."""
    service = GameService(db)
    game = await service.get_game(game_id)
    if not game:
        raise HTTPException(status_code=404, detail="Game not found")
    return game


@router.get("/{game_id}/stats", response_model=GameStatsResponse)
async def get_game_stats(
    game_id: int,
    db: AsyncSession = Depends(get_db),
):
    """Get box score and statistics for a game."""
    service = GameService(db)
    stats = await service.get_game_stats(game_id)
    if not stats:
        raise HTTPException(status_code=404, detail="Game stats not found")
    return stats
```

### Predictions Endpoints

```python
# app/api/v1/endpoints/predictions.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional

from app.api.deps import get_db
from app.schemas.prediction import (
    GamePredictionResponse,
    PlayerPredictionResponse,
    PredictionAccuracyResponse,
)
from app.services.prediction_service import PredictionService
from app.ml.predictor import MLPredictor

router = APIRouter(prefix="/predictions", tags=["predictions"])


@router.get("/games/{game_id}", response_model=GamePredictionResponse)
async def get_game_prediction(
    game_id: int,
    db: AsyncSession = Depends(get_db),
):
    """
    Get ML prediction for a specific game.

    Returns:
    - Win probability for each team
    - Predicted point spread
    - Predicted total points
    - Model confidence score
    """
    service = PredictionService(db)
    prediction = await service.get_game_prediction(game_id)

    if not prediction:
        # Generate prediction on-demand if not cached
        predictor = MLPredictor()
        prediction = await predictor.predict_game(game_id)
        await service.save_prediction(prediction)

    return prediction


@router.get("/players/{player_id}", response_model=PlayerPredictionResponse)
async def get_player_prediction(
    player_id: int,
    game_id: Optional[int] = None,
    db: AsyncSession = Depends(get_db),
):
    """
    Get ML prediction for a player's upcoming game performance.

    If game_id is not provided, predicts for the player's next scheduled game.
    """
    service = PredictionService(db)

    if not game_id:
        game_id = await service.get_next_game_for_player(player_id)
        if not game_id:
            raise HTTPException(
                status_code=404,
                detail="No upcoming game found for this player"
            )

    prediction = await service.get_player_prediction(player_id, game_id)
    return prediction


@router.get("/today", response_model=list[GamePredictionResponse])
async def get_todays_predictions(
    sport: Optional[str] = None,
    min_confidence: float = 0.0,
    db: AsyncSession = Depends(get_db),
):
    """Get predictions for all of today's games."""
    service = PredictionService(db)
    predictions = await service.get_predictions_for_date(
        date=date.today(),
        sport=sport,
        min_confidence=min_confidence,
    )
    return predictions


@router.get("/accuracy", response_model=PredictionAccuracyResponse)
async def get_prediction_accuracy(
    sport: Optional[str] = None,
    days: int = 30,
    db: AsyncSession = Depends(get_db),
):
    """
    Get model accuracy statistics.

    Returns accuracy metrics for game outcome predictions over the specified period.
    """
    service = PredictionService(db)
    accuracy = await service.calculate_accuracy(sport=sport, days=days)
    return accuracy
```

## Pydantic Schemas

```python
# app/schemas/game.py
from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional

class TeamBase(BaseModel):
    id: int
    name: str
    city: str
    abbreviation: str
    logo_url: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class GameBase(BaseModel):
    id: int
    sport: str
    home_team: TeamBase
    away_team: TeamBase
    game_date: datetime
    venue: Optional[str] = None
    status: str

    model_config = ConfigDict(from_attributes=True)


class GameResponse(GameBase):
    home_score: Optional[int] = None
    away_score: Optional[int] = None
    season_id: int
    is_playoff: bool = False


class GameListResponse(BaseModel):
    items: list[GameResponse]
    total: int
    page: int = 1
    page_size: int = 20


class PlayerGameStats(BaseModel):
    player_id: int
    player_name: str
    team: str
    minutes: Optional[int] = None
    stats: dict


class GameStatsResponse(BaseModel):
    game_id: int
    home_team_stats: dict
    away_team_stats: dict
    home_players: list[PlayerGameStats]
    away_players: list[PlayerGameStats]


# app/schemas/prediction.py
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional


class WinProbability(BaseModel):
    home: float = Field(..., ge=0, le=1)
    away: float = Field(..., ge=0, le=1)


class GamePredictionResponse(BaseModel):
    game_id: int
    win_probability: WinProbability
    point_spread: float
    total_points: float
    confidence: float = Field(..., ge=0, le=1)
    model_version: str
    created_at: datetime


class StatPrediction(BaseModel):
    predicted: float
    confidence_interval: tuple[float, float]


class PlayerPredictionResponse(BaseModel):
    player_id: int
    game_id: int
    opponent: str
    stats: dict[str, StatPrediction]
    model_version: str
    created_at: datetime


class PredictionAccuracyResponse(BaseModel):
    total_predictions: int
    correct_predictions: int
    accuracy: float
    by_sport: dict[str, float]
    by_confidence_tier: dict[str, float]
    point_spread_mae: float
    period_start: datetime
    period_end: datetime
```

## Service Layer

```python
# app/services/prediction_service.py
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from datetime import date, datetime, timedelta
from typing import Optional

from app.models.prediction import Prediction
from app.models.game import Game
from app.schemas.prediction import GamePredictionResponse, PredictionAccuracyResponse
from app.ml.predictor import MLPredictor
from app.core.cache import cache


class PredictionService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.predictor = MLPredictor()

    @cache(ttl=300)  # Cache for 5 minutes
    async def get_game_prediction(self, game_id: int) -> Optional[GamePredictionResponse]:
        """Get or generate prediction for a game."""
        # Check database first
        result = await self.db.execute(
            select(Prediction)
            .where(Prediction.game_id == game_id)
            .order_by(Prediction.created_at.desc())
        )
        prediction = result.scalar_one_or_none()

        if prediction:
            return self._to_response(prediction)

        # Generate new prediction
        return await self._generate_game_prediction(game_id)

    async def _generate_game_prediction(self, game_id: int) -> GamePredictionResponse:
        """Generate a new prediction using ML model."""
        # Get game data
        game = await self.db.get(Game, game_id)
        if not game:
            raise ValueError(f"Game {game_id} not found")

        # Generate prediction
        prediction_data = await self.predictor.predict_game(game)

        # Save to database
        prediction = Prediction(
            game_id=game_id,
            model_version=self.predictor.model_version,
            prediction_type='game_outcome',
            predicted_value=prediction_data,
            confidence=prediction_data['confidence'],
        )
        self.db.add(prediction)
        await self.db.commit()

        return self._to_response(prediction)

    async def calculate_accuracy(
        self,
        sport: Optional[str] = None,
        days: int = 30,
    ) -> PredictionAccuracyResponse:
        """Calculate prediction accuracy over a period."""
        start_date = datetime.now() - timedelta(days=days)

        query = (
            select(Prediction, Game)
            .join(Game)
            .where(
                Prediction.created_at >= start_date,
                Game.status == 'final',
            )
        )

        if sport:
            query = query.where(Game.sport == sport)

        result = await self.db.execute(query)
        predictions = result.all()

        # Calculate metrics
        correct = 0
        total = len(predictions)
        spread_errors = []
        by_sport = {}
        by_confidence = {'high': [], 'medium': [], 'low': []}

        for pred, game in predictions:
            predicted_winner = 'home' if pred.predicted_value['win_probability']['home'] > 0.5 else 'away'
            actual_winner = 'home' if game.home_score > game.away_score else 'away'

            is_correct = predicted_winner == actual_winner
            if is_correct:
                correct += 1

            # Track by sport
            if game.sport not in by_sport:
                by_sport[game.sport] = {'correct': 0, 'total': 0}
            by_sport[game.sport]['total'] += 1
            if is_correct:
                by_sport[game.sport]['correct'] += 1

            # Track by confidence tier
            conf = pred.confidence
            tier = 'high' if conf > 0.7 else 'medium' if conf > 0.5 else 'low'
            by_confidence[tier].append(is_correct)

            # Point spread error
            actual_spread = game.home_score - game.away_score
            predicted_spread = pred.predicted_value['point_spread']
            spread_errors.append(abs(actual_spread - predicted_spread))

        return PredictionAccuracyResponse(
            total_predictions=total,
            correct_predictions=correct,
            accuracy=correct / total if total > 0 else 0,
            by_sport={k: v['correct'] / v['total'] for k, v in by_sport.items()},
            by_confidence_tier={
                k: sum(v) / len(v) if v else 0 for k, v in by_confidence.items()
            },
            point_spread_mae=sum(spread_errors) / len(spread_errors) if spread_errors else 0,
            period_start=start_date,
            period_end=datetime.now(),
        )
```

## Database Session Management

```python
# app/db/session.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base

from app.config import settings

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    pool_size=20,
    max_overflow=10,
    pool_pre_ping=True,
)

async_session_maker = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

Base = declarative_base()


async def get_db() -> AsyncSession:
    """Dependency for getting database session."""
    async with async_session_maker() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
```

## Caching Layer

```python
# app/core/cache.py
import redis.asyncio as redis
import json
from functools import wraps
from typing import Optional, Callable
import hashlib

from app.config import settings

redis_client = redis.from_url(settings.REDIS_URL)


def cache(ttl: int = 300, prefix: str = ""):
    """Decorator for caching function results in Redis."""
    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Generate cache key
            key_data = f"{func.__name__}:{args}:{kwargs}"
            cache_key = f"{prefix}:{hashlib.md5(key_data.encode()).hexdigest()}"

            # Try to get from cache
            cached = await redis_client.get(cache_key)
            if cached:
                return json.loads(cached)

            # Execute function
            result = await func(*args, **kwargs)

            # Store in cache
            if result is not None:
                await redis_client.setex(
                    cache_key,
                    ttl,
                    json.dumps(result, default=str),
                )

            return result
        return wrapper
    return decorator


async def invalidate_pattern(pattern: str):
    """Invalidate all cache keys matching a pattern."""
    async for key in redis_client.scan_iter(match=pattern):
        await redis_client.delete(key)
```

## Authentication

```python
# app/core/security.py
from datetime import datetime, timedelta
from typing import Optional
from jose import jwt, JWTError
from passlib.context import CryptContext
from fastapi import HTTPException, Depends, status
from fastapi.security import OAuth2PasswordBearer

from app.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create JWT access token."""
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm="HS256")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash."""
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """Hash a password."""
    return pwd_context.hash(password)


async def get_current_user(token: str = Depends(oauth2_scheme)):
    """Dependency to get current authenticated user."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    # Get user from database
    # ...
    return user
```

## Error Handling

```python
# app/core/exceptions.py
from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse
from starlette.status import (
    HTTP_400_BAD_REQUEST,
    HTTP_404_NOT_FOUND,
    HTTP_500_INTERNAL_SERVER_ERROR,
)


class AppException(Exception):
    """Base application exception."""
    def __init__(self, message: str, status_code: int = HTTP_400_BAD_REQUEST):
        self.message = message
        self.status_code = status_code


class NotFoundException(AppException):
    def __init__(self, resource: str, id: int):
        super().__init__(
            message=f"{resource} with id {id} not found",
            status_code=HTTP_404_NOT_FOUND,
        )


class PredictionError(AppException):
    def __init__(self, message: str):
        super().__init__(
            message=f"Prediction failed: {message}",
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
        )


# Exception handlers
async def app_exception_handler(request: Request, exc: AppException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.message},
    )


async def general_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "An unexpected error occurred"},
    )
```

## Configuration

```python
# app/config.py
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # Application
    APP_NAME: str = "ML Sport Stat Predictor API"
    DEBUG: bool = False
    VERSION: str = "1.0.0"

    # Database
    DATABASE_URL: str
    DATABASE_POOL_SIZE: int = 20

    # Redis
    REDIS_URL: str = "redis://localhost:6379"

    # Security
    SECRET_KEY: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # ML
    ML_MODEL_PATH: str = "/models"
    MLFLOW_TRACKING_URI: str = "http://mlflow:5000"

    # CORS
    ALLOWED_ORIGINS: list[str] = ["http://localhost:3000"]

    class Config:
        env_file = ".env"


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
```

## Main Application

```python
# app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.config import settings
from app.api.v1.router import api_router
from app.core.exceptions import AppException, app_exception_handler
from app.db.session import engine


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    # Load ML models, warm up connections, etc.
    yield
    # Shutdown
    await engine.dispose()


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.VERSION,
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Exception handlers
app.add_exception_handler(AppException, app_exception_handler)

# Routes
app.include_router(api_router, prefix="/api/v1")


@app.get("/health")
async def health_check():
    return {"status": "healthy"}
```

## Testing

```python
# tests/conftest.py
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession

from app.main import app
from app.db.session import get_db, Base

TEST_DATABASE_URL = "postgresql+asyncpg://test:test@localhost:5432/test_db"


@pytest.fixture
async def db_session():
    engine = create_async_engine(TEST_DATABASE_URL)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSession(engine) as session:
        yield session

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest.fixture
async def client(db_session):
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db

    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client


# tests/api/test_games.py
import pytest

@pytest.mark.asyncio
async def test_list_games(client, db_session):
    response = await client.get("/api/v1/games")
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data


@pytest.mark.asyncio
async def test_get_game_not_found(client):
    response = await client.get("/api/v1/games/99999")
    assert response.status_code == 404
```
