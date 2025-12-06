"""
Redis Client Configuration and Management
"""
import redis.asyncio as redis
from typing import Optional
import logging
from contextlib import asynccontextmanager

from .config import get_settings

logger = logging.getLogger(__name__)


class RedisClient:
    """Redis client manager with connection pooling"""

    def __init__(self):
        self._redis: Optional[redis.Redis] = None
        self._settings = get_settings()

    async def connect(self) -> None:
        """Initialize Redis connection pool"""
        try:
            self._redis = redis.from_url(
                self._settings.REDIS_URL,
                encoding="utf-8",
                decode_responses=self._settings.REDIS_DECODE_RESPONSES,
                max_connections=self._settings.REDIS_MAX_CONNECTIONS,
                socket_connect_timeout=5,
                socket_keepalive=True,
                health_check_interval=30,
            )
            # Test connection
            await self._redis.ping()
            logger.info("✓ Redis connection established successfully")
        except Exception as e:
            logger.error(f"✗ Failed to connect to Redis: {e}")
            raise

    async def disconnect(self) -> None:
        """Close Redis connection pool"""
        if self._redis:
            await self._redis.close()
            logger.info("Redis connection closed")

    async def ping(self) -> bool:
        """Check if Redis is accessible"""
        try:
            if self._redis:
                return await self._redis.ping()
            return False
        except Exception as e:
            logger.error(f"Redis ping failed: {e}")
            return False

    @property
    def client(self) -> redis.Redis:
        """Get Redis client instance"""
        if self._redis is None:
            raise RuntimeError("Redis client is not initialized. Call connect() first.")
        return self._redis

    # Cache helper methods
    async def get_cache(self, key: str) -> Optional[str]:
        """Get value from cache"""
        try:
            return await self._redis.get(key)
        except Exception as e:
            logger.error(f"Cache get error for key {key}: {e}")
            return None

    async def set_cache(self, key: str, value: str, ttl: Optional[int] = None) -> bool:
        """Set value in cache with optional TTL"""
        try:
            if ttl:
                await self._redis.setex(key, ttl, value)
            else:
                await self._redis.set(key, value)
            return True
        except Exception as e:
            logger.error(f"Cache set error for key {key}: {e}")
            return False

    async def delete_cache(self, key: str) -> bool:
        """Delete key from cache"""
        try:
            await self._redis.delete(key)
            return True
        except Exception as e:
            logger.error(f"Cache delete error for key {key}: {e}")
            return False

    async def clear_pattern(self, pattern: str) -> int:
        """Clear all keys matching pattern"""
        try:
            keys = []
            async for key in self._redis.scan_iter(match=pattern):
                keys.append(key)

            if keys:
                return await self._redis.delete(*keys)
            return 0
        except Exception as e:
            logger.error(f"Cache clear pattern error for {pattern}: {e}")
            return 0

    async def get_info(self) -> dict:
        """Get Redis server info"""
        try:
            info = await self._redis.info()
            return {
                "version": info.get("redis_version"),
                "uptime_seconds": info.get("uptime_in_seconds"),
                "connected_clients": info.get("connected_clients"),
                "used_memory_human": info.get("used_memory_human"),
                "total_commands_processed": info.get("total_commands_processed"),
                "keyspace_hits": info.get("keyspace_hits", 0),
                "keyspace_misses": info.get("keyspace_misses", 0),
            }
        except Exception as e:
            logger.error(f"Failed to get Redis info: {e}")
            return {}


# Global Redis client instance
redis_client = RedisClient()


async def get_redis() -> redis.Redis:
    """Dependency to get Redis client for FastAPI"""
    return redis_client.client


@asynccontextmanager
async def get_redis_context():
    """Context manager for Redis operations"""
    client = redis_client.client
    try:
        yield client
    finally:
        # Connection is managed by the pool, no need to close here
        pass
