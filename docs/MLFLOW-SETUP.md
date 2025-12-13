# MLflow Setup Guide

This document describes the MLflow configuration for experiment tracking, model versioning, and artifact storage in the ML Sport Stat Predictor project.

## Overview

MLflow is configured with the following components:

- **Tracking Backend**: PostgreSQL (for experiment metadata, parameters, metrics)
- **Artifact Storage**: MinIO (S3-compatible object storage)
- **Model Registry**: Enabled via PostgreSQL backend
- **Authentication**: Basic authentication with username/password

## Architecture

```
┌─────────────┐
│   Backend   │──────┐
│   (FastAPI) │      │
└─────────────┘      │
                     ▼
┌─────────────┐  ┌──────────┐  ┌────────────┐
│  ML Scripts │─▶│  MLflow  │─▶│ PostgreSQL │
└─────────────┘  │  Server  │  │ (Tracking) │
                 └──────────┘  └────────────┘
                     │
                     ▼
                 ┌──────────┐
                 │  MinIO   │
                 │(Artifacts)│
                 └──────────┘
```

## Configuration Details

### 1. PostgreSQL Tracking Backend

- **Database**: `mlflow` (auto-created via init-db.sh)
- **Connection**: Through PgBouncer connection pooler
- **Purpose**: Stores experiment runs, parameters, metrics, tags, and model registry metadata

### 2. MinIO Artifact Storage

- **Type**: S3-compatible object storage
- **Bucket**: `mlflow`
- **Access**: Via AWS SDK (boto3)
- **Purpose**: Stores model artifacts, plots, files, and large objects

**MinIO Ports**:
- API: `9000`
- Console: `9001`

### 3. MLflow Authentication

**Default Credentials**:
- Username: `admin`
- Password: `admin_password`

**Configuration File**: `mlflow/auth/basic_auth.ini`

**Security Notes**:
- Change default credentials in production
- Update via `.env` file: `MLFLOW_ADMIN_USERNAME` and `MLFLOW_ADMIN_PASSWORD`
- User database stored in SQLite: `mlflow/auth/basic_auth.db`

### 4. Model Registry

The model registry is automatically enabled when using PostgreSQL as the backend store. It provides:

- Model versioning
- Stage transitions (None, Staging, Production, Archived)
- Model lineage tracking
- Descriptions and tags

## Environment Variables

Add these to your `.env` file (already in `.env.example`):

```bash
# MinIO Configuration
MINIO_ROOT_USER=minio_admin
MINIO_ROOT_PASSWORD=minio_password_change_in_production
MINIO_PORT=9000
MINIO_CONSOLE_PORT=9001

# MLflow Configuration
MLFLOW_PORT=5000
MLFLOW_ADMIN_USERNAME=admin
MLFLOW_ADMIN_PASSWORD=admin_password_change_in_production

# MLflow Tracking (for clients)
MLFLOW_TRACKING_USERNAME=admin
MLFLOW_TRACKING_PASSWORD=admin_password_change_in_production
```

## Usage

### Starting Services

```bash
# Start all services including MLflow
make up

# View MLflow logs
make logs-mlflow

# Access MLflow shell
make shell-mlflow
```

### Accessing MLflow UI

1. Navigate to: http://localhost:5000
2. Login with credentials (default: admin / admin_password)
3. View experiments, runs, and models

### Accessing MinIO Console

1. Navigate to: http://localhost:9001
2. Login with credentials (default: minio_admin / minio_password)
3. View stored artifacts in the `mlflow` bucket

### Using MLflow in Python Code

```python
import mlflow
import os

# Set tracking URI and credentials
mlflow.set_tracking_uri("http://mlflow:5000")
os.environ["MLFLOW_TRACKING_USERNAME"] = "admin"
os.environ["MLFLOW_TRACKING_PASSWORD"] = "admin_password"

# Configure S3 endpoint for MinIO
os.environ["AWS_ACCESS_KEY_ID"] = "minio_admin"
os.environ["AWS_SECRET_ACCESS_KEY"] = "minio_password"
os.environ["MLFLOW_S3_ENDPOINT_URL"] = "http://minio:9000"

# Start an experiment
mlflow.set_experiment("nfl-prediction")

# Log a run
with mlflow.start_run(run_name="random_forest_v1"):
    # Log parameters
    mlflow.log_param("n_estimators", 100)
    mlflow.log_param("max_depth", 10)

    # Log metrics
    mlflow.log_metric("accuracy", 0.85)
    mlflow.log_metric("f1_score", 0.82)

    # Log model
    mlflow.sklearn.log_model(model, "model")

    # Log artifacts
    mlflow.log_artifact("confusion_matrix.png")
```

