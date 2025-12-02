"""
Custom Airflow webserver configuration
"""
import os
from flask_appbuilder.security.manager import AUTH_DB

# Flask-AppBuilder configuration
AUTH_TYPE = AUTH_DB

# Rate limiting configuration for flask-limiter
# Use Redis for rate limit storage instead of in-memory
RATELIMIT_STORAGE_URI = os.getenv(
    'RATELIMIT_STORAGE_URI',
    'redis://:redis_password@redis:6379/2'
)
