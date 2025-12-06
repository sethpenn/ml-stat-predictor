# Apache Airflow Setup Documentation

## Overview

Apache Airflow has been successfully configured for orchestrating data pipelines and ML training workflows in the ML Sport Stat Predictor project.

## Architecture

### Components

1. **Airflow Webserver** (Port 8080)
   - Provides the web UI for monitoring and managing DAGs
   - Container: `mlsp-airflow-webserver`
   - Health check: http://localhost:8080/health

2. **Airflow Scheduler**
   - Schedules and triggers DAG runs
   - Container: `mlsp-airflow-scheduler`
   - Monitors the `dags/` directory for changes

3. **Airflow Worker**
   - Executes tasks using CeleryExecutor
   - Container: `mlsp-airflow-worker`
   - Scales horizontally for increased throughput

4. **Airflow Init**
   - One-time initialization container
   - Creates admin user and initializes the metadata database
   - Container: `mlsp-airflow-init` (runs once then exits)

### Infrastructure

- **Metadata Database**: PostgreSQL (via PgBouncer on port 6432)
  - Database: `airflow`
  - Connection pooling via PgBouncer for optimal performance

- **Message Broker**: Redis (port 6379, database 1)
  - Used for Celery task queue
  - Handles communication between scheduler and workers

- **Rate Limiting**: Redis (database 2)
  - Stores rate limit data for the webserver

## Configuration

### Environment Variables

Key Airflow configuration from `.env`:

```bash
# Airflow Webserver
AIRFLOW_WEBSERVER_PORT=8080

# Admin User
AIRFLOW_ADMIN_USERNAME=admin
AIRFLOW_ADMIN_PASSWORD=admin
AIRFLOW_ADMIN_EMAIL=admin@example.com

# Security
AIRFLOW_FERNET_KEY=<generated-key>

# Database
AIRFLOW_DB=airflow
```

### Executor Configuration

- **Executor Type**: CeleryExecutor
- **Parallelism**: Configurable via worker scaling
- **DAGs Paused at Creation**: Yes (for safety)
- **Load Examples**: No (disabled to keep UI clean)

### Connection Pooling (PgBouncer)

```ini
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 25
min_pool_size = 10
reserve_pool_size = 5
```

## Accessing Airflow

### Web UI

1. **URL**: http://localhost:8080
2. **Username**: `admin` (or value from `AIRFLOW_ADMIN_USERNAME`)
3. **Password**: `admin` (or value from `AIRFLOW_ADMIN_PASSWORD`)

### Key Features Available

- DAG overview and management
- Task execution monitoring
- Log viewing
- Connection management
- Variable management
- User administration

## Available DAGs

### 1. example_dag
- **Purpose**: Verify Airflow setup
- **Schedule**: Manual trigger only
- **Tasks**: Basic Python and Bash operations
- **Status**: Paused (enable manually for testing)

### 2. sports_data_scraper
- **Purpose**: Daily scraping of sports data (NFL, NBA, MLB)
- **Schedule**: Daily at 6 AM UTC (`0 6 * * *`)
- **Tasks**:
  - Parallel scraping of NFL, NBA, MLB data
  - Data validation
  - Database loading
- **Status**: Paused (enable when scrapers are implemented)

### 3. ml_model_training
- **Purpose**: Weekly ML model training and deployment
- **Schedule**: Weekly on Sunday at 2 AM UTC (`0 2 * * 0`)
- **Tasks**:
  - Data preparation
  - Parallel model training (NFL, NBA, MLB)
  - Model evaluation
  - MLflow registration
  - Model deployment
- **Status**: Paused (enable when ML modules are ready)

## Configured Connections

The following Airflow connections are pre-configured:

| Connection ID | Type | Description |
|---------------|------|-------------|
| `postgres_mlsp` | PostgreSQL | Main application database |
| `postgres_mlflow` | PostgreSQL | MLflow metadata database |
| `redis_default` | Redis | Redis cache (database 0) |
| `mlflow_tracking` | HTTP | MLflow tracking server |
| `backend_api` | HTTP | FastAPI backend service |

### Using Connections in DAGs

```python
from airflow.providers.postgres.hooks.postgres import PostgresHook

# Use in a task
def my_task():
    hook = PostgresHook(postgres_conn_id='postgres_mlsp')
    records = hook.get_records("SELECT * FROM games LIMIT 10")
    return records
```

## Management Scripts

### Generate Fernet Key

```bash
bash scripts/generate-fernet-key.sh
```

This script generates a new Fernet key for Airflow encryption and optionally updates the `.env` file.

### Setup Connections

```bash
bash scripts/setup-airflow-connections.sh
```

This script creates all predefined Airflow connections for external services.

## Docker Commands

### Start Airflow Services

```bash
# Start all services
docker-compose up -d

# Start only Airflow services
docker-compose up -d airflow-webserver airflow-scheduler airflow-worker
```

### View Logs

```bash
# Webserver logs
docker logs mlsp-airflow-webserver -f

# Scheduler logs
docker logs mlsp-airflow-scheduler -f

# Worker logs
docker logs mlsp-airflow-worker -f
```

### Airflow CLI Commands

