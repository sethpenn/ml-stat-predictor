#!/bin/bash
# Setup Airflow connections for external services
# This script creates connections that can be used in DAGs

set -e

echo "Setting up Airflow connections..."
echo ""

# Load environment variables from .env file
if [ -f .env ]; then
    # Parse .env file more carefully, avoiding comments and special characters
    while IFS='=' read -r key value; do
        # Skip empty lines and comments
        if [[ ! -z "$key" && ! "$key" =~ ^# ]]; then
            # Remove quotes and export
            value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
            export "$key=$value"
        fi
    done < <(grep -v '^#' .env | grep -v '^$')
else
    echo "Warning: .env file not found. Using default values."
fi

# Wait for Airflow webserver to be ready
echo "Waiting for Airflow webserver to be ready..."
until curl -s http://localhost:${AIRFLOW_WEBSERVER_PORT:-8080}/health > /dev/null 2>&1; do
    echo "Waiting for Airflow webserver..."
    sleep 5
done
echo "✓ Airflow webserver is ready"
echo ""

# Create connections using Airflow CLI
echo "Creating Airflow connections..."

# PostgreSQL main database connection
docker exec mlsp-airflow-scheduler airflow connections add 'postgres_mlsp' \
    --conn-type 'postgres' \
    --conn-host 'pgbouncer' \
    --conn-port '6432' \
    --conn-schema 'mlsp' \
    --conn-login "${POSTGRES_USER:-mlsp_user}" \
    --conn-password "${POSTGRES_PASSWORD:-mlsp_password}" \
    2>/dev/null && echo "✓ Created postgres_mlsp connection" || echo "  postgres_mlsp already exists"

# PostgreSQL MLflow database connection
docker exec mlsp-airflow-scheduler airflow connections add 'postgres_mlflow' \
    --conn-type 'postgres' \
    --conn-host 'pgbouncer' \
    --conn-port '6432' \
    --conn-schema 'mlflow' \
    --conn-login "${POSTGRES_USER:-mlsp_user}" \
    --conn-password "${POSTGRES_PASSWORD:-mlsp_password}" \
    2>/dev/null && echo "✓ Created postgres_mlflow connection" || echo "  postgres_mlflow already exists"

# Redis connection
docker exec mlsp-airflow-scheduler airflow connections add 'redis_default' \
    --conn-type 'redis' \
    --conn-host 'redis' \
    --conn-port '6379' \
    --conn-password "${REDIS_PASSWORD:-redis_password}" \
    --conn-extra '{"db": 0}' \
    2>/dev/null && echo "✓ Created redis_default connection" || echo "  redis_default already exists"

# MLflow tracking server connection
docker exec mlsp-airflow-scheduler airflow connections add 'mlflow_tracking' \
    --conn-type 'http' \
    --conn-host 'mlflow' \
    --conn-port '5000' \
    --conn-schema 'http' \
    2>/dev/null && echo "✓ Created mlflow_tracking connection" || echo "  mlflow_tracking already exists"

# Backend API connection
docker exec mlsp-airflow-scheduler airflow connections add 'backend_api' \
    --conn-type 'http' \
    --conn-host 'backend' \
    --conn-port '8000' \
    --conn-schema 'http' \
    2>/dev/null && echo "✓ Created backend_api connection" || echo "  backend_api already exists"

echo ""
echo "✓ Airflow connections setup completed!"
echo ""
echo "You can view and manage connections in the Airflow UI:"
echo "http://localhost:${AIRFLOW_WEBSERVER_PORT:-8080}/connection/list/"
echo ""
echo "Login credentials:"
echo "Username: ${AIRFLOW_ADMIN_USERNAME:-admin}"
echo "Password: ${AIRFLOW_ADMIN_PASSWORD:-admin}"
