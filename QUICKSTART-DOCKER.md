# Quick Start - Running with Docker Desktop on Mac

## Prerequisites

✅ Docker Desktop installed and running
✅ At least 8 GB RAM allocated to Docker
✅ At least 4 CPU cores allocated to Docker

Check Docker is running:
```bash
docker --version
docker-compose --version
```

## 🚀 Quick Start (3 Commands)

### 1. Copy Environment File
```bash
cp .env.example .env
```

### 2. Start All Services
```bash
docker-compose up -d
```

This will download images (first time ~5-10 min) and start all services.

### 3. Check Status
```bash
docker-compose ps
```

All services should show "Up" or "Up (healthy)".

## 🌐 Access Your Services

Open in your browser:

- **Frontend**: http://localhost:3000
- **Backend API Docs**: http://localhost:8000/docs
- **Airflow**: http://localhost:8080 (admin/admin)
- **MLflow**: http://localhost:5000

## 📊 Monitor Progress

Watch the logs:
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend

# Press Ctrl+C to stop watching (services keep running)
```

## ⏸️ Stop Services

```bash
# Stop all services (data preserved)
docker-compose stop

# Start again
docker-compose up -d

# Stop and remove containers (data still preserved in volumes)
docker-compose down
```

## 🔧 Using the Makefile

The project includes helpful shortcuts:

```bash
make up          # Start all services
make down        # Stop all services
make logs        # View logs
make status      # Check service status
make restart     # Restart services
make backup      # Backup database
make clean       # Clean up Docker resources
make help        # Show all commands
```

## 🆘 Troubleshooting

### Services won't start?
```bash
docker-compose logs [service-name]
```

### Port already in use?
```bash
# Find what's using the port
lsof -i :5432

# Or change ports in .env file
```

### Need to start fresh?
```bash
docker-compose down -v  # Deletes data!
docker-compose up -d
```

## 📖 Full Documentation

For detailed information, see:
- [Complete Docker Setup Guide](docs/DOCKER-SETUP-GUIDE.md)
- [PostgreSQL Operations](docs/operations/POSTGRESQL-SETUP.md)
- [Backup Strategy](docs/operations/DATABASE-BACKUP-STRATEGY.md)

## ✅ Verify Everything Works

```bash
# Check all services are running
docker-compose ps

# Test backend API
curl http://localhost:8000/health

# Should return: {"status":"healthy"}
```

## 🎯 What's Running?

Your Docker setup includes:

| Service | Description | Port |
|---------|-------------|------|
| postgres | PostgreSQL 15 + TimescaleDB | 5432 |
| pgbouncer | Connection pooler | 6432 |
| redis | Cache & message broker | 6379 |
| backend | FastAPI application | 8000 |
| frontend | React application | 3000 |
| airflow-* | Data pipeline orchestration | 8080 |
| mlflow | ML experiment tracking | 5000 |

All services automatically restart if they crash and persist data across restarts!
