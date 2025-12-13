FROM ghcr.io/mlflow/mlflow:v2.9.2

# Install PostgreSQL client and build dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install required Python packages
# - psycopg2-binary: PostgreSQL support for tracking backend
# - boto3: AWS SDK for S3-compatible storage (MinIO)
# - cryptography: Required for MLflow authentication
RUN pip install --no-cache-dir \
    psycopg2-binary==2.9.9 \
    boto3==1.34.16 \
    cryptography==41.0.7

# Create directory for MLflow artifacts (fallback)
RUN mkdir -p /mlflow/artifacts

# Default command (overridden in docker-compose)
CMD ["mlflow", "server", "--host", "0.0.0.0", "--port", "5000"]
