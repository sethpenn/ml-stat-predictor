# Docker Setup Guide for Mac

This guide will help you run the ML Sport Stat Predictor platform using Docker Desktop on macOS.

## Prerequisites

### 1. Verify Docker Installation

Open Terminal and run:

```bash
docker --version
docker-compose --version
```

You should see output like:
```
Docker version 24.x.x
Docker Compose version v2.x.x
```

### 2. Ensure Docker Desktop is Running

- Open Docker Desktop application
- Wait for the Docker icon in the menu bar to show "Docker Desktop is running"
- You should see a green indicator

### 3. Configure Docker Resources (Recommended)

This project runs multiple services, so allocate sufficient resources:

1. Open **Docker Desktop**
2. Go to **Settings** (⚙️ icon)
3. Click **Resources**
4. Adjust settings:
   - **CPUs**: 4+ cores recommended
   - **Memory**: 8 GB minimum, 16 GB recommended
   - **Swap**: 2 GB
   - **Disk**: 60 GB recommended

5. Click **Apply & Restart**

## Quick Start (5 Minutes)

### Step 1: Navigate to Project Directory

```bash
cd /Users/penne/Code/ml-stat-predictor
```

### Step 2: Create Environment File

```bash
# Copy the example environment file
cp .env.example .env

# (Optional) Edit .env to customize settings
nano .env
```

**Important:** The default passwords in `.env.example` are for development only. For production, change all passwords!

### Step 3: Start All Services

```bash
# Start all services in detached mode (background)
docker-compose up -d
```

This will:
- Download all required Docker images (~5-10 minutes first time)
- Create Docker volumes for data persistence
- Start all services (PostgreSQL, PgBouncer, Redis, Backend, Frontend, Airflow, MLflow)

### Step 4: Monitor Startup Progress

```bash
# Watch logs from all services
docker-compose logs -f

# Or watch specific services
docker-compose logs -f postgres pgbouncer backend

# Press Ctrl+C to stop watching logs (services keep running)
```

### Step 5: Verify Services are Running

```bash
# Check status of all services
docker-compose ps
```

You should see all services with status "Up" or "Up (healthy)":

```
NAME                        STATUS
mlsp-airflow-init           Exited (0)
mlsp-airflow-scheduler      Up
mlsp-airflow-webserver      Up (healthy)
mlsp-airflow-worker         Up
mlsp-backend                Up
mlsp-frontend               Up
mlsp-mlflow                 Up
mlsp-pgbouncer              Up (healthy)
mlsp-postgres               Up (healthy)
mlsp-redis                  Up (healthy)
```

**Note:** `airflow-init` will show "Exited (0)" - this is normal. It only runs once to initialize Airflow.

## Accessing the Services

Once all services are running, you can access:

| Service | URL | Credentials |
|---------|-----|-------------|
| **Frontend** | http://localhost:3000 | N/A |
| **Backend API** | http://localhost:8000 | N/A |
| **API Docs** | http://localhost:8000/docs | N/A |
| **Airflow UI** | http://localhost:8080 | admin / admin |
| **MLflow UI** | http://localhost:5000 | N/A |
| **PostgreSQL** | localhost:5432 | mlsp_user / mlsp_password |
| **PgBouncer** | localhost:6432 | mlsp_user / mlsp_password |
| **Redis** | localhost:6379 | Password: redis_password |

### Test Backend API

```bash
curl http://localhost:8000/health
```

Should return: `{"status":"healthy"}`

## Step-by-Step Service Startup

If you prefer to start services individually (useful for debugging):

### 1. Start Core Infrastructure

```bash
# Start PostgreSQL and wait for it to be healthy
docker-compose up -d postgres

# Check PostgreSQL logs
docker-compose logs -f postgres

# Wait for: "database system is ready to accept connections"
```

### 2. Start PgBouncer (Connection Pooler)

```bash
docker-compose up -d pgbouncer

# Verify PgBouncer is healthy
docker-compose ps pgbouncer
```

### 3. Start Redis (Cache)

```bash
docker-compose up -d redis

# Verify Redis is healthy
docker-compose ps redis
```

### 4. Start Backend API

```bash
docker-compose up -d backend

# Watch backend logs
docker-compose logs -f backend

# Wait for: "Application startup complete"
```

### 5. Start Frontend