### Using the Model Registry

```python
import mlflow

# Register a model
result = mlflow.register_model(
    model_uri="runs:/<run_id>/model",
    name="nfl-win-predictor"
)

# Transition model to production
client = mlflow.tracking.MlflowClient()
client.transition_model_version_stage(
    name="nfl-win-predictor",
    version=1,
    stage="Production"
)

# Load a production model
model = mlflow.pyfunc.load_model(
    model_uri="models:/nfl-win-predictor/Production"
)
```

## User Management

### Creating New Users

```bash
# Access MLflow container
docker compose exec mlflow bash

# Create a new user
mlflow server auth create-user --username john --password secure_password

# Update user permissions
mlflow server auth update-user --username john --admin
```

### Listing Users

```bash
docker compose exec mlflow bash
mlflow server auth list-users
```

## Health Checks

```bash
# Check all services including MLflow
make health

# Manual MLflow health check
curl http://localhost:5000/health
```

## Troubleshooting

### MLflow Can't Connect to PostgreSQL

1. Check PostgreSQL is running: `docker compose ps postgres`
2. Check MLflow logs: `make logs-mlflow`
3. Verify database exists: `docker compose exec postgres psql -U mlsp_user -l`

### Artifacts Not Uploading to MinIO

1. Check MinIO is running: `docker compose ps minio`
2. Verify bucket exists: Check MinIO console at http://localhost:9001
3. Check environment variables are set correctly
4. Verify network connectivity: `docker compose exec backend ping minio`

### Authentication Failures

1. Check credentials in `.env` file
2. Verify `basic_auth.ini` configuration in `mlflow/auth/`
3. Check MLflow logs for auth errors: `make logs-mlflow`
4. Reset auth database if needed: `rm mlflow/auth/basic_auth.db` and restart

### MinIO Bucket Not Created

1. Check minio-init logs: `docker compose logs minio-init`
2. Manually create bucket via MinIO console
3. Restart minio-init: `docker compose up -d minio-init`

## Production Considerations

1. **Security**:
   - Change all default passwords
   - Use strong, unique passwords
   - Consider external authentication (LDAP, OAuth)
   - Enable HTTPS/TLS
   - Rotate credentials regularly

2. **Storage**:
   - MinIO volumes should be backed up regularly
   - Consider using AWS S3 instead of MinIO for production
   - Monitor storage usage and set up alerts

3. **Performance**:
   - Scale MLflow server horizontally if needed
   - Use separate PostgreSQL instance for production
   - Configure MinIO with multiple drives for better performance

4. **Monitoring**:
   - Set up logging and monitoring for MLflow
   - Track artifact storage usage
   - Monitor database performance

## Migration to AWS S3 (Production)

To use AWS S3 instead of MinIO in production:

1. Create an S3 bucket (e.g., `mlsp-mlflow-artifacts`)
2. Create IAM user with S3 access
3. Update MLflow command in `docker-compose.prod.yml`:

```yaml
command: >
  mlflow server
  --backend-store-uri postgresql://...
  --default-artifact-root s3://mlsp-mlflow-artifacts/
  --host 0.0.0.0
  --port 5000
  --app-name basic-auth
```

4. Update environment variables:
```bash
AWS_ACCESS_KEY_ID=<your-aws-key>
AWS_SECRET_ACCESS_KEY=<your-aws-secret>
AWS_DEFAULT_REGION=us-east-1
# Remove MLFLOW_S3_ENDPOINT_URL
```

## References

- [MLflow Documentation](https://mlflow.org/docs/latest/index.html)
- [MLflow Authentication](https://mlflow.org/docs/latest/auth/index.html)
- [MLflow Model Registry](https://mlflow.org/docs/latest/model-registry.html)
- [MinIO Documentation](https://min.io/docs/minio/linux/index.html)
