.PHONY: help build up down restart logs ps test clean migrate seed

# Default target
help:
	@echo "ML Sport Stat Predictor - Docker Commands"
	@echo ""
	@echo "Setup:"
	@echo "  make setup          - Initial setup (copy .env, generate keys)"
	@echo "  make build          - Build all Docker images"
	@echo "  make build-prod     - Build production Docker images"
	@echo ""
	@echo "Development:"
	@echo "  make up             - Start all services in development mode"
	@echo "  make down           - Stop all services"
	@echo "  make restart        - Restart all services"
	@echo "  make logs           - View logs (all services)"
	@echo "  make logs-backend   - View backend logs"
	@echo "  make logs-frontend  - View frontend logs"
	@echo "  make logs-airflow   - View Airflow logs"
	@echo "  make ps             - List running containers"
	@echo ""
	@echo "Database:"
	@echo "  make db-shell       - Connect to PostgreSQL shell"
	@echo "  make migrate        - Run database migrations"
	@echo "  make migrate-create - Create new migration"
	@echo "  make seed           - Seed database with sample data"
	@echo "  make db-backup      - Backup database"
	@echo "  make db-restore     - Restore database from backup"
	@echo ""
	@echo "Testing:"
	@echo "  make test           - Run all tests"
	@echo "  make test-backend   - Run backend tests"
	@echo "  make test-frontend  - Run frontend tests"
	@echo "  make test-coverage  - Run tests with coverage"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean          - Remove containers, volumes, and images"
	@echo "  make clean-volumes  - Remove all volumes (WARNING: deletes data)"
	@echo "  make prune          - Remove unused Docker resources"
	@echo "  make reset          - Complete reset (clean + rebuild)"
	@echo ""
	@echo "Production:"
	@echo "  make prod-up        - Start services in production mode"
	@echo "  make prod-down      - Stop production services"
	@echo "  make prod-logs      - View production logs"

# Setup
setup:
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "Created .env file from .env.example"; \
		echo ""; \
		echo "Generating Airflow Fernet key..."; \
		FERNET_KEY=$$(python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"); \
		sed -i.bak "s/AIRFLOW_FERNET_KEY=/AIRFLOW_FERNET_KEY=$$FERNET_KEY/" .env && rm .env.bak; \
		echo "Fernet key added to .env"; \
		echo ""; \
		echo "Please review and update .env file with your settings!"; \
	else \
		echo ".env file already exists. Skipping..."; \
	fi

# Build
build:
	docker compose build

build-prod:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml build

# Start/Stop
up:
	docker compose up -d
	@echo "Services starting... Wait a moment for initialization."
	@echo "Access points:"
	@echo "  Frontend:  http://localhost:3000"
	@echo "  Backend:   http://localhost:8000"
	@echo "  API Docs:  http://localhost:8000/docs"
	@echo "  Airflow:   http://localhost:8080"
	@echo "  MLflow:    http://localhost:5000"

down:
	docker compose down

restart:
	docker compose restart

restart-backend:
	docker compose restart backend

restart-frontend:
	docker compose restart frontend

# Logs
logs:
	docker compose logs -f

logs-backend:
	docker compose logs -f backend

logs-frontend:
	docker compose logs -f frontend

logs-airflow:
	docker compose logs -f airflow-webserver airflow-scheduler airflow-worker

# Status
ps:
	docker compose ps

# Database
db-shell:
	docker compose exec postgres psql -U mlsp_user -d mlsp

db-backup:
	@mkdir -p backups
	docker compose exec postgres pg_dump -U mlsp_user -F c mlsp > backups/mlsp_$$(date +%Y%m%d_%H%M%S).dump
	@echo "Database backed up to backups/"

db-restore:
	@echo "WARNING: This will overwrite the current database!"
	@read -p "Enter backup file path: " backup_file; \
	docker compose exec -T postgres pg_restore -U mlsp_user -d mlsp -c < $$backup_file

migrate:
	docker compose exec backend alembic upgrade head

migrate-create:
	@read -p "Enter migration message: " msg; \
	docker compose exec backend alembic revision --autogenerate -m "$$msg"

seed:
	docker compose exec backend python -m app.db.seed

# Shell access
shell-backend:
	docker compose exec backend bash

shell-frontend:
	docker compose exec frontend sh

shell-airflow:
	docker compose exec airflow-scheduler bash

# Testing
test:
	@echo "Running backend tests..."
	docker compose exec backend pytest
	@echo "Running frontend tests..."
	docker compose exec frontend npm test -- --run

test-backend:
	docker compose exec backend pytest

test-frontend:
	docker compose exec frontend npm test

test-coverage:
	docker compose exec backend pytest --cov=app --cov-report=html --cov-report=term
	@echo "Coverage report generated in backend/htmlcov/"

# Linting
lint:
	docker compose exec backend ruff check .
	docker compose exec backend black --check .
	docker compose exec frontend npm run lint

format:
	docker compose exec backend black .
	docker compose exec backend ruff --fix .
	docker compose exec frontend npm run format

# Clean
clean:
	docker compose down --rmi all --volumes --remove-orphans

clean-volumes:
	@echo "WARNING: This will delete all data!"
	@read -p "Are you sure? [y/N] " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		docker compose down -v; \
	fi

prune:
	docker system prune -af
	docker volume prune -f

reset: clean build up
	@echo "System reset complete!"

# Production
prod-up:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
	@echo "Production services started"

prod-down:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml down

prod-logs:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml logs -f

# Health checks
health:
	@echo "Checking service health..."
	@curl -f http://localhost:8000/health && echo "✓ Backend healthy" || echo "✗ Backend unhealthy"
	@curl -f http://localhost:3000/health && echo "✓ Frontend healthy" || echo "✗ Frontend unhealthy"
	@curl -f http://localhost:8080/health && echo "✓ Airflow healthy" || echo "✗ Airflow unhealthy"

# Stats
stats:
	docker stats
