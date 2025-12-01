# Docker Setup Guide

This guide covers the Docker configuration for the ML Sport Stat Predictor platform, including local development and production deployment.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Architecture Overview](#architecture-overview)
4. [Environment Configuration](#environment-configuration)
5. [Development Workflow](#development-workflow)
6. [Production Deployment](#production-deployment)
7. [Common Commands](#common-commands)
8. [Troubleshooting](#troubleshooting)
9. [Performance Tuning](#performance-tuning)

---

## Prerequisites

### Required Software

- **Docker**: Version 24.0 or higher
- **Docker Compose**: Version 2.20 or higher
- **Git**: For version control
- **Make**: (Optional) For using Makefile commands

### System Requirements

**Minimum:**
- 8 GB RAM
- 4 CPU cores
- 20 GB free disk space

**Recommended:**
- 16 GB RAM
- 8 CPU cores
- 50 GB free disk space (for datasets and model artifacts)

### Verify Installation

```bash
docker --version
docker compose version
```

---

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd ml-stat-predictor
```

### 2. Set Up Environment Variables

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your preferred text editor
nano .env
```

**Important:** Generate a secure Airflow Fernet key:

```bash
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

Add the generated key to your `.env` file under `AIRFLOW_FERNET_KEY`.

### 3. Start All Services

```bash
# Development environment
docker compose up -d

# Or with build (first time or after code changes)
docker compose up -d --build
```

### 4. Verify Services

```bash
# Check all containers are running
docker compose ps

# View logs
docker compose logs -f
```

### 5. Access Applications

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| Frontend | http://localhost:3000 | N/A |
| Backend API | http://localhost:8000 | N/A |
| API Docs | http://localhost:8000/docs | N/A |
| Airflow UI | http://localhost:8080 | admin / admin |
| MLflow UI | http://localhost:5000 | N/A |
| PostgreSQL | localhost:5432 | mlsp_user / mlsp_password |
| Redis | localhost:6379 | Password: redis_password |

---

## Architecture Overview

### Services

The platform consists of the following Docker services:

```
┌─────────────────────────────────────────────────────────────┐
│                        Docker Network                        │
│                                                               │
│  ┌──────────┐  ┌──────────┐  ┌────────────┐  ┌───────────┐ │
│  │ Frontend │  │ Backend  │  │ Airflow    │  │  MLflow   │ │
│  │  (React) │  │ (FastAPI)│  │ (Scheduler)│  │           │ │
│  └────┬─────┘  └────┬─────┘  └─────┬──────┘  └─────┬─────┘ │
│       │             │               │                │       │
│       │             └───────┬───────┴────────────────┘       │
│       │                     │                                │
│  ┌────┴─────┐  ┌───────────┴────────┐  ┌──────────────┐    │
│  │PostgreSQL│  │       Redis         │  │   Volumes    │    │
│  │TimescaleDB│  │   (Cache/Broker)   │  │   (Data)     │    │
│  └──────────┘  └────────────────────┘  └──────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### Docker Volumes

Persistent data is stored in named volumes:

- `postgres_data`: PostgreSQL database files
- `redis_data`: Redis persistence files
- `airflow_data`: Airflow metadata and logs
- `mlflow_data`: MLflow artifacts and models
- `backend_cache`: Python package cache (dev only)

### Networks

All services communicate through a dedicated bridge network: `mlsp-network`

---

## Environment Configuration

### Environment Variables

The `.env` file controls all configuration. Key variables:

#### Database Configuration

```bash
POSTGRES_DB=mlsp
POSTGRES_USER=mlsp_user
POSTGRES_PASSWORD=your-secure-password
POSTGRES_PORT=5432
```

#### API Configuration

```bash
BACKEND_PORT=8000
SECRET_KEY=your-secret-key-min-32-chars
LOG_LEVEL=INFO
```

#### Frontend Configuration

```bash
FRONTEND_PORT=3000
VITE_API_URL=http://localhost:8000
```

#### Airflow Configuration

```bash
AIRFLOW_WEBSERVER_PORT=8080
AIRFLOW_ADMIN_USERNAME=admin
AIRFLOW_ADMIN_PASSWORD=your-secure-password
AIRFLOW_FERNET_KEY=your-generated-fernet-key
```

### Security Best Practices

1. **Never commit `.env` file** to version control
2. **Use strong passwords** for all services (minimum 16 characters)
3. **Rotate secrets regularly** in production environments
4. **Limit service exposure** - only expose necessary ports

---

## Development Workflow

### Hot Reloading

All services support hot reloading in development mode:

- **Backend**: Uvicorn auto-reloads on Python file changes
- **Frontend**: Vite HMR (Hot Module Replacement) for instant updates
- **Airflow**: DAG files are watched for changes

### Volume Mounts

Development containers mount source code as volumes:

```yaml
# Backend
volumes:
  - ./backend:/app

# Frontend
volumes:
  - ./frontend:/app
  - /app/node_modules  # Prevents overwriting node_modules

# Airflow
volumes:
  - ./data_pipeline/dags:/opt/airflow/dags
  - ./data_pipeline/scrapers:/opt/airflow/scrapers
```

### Running Tests

```bash
# Backend tests
docker compose exec backend pytest

# Backend tests with coverage
docker compose exec backend pytest --cov=app --cov-report=html

# Frontend tests
docker compose exec frontend npm test

# Frontend tests with coverage
docker compose exec frontend npm test -- --coverage
```

### Database Migrations

```bash
# Generate a new migration
docker compose exec backend alembic revision --autogenerate -m "description"

# Apply migrations
docker compose exec backend alembic upgrade head

# Rollback migration
docker compose exec backend alembic downgrade -1

# View migration history
docker compose exec backend alembic history
```

### Accessing Services

```bash
# Backend shell
docker compose exec backend bash

# Python shell with app context
docker compose exec backend python

# Frontend shell
docker compose exec frontend sh

# Database shell
docker compose exec postgres psql -U mlsp_user -d mlsp

# Redis CLI
docker compose exec redis redis-cli -a redis_password

# Airflow CLI
docker compose exec airflow-scheduler airflow dags list
```

---

## Production Deployment

### Building Production Images

```bash
# Build all production images
docker compose -f docker-compose.yml -f docker-compose.prod.yml build

# Build specific service
docker compose -f docker-compose.yml -f docker-compose.prod.yml build backend
```

### Starting Production Environment

```bash
# Start with production overrides
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Production Differences

1. **Multi-stage builds** for smaller image sizes
2. **No volume mounts** for source code
3. **Production servers**: Gunicorn for backend, Nginx for frontend
4. **Health checks** enabled for all services
5. **Restart policies**: `unless-stopped` for automatic recovery
6. **Nginx reverse proxy** for routing and SSL termination

### SSL/TLS Configuration

1. Place SSL certificates in `nginx/ssl/`:
   - `cert.pem` - SSL certificate
   - `key.pem` - Private key

2. Update `.env`:
   ```bash
   DOMAIN=your-domain.com
   ```

3. Uncomment HTTPS server block in `nginx/nginx.conf`

### Environment-Specific Settings

Update `.env` for production:

```bash
ENVIRONMENT=production
LOG_LEVEL=WARNING
SECRET_KEY=your-production-secret-key
POSTGRES_PASSWORD=strong-production-password
REDIS_PASSWORD=strong-redis-password
AIRFLOW_ADMIN_PASSWORD=strong-airflow-password
```

---

## Common Commands

### Service Management

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart specific service
docker compose restart backend

# View service logs
docker compose logs -f backend

# View logs for all services
docker compose logs -f

# Scale a service (e.g., multiple workers)
docker compose up -d --scale airflow-worker=3
```

### Container Management

```bash
# List running containers
docker compose ps

# Execute command in container
docker compose exec backend python manage.py

# Run one-off command
docker compose run --rm backend pytest

# Remove stopped containers
docker compose rm

# Stop and remove all containers, networks, and volumes
docker compose down -v
```

### Image Management

```bash
# Build images
docker compose build

# Build with no cache
docker compose build --no-cache

# Pull latest images
docker compose pull

# Remove unused images
docker image prune -a
```

### Volume Management

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect mlsp_postgres_data

# Backup database
docker compose exec postgres pg_dump -U mlsp_user mlsp > backup.sql

# Restore database
docker compose exec -T postgres psql -U mlsp_user mlsp < backup.sql

# Remove all volumes (WARNING: deletes all data)
docker compose down -v
```

### Monitoring

```bash
# View resource usage
docker stats

# View container processes
docker compose top

# Check service health
docker compose ps
docker inspect <container_id> | grep -A 10 Health
```

---

## Troubleshooting

### Common Issues

#### 1. Port Already in Use

**Error**: `bind: address already in use`

**Solution**:
```bash
# Find process using the port
lsof -i :8000

# Kill the process
kill -9 <PID>

# Or change the port in .env
BACKEND_PORT=8001
```

#### 2. Container Keeps Restarting

**Check logs**:
```bash
docker compose logs backend
```

**Common causes**:
- Database connection failure
- Missing environment variables
- Application errors

**Solution**: Fix the underlying issue and restart:
```bash
docker compose restart backend
```

#### 3. Database Connection Errors

**Verify database is healthy**:
```bash
docker compose ps postgres
docker compose exec postgres pg_isready -U mlsp_user
```

**Check credentials**:
- Verify `.env` file has correct `POSTGRES_*` variables
- Ensure `DATABASE_URL` in backend uses correct credentials

#### 4. Airflow Initialization Fails

**Check Fernet key**:
```bash
# Generate new key
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

**Reset Airflow**:
```bash
docker compose down
docker volume rm mlsp_airflow_data
docker compose up -d
```

#### 5. Frontend Cannot Connect to Backend

**Check CORS configuration**:
- Verify `VITE_API_URL` in `.env`
- Ensure backend CORS settings allow frontend origin

#### 6. Out of Disk Space

**Clean up Docker resources**:
```bash
# Remove unused containers, networks, images
docker system prune -a

# Remove unused volumes
docker volume prune
```

### Debug Mode

Enable debug logging:

```bash
# Backend
LOG_LEVEL=DEBUG docker compose up backend

# Docker Compose verbose output
docker compose --verbose up
```

### Health Checks

```bash
# Backend health check
curl http://localhost:8000/health

# Frontend health check
curl http://localhost:3000/health

# Airflow health check
curl http://localhost:8080/health
```

---

## Performance Tuning

### Database Optimization

**Increase connection pool**:
```bash
# In .env
DB_POOL_SIZE=20
DB_MAX_OVERFLOW=40
```

**PostgreSQL configuration** (add to `docker-compose.yml`):
```yaml
postgres:
  command: >
    postgres
    -c shared_buffers=256MB
    -c effective_cache_size=1GB
    -c max_connections=200
```

### Redis Optimization

```yaml
redis:
  command: >
    redis-server
    --maxmemory 2gb
    --maxmemory-policy allkeys-lru
    --save 60 1000
```

### Resource Limits

**Set memory limits** in `docker-compose.yml`:
```yaml
backend:
  deploy:
    resources:
      limits:
        cpus: '2'
        memory: 2G
      reservations:
        cpus: '1'
        memory: 1G
```

### Scaling Workers

```bash
# Scale Airflow workers
docker compose up -d --scale airflow-worker=4

# Scale backend replicas (with load balancer)
docker compose up -d --scale backend=3
```

---

## Backup and Restore

### Database Backup

```bash
# Full backup
docker compose exec postgres pg_dump -U mlsp_user -F c mlsp > mlsp_backup.dump

# Schema only
docker compose exec postgres pg_dump -U mlsp_user --schema-only mlsp > schema.sql

# Data only
docker compose exec postgres pg_dump -U mlsp_user --data-only mlsp > data.sql
```

### Database Restore

```bash
# Restore from backup
docker compose exec -T postgres pg_restore -U mlsp_user -d mlsp -c < mlsp_backup.dump
```

### Volume Backup

```bash
# Backup all volumes
docker run --rm -v mlsp_postgres_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/postgres_backup.tar.gz /data
```

---

## Continuous Integration

### GitHub Actions Example

```yaml
name: Docker Build

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build images
        run: docker compose build

      - name: Run tests
        run: |
          docker compose up -d
          docker compose exec -T backend pytest
          docker compose exec -T frontend npm test

      - name: Cleanup
        run: docker compose down -v
```

---

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PostgreSQL Docker Hub](https://hub.docker.com/_/postgres)
- [TimescaleDB Documentation](https://docs.timescale.com/)
- [Airflow Docker Documentation](https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html)

---

## Support

For issues or questions:
1. Check this documentation
2. Review logs: `docker compose logs -f`
3. Search existing GitHub issues
4. Create a new issue with:
   - Docker version
   - Docker Compose version
   - Error messages
   - Steps to reproduce
