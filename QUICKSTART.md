# Quick Start Guide

Get the ML Sport Stat Predictor running in 5 minutes.

## TL;DR

```bash
make setup
make up
```

Then visit http://localhost:3000

## Step-by-Step

### 1. Prerequisites

Ensure you have Docker and Docker Compose installed:

```bash
docker --version  # Should be 24.0+
docker compose version  # Should be 2.20+
```

### 2. Initial Setup

```bash
# Clone the repository (if you haven't already)
git clone <repository-url>
cd ml-stat-predictor

# Create environment file and generate keys
make setup

# (Optional) Edit .env to customize settings
nano .env
```

### 3. Start Services

```bash
# Build and start all services
make up

# Or with explicit build
make build && make up
```

Wait 30-60 seconds for all services to initialize.

### 4. Verify Everything is Running

```bash
# Check service status
make ps

# View logs
make logs
```

### 5. Access Applications

| Service | URL | Credentials |
|---------|-----|-------------|
| **Frontend** | http://localhost:3000 | - |
| **Backend API Docs** | http://localhost:8000/docs | - |
| **Airflow** | http://localhost:8080 | admin / admin |
| **MLflow** | http://localhost:5000 | - |

## Development Workflow

### Making Code Changes

All code changes are automatically reflected:

- **Backend**: Auto-reloads on file changes
- **Frontend**: Hot module replacement (HMR)
- **Airflow DAGs**: Scanned every 30 seconds

### Running Tests

```bash
# All tests
make test

# Backend only
make test-backend

# Frontend only
make test-frontend
```

### Database Operations

```bash
# Access database shell
make db-shell

# Run migrations
make migrate

# Create new migration
make migrate-create

# Seed test data
make seed
```

### Viewing Logs

```bash
# All services
make logs

# Specific service
make logs-backend
make logs-frontend
make logs-airflow
```

### Restarting Services

```bash
# Restart all
make restart

# Restart specific service
make restart-backend
make restart-frontend
```

## Common Issues

### Port Already in Use

Change ports in `.env`:
```bash
BACKEND_PORT=8001
FRONTEND_PORT=3001
```

Then restart:
```bash
make restart
```

### Services Won't Start

Check logs for errors:
```bash
make logs
```

Common fixes:
```bash
# Rebuild images
make down
make build
make up

# Complete reset (WARNING: deletes data)
make reset
```

### Database Connection Errors

Ensure PostgreSQL is healthy:
```bash
make ps  # Check if postgres is running
make db-shell  # Try to connect
```

## Stopping Services

```bash
# Stop services (preserves data)
make down

# Stop and remove volumes (deletes data)
make clean-volumes
```

## Next Steps

- Read the full [Docker Setup Guide](docs/DOCKER.md)
- Review [System Architecture](docs/architecture/01-SYSTEM-ARCHITECTURE.md)
- Check [Jira Stories](docs/stories/JIRA-STORIES.md) for implementation tasks

## Help

Run `make help` to see all available commands.

For detailed documentation, see [docs/DOCKER.md](docs/DOCKER.md).