```bash
docker-compose up -d frontend

# Watch frontend logs
docker-compose logs -f frontend
```

### 6. Start Airflow Services

```bash
# Initialize Airflow database (runs once)
docker-compose up -d airflow-init

# Wait for initialization to complete
docker-compose logs -f airflow-init

# Start Airflow services
docker-compose up -d airflow-webserver airflow-scheduler airflow-worker

# Check Airflow logs
docker-compose logs -f airflow-webserver
```

### 7. Start MLflow

```bash
docker-compose up -d mlflow

# Check MLflow logs
docker-compose logs -f mlflow
```

## Common Docker Commands

### Managing Services

```bash
# Start all services
docker-compose up -d

# Start specific services
docker-compose up -d postgres pgbouncer backend

# Stop all services
docker-compose stop

# Stop specific services
docker-compose stop backend frontend

# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart backend

# Remove all stopped containers
docker-compose down

# Remove containers AND volumes (WARNING: deletes data!)
docker-compose down -v
```

### Viewing Logs

```bash
# View logs from all services
docker-compose logs

# Follow logs (real-time)
docker-compose logs -f

# View logs from specific service
docker-compose logs backend

# View last 100 lines
docker-compose logs --tail=100 backend

# View logs from multiple services
docker-compose logs postgres pgbouncer backend
```

### Checking Service Status

```bash
# List all services and their status
docker-compose ps

# Show resource usage
docker stats

# Show detailed info about a service
docker inspect mlsp-postgres
```

### Executing Commands in Containers

```bash
# Access PostgreSQL shell
docker exec -it mlsp-postgres psql -U mlsp_user -d mlsp

# Access PgBouncer console
docker exec -it mlsp-pgbouncer psql -h localhost -p 6432 -U mlsp_user pgbouncer

# Access Redis CLI
docker exec -it mlsp-redis redis-cli -a redis_password

# Access backend container shell
docker exec -it mlsp-backend /bin/bash

# Run backend commands (e.g., database migrations)
docker exec mlsp-backend alembic upgrade head
```

## Development Workflow

### Hot Reloading

The development setup includes hot reloading:

- **Backend**: Edit files in `./backend/` - FastAPI auto-reloads
- **Frontend**: Edit files in `./frontend/` - Vite auto-reloads
- **Airflow DAGs**: Edit files in `./data_pipeline/dags/` - Airflow auto-reloads

Changes appear automatically without restarting containers!

### Rebuilding Services

If you change Dockerfiles or add new dependencies:

```bash
# Rebuild all services
docker-compose build

# Rebuild specific service
docker-compose build backend

# Rebuild and restart
docker-compose up -d --build backend

# Force rebuild (no cache)
docker-compose build --no-cache backend
```

### Database Operations

```bash
# Create a backup
./scripts/backup-db.sh

# Restore from backup
./scripts/restore-db.sh ./backups/postgres/full_backup_TIMESTAMP.sql.gz

# Access PostgreSQL directly
docker exec -it mlsp-postgres psql -U mlsp_user -d mlsp

# Run SQL file
docker exec -i mlsp-postgres psql -U mlsp_user -d mlsp < your-script.sql

# Check database size
docker exec mlsp-postgres psql -U mlsp_user -d mlsp -c "SELECT pg_size_pretty(pg_database_size('mlsp'));"
```

## Troubleshooting

### Services Won't Start

**Issue**: Container fails to start

**Solution**:
```bash
# Check logs for errors
docker-compose logs [service-name]

# Remove and recreate containers
docker-compose down
docker-compose up -d

# If still failing, rebuild
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Port Already in Use

**Issue**: Error like "port 5432 is already allocated"

**Solution**:
```bash
# Find what's using the port (example: port 5432)
lsof -i :5432

# Kill the process or stop the service
# Then restart Docker Compose

# Or change the port in .env file
# Example: POSTGRES_PORT=5433
```

### Out of Memory / Disk Space

**Issue**: Services crash or won't start

**Solution**:
```bash
# Check Docker disk usage
docker system df

# Clean up unused resources
docker system prune

# Clean up everything (WARNING: deletes all stopped containers, unused networks, images)
docker system prune -a

# Increase memory in Docker Desktop Settings > Resources
```

### Database Connection Issues

**Issue**: Backend can't connect to database

**Solution**:
```bash
# Check if PostgreSQL is healthy
docker-compose ps postgres

