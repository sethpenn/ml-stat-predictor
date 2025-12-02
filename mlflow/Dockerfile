FROM ghcr.io/mlflow/mlflow:v2.9.2

# Install PostgreSQL client and build dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install psycopg2-binary for PostgreSQL support
RUN pip install --no-cache-dir psycopg2-binary

# Default command
CMD ["mlflow", "server", "--host", "0.0.0.0", "--port", "5000"]