```bash
# List DAGs
docker exec mlsp-airflow-scheduler airflow dags list

# Trigger a DAG
docker exec mlsp-airflow-scheduler airflow dags trigger example_dag

# Test a task
docker exec mlsp-airflow-scheduler airflow tasks test example_dag print_hello 2024-01-01

# List connections
docker exec mlsp-airflow-scheduler airflow connections list

# Create a connection
docker exec mlsp-airflow-scheduler airflow connections add my_conn \
    --conn-type postgres \
    --conn-host localhost \
    --conn-login user \
    --conn-password pass
```

### Restart Services

```bash
# Restart all Airflow services
docker-compose restart airflow-webserver airflow-scheduler airflow-worker

# Restart individual service
docker-compose restart airflow-scheduler
```

## Development Workflow

### Creating a New DAG

1. Create a new Python file in `data_pipeline/dags/`
2. Define the DAG using Airflow's context manager syntax
3. Airflow will automatically detect the new DAG (may take up to 30 seconds)
4. Enable the DAG in the web UI
5. Test with a manual trigger

### Testing DAGs Locally

```bash
# Syntax check
python data_pipeline/dags/my_new_dag.py

# Test a specific task
docker exec mlsp-airflow-scheduler airflow tasks test my_new_dag task_name 2024-01-01

# Run the entire DAG
docker exec mlsp-airflow-scheduler airflow dags test my_new_dag 2024-01-01
```

### Debugging

1. **Check Scheduler Logs**:
   ```bash
   docker logs mlsp-airflow-scheduler --tail 100
   ```

2. **Check Task Logs**:
   - Navigate to the Airflow UI
   - Click on the DAG → Task → Log

3. **Check Worker Logs**:
   ```bash
   docker logs mlsp-airflow-worker --tail 100
   ```

4. **Database Connection Issues**:
   ```bash
   # Test database connection
   docker exec mlsp-airflow-scheduler airflow db check

   # Check PgBouncer connectivity
   docker exec mlsp-airflow-scheduler psql -h pgbouncer -p 6432 -U mlsp_user -d airflow -c "SELECT 1;"
   ```

## Monitoring and Maintenance

### Health Checks

All Airflow containers have health checks configured:

```bash
# Check container health
docker-compose ps

# Healthy containers will show (healthy) status
```

### Metadata Database

The Airflow metadata database is automatically backed up with the PostgreSQL container volume.

### Cleaning Old Data

```bash
# Clean old task instances (older than 30 days)
docker exec mlsp-airflow-scheduler airflow db clean --clean-before-timestamp "$(date -d '30 days ago' '+%Y-%m-%d')"
```

## Security

### Authentication

- **Web UI**: Username/password authentication (Flask-AppBuilder)
- **API**: Basic auth and session-based auth enabled
- **Default Admin**: Change the default admin password in production!

### Encryption

- **Fernet Key**: Used to encrypt sensitive data in the metadata database
- **Generation**: Use `scripts/generate-fernet-key.sh`
- **Rotation**: Update `AIRFLOW_FERNET_KEY` in `.env` and restart services

### Network Security

- Airflow services run in isolated Docker network (`mlsp-network`)
- Only webserver port (8080) is exposed to host
- Internal services communicate via Docker network

## Performance Tuning

### Worker Scaling

```bash
# Scale workers horizontally
docker-compose up -d --scale airflow-worker=3
```

### Connection Pool Tuning

Edit `pgbouncer/pgbouncer.ini`:

```ini
default_pool_size = 25      # Connections per database
max_client_conn = 1000      # Maximum client connections
```

### Redis Configuration

Edit `redis/redis.conf`:

```conf
maxmemory 512mb
maxmemory-policy allkeys-lru
```

## Troubleshooting

### Common Issues

#### DAG Not Appearing

- **Cause**: Python syntax error or import error
- **Solution**: Check scheduler logs for import errors

#### Tasks Stuck in Queued State

- **Cause**: Workers not running or overloaded
- **Solution**: Check worker health, scale workers if needed

#### Connection Refused Errors

- **Cause**: Database or Redis not ready
- **Solution**: Wait for health checks to pass, check service logs

#### ImportError in DAGs

- **Cause**: Missing Python dependencies
- **Solution**: Add dependencies to `data_pipeline/requirements.txt` and rebuild

## Next Steps

1. **Implement Scrapers**: Add scraper modules in `data_pipeline/scrapers/`
2. **Create Production DAGs**: Implement actual data processing logic
3. **Add ML Training**: Implement model training in `ml/` directory
4. **Configure Alerts**: Set up email alerts for task failures
5. **Add Monitoring**: Integrate with monitoring tools (e.g., Prometheus, Grafana)
6. **Implement SLAs**: Add SLA monitoring for critical DAGs
7. **Set up CI/CD**: Automate DAG testing and deployment

## Resources

- [Airflow Documentation](https://airflow.apache.org/docs/)
- [Airflow Best Practices](https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html)
- [CeleryExecutor Guide](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/executor/celery.html)
- [Project Documentation](../docs/)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Airflow logs
3. Consult the project documentation in `/docs`
4. Check the example DAGs for reference patterns
