#!/bin/bash
set -e

# This script runs on PostgreSQL container initialization

echo "Creating additional databases..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create Airflow database
    CREATE DATABASE airflow;
    GRANT ALL PRIVILEGES ON DATABASE airflow TO $POSTGRES_USER;

    -- Create MLflow database
    CREATE DATABASE mlflow;
    GRANT ALL PRIVILEGES ON DATABASE mlflow TO $POSTGRES_USER;

    -- Enable TimescaleDB extension on main database
    \c $POSTGRES_DB;
    CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

    -- Enable required extensions
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
EOSQL

echo "Additional databases created successfully!"