# Check PgBouncer is healthy
docker-compose ps pgbouncer

# Test connection
docker exec mlsp-postgres pg_isready -U mlsp_user -d mlsp

# Check backend logs for connection errors
docker-compose logs backend

# Restart database services
docker-compose restart postgres pgbouncer backend
```

### Airflow Services Failing

**Issue**: Airflow services won't start

**Solution**:
```bash
# Reinitialize Airflow database
docker-compose stop airflow-webserver airflow-scheduler airflow-worker
docker-compose rm -f airflow-init
docker-compose up -d airflow-init

# Wait for initialization to complete
docker-compose logs -f airflow-init

# Restart Airflow services
docker-compose up -d airflow-webserver airflow-scheduler airflow-worker
```

### Reset Everything (Nuclear Option)

**WARNING**: This deletes all data!

```bash
# Stop and remove all containers, networks, volumes
docker-compose down -v

# Remove all project images
docker-compose down --rmi all

# Clean up Docker system
docker system prune -a --volumes

# Start fresh
docker-compose up -d
```

## Performance Tips

### Speed Up Builds

```bash
# Use BuildKit for faster builds
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Add to ~/.zshrc or ~/.bash_profile to make permanent
echo 'export DOCKER_BUILDKIT=1' >> ~/.zshrc
echo 'export COMPOSE_DOCKER_CLI_BUILD=1' >> ~/.zshrc
```

### Reduce Resource Usage

If running low on resources, start only essential services:

```bash
# Minimal setup (backend development)
docker-compose up -d postgres pgbouncer redis backend

# Add frontend
docker-compose up -d frontend

# Add Airflow when needed
docker-compose up -d airflow-init airflow-webserver airflow-scheduler airflow-worker

# Add MLflow when needed
docker-compose up -d mlflow
```

## Useful Shortcuts

Add these to your `~/.zshrc` or `~/.bash_profile`:

```bash
# Docker Compose shortcuts
alias dc='docker-compose'
alias dcu='docker-compose up -d'
alias dcd='docker-compose down'
alias dcl='docker-compose logs -f'
alias dcp='docker-compose ps'
alias dcr='docker-compose restart'

# Project-specific
alias mlsp-start='cd /Users/penne/Code/ml-stat-predictor && docker-compose up -d'
alias mlsp-stop='cd /Users/penne/Code/ml-stat-predictor && docker-compose stop'
alias mlsp-logs='cd /Users/penne/Code/ml-stat-predictor && docker-compose logs -f'
alias mlsp-status='cd /Users/penne/Code/ml-stat-predictor && docker-compose ps'
```

Reload your shell:
```bash
source ~/.zshrc  # or source ~/.bash_profile
```

Now you can use:
```bash
mlsp-start    # Start all services
mlsp-logs     # View logs
mlsp-status   # Check status
mlsp-stop     # Stop all services
```

## Makefile Commands

The project includes a Makefile for common tasks:

```bash
# View all available commands
make help

# Start all services
make up

# Stop all services
make down

# View logs
make logs

# Restart services
make restart

# Run tests
make test

# Create database backup
make backup

# Clean up
make clean
```

## Next Steps

1. ✅ Verify all services are running: `docker-compose ps`
2. ✅ Access the frontend: http://localhost:3000
3. ✅ Check API docs: http://localhost:8000/docs
4. ✅ Create your first backup: `./scripts/backup-db.sh`
5. 📖 Review [POSTGRESQL-SETUP.md](./operations/POSTGRESQL-SETUP.md) for database operations
6. 📖 Review [DATABASE-BACKUP-STRATEGY.md](./operations/DATABASE-BACKUP-STRATEGY.md) for backup procedures

## Getting Help

If you encounter issues:

1. Check the logs: `docker-compose logs -f [service-name]`
2. Verify Docker Desktop is running with sufficient resources
3. Check for port conflicts: `lsof -i :[port]`
4. Review the troubleshooting section above
5. Check project documentation in `/docs`

## Resources

- [Docker Desktop for Mac Documentation](https://docs.docker.com/desktop/mac/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Project README](../README.md)
- [PostgreSQL Setup Guide](./operations/POSTGRESQL-SETUP.md)
