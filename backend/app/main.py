"""
ML Sport Stat Predictor - Main FastAPI Application
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging

from app.core.config import get_settings
from app.core.redis import redis_client

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events"""
    # Startup
    logger.info("Starting ML Sport Stat Predictor API...")
    try:
        await redis_client.connect()
        logger.info("All services initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize services: {e}")
        raise

    yield

    # Shutdown
    logger.info("Shutting down ML Sport Stat Predictor API...")
    await redis_client.disconnect()
    logger.info("Shutdown complete")


# Create FastAPI app
app = FastAPI(
    title="ML Sport Stat Predictor API",
    description="Machine Learning platform for predicting sports game outcomes",
    version="0.1.0",
    lifespan=lifespan,
)

# Configure CORS
origins = settings.CORS_ORIGINS.split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "ML Sport Stat Predictor API",
        "version": "0.1.0",
        "status": "running"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint with service connectivity verification"""
    redis_status = "disconnected"
    redis_info = {}

    # Check Redis connectivity
    try:
        if await redis_client.ping():
            redis_status = "connected"
            redis_info = await redis_client.get_info()
    except Exception as e:
        logger.error(f"Redis health check failed: {e}")
        redis_status = "error"

    # Overall health status
    is_healthy = redis_status == "connected"

    return {
        "status": "healthy" if is_healthy else "degraded",
        "service": "backend",
        "version": "0.1.0",
        "environment": settings.ENVIRONMENT,
        "services": {
            "database": "not_implemented",  # TODO: Add actual DB check
            "cache": {
                "status": redis_status,
                "info": redis_info,
            }
        }
    }


@app.get("/api/v1/status")
async def api_status():
    """API status endpoint"""
    return {
        "api_version": "v1",
        "status": "operational",
        "features": {
            "predictions": "coming soon",
            "statistics": "coming soon",
            "models": "coming soon"
        }
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
