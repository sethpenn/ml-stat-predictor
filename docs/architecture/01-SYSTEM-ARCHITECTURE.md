# System Architecture Document

## Overview

This document describes the technical architecture for the ML Sport Stat Predictor platform, an enterprise-grade system for predicting sports outcomes using machine learning.

## System Components

### 1. Frontend Application

**Technology:** React 18 + TypeScript + Vite + TailwindCSS

```
frontend/
├── src/
│   ├── components/          # Reusable UI components
│   │   ├── common/          # Buttons, inputs, cards, etc.
│   │   ├── charts/          # D3/Recharts visualizations
│   │   └── layouts/         # Page layouts, navigation
│   ├── features/            # Feature-based modules
│   │   ├── dashboard/       # Main dashboard
│   │   ├── games/           # Game listings and details
│   │   ├── players/         # Player stats and predictions
│   │   ├── teams/           # Team information
│   │   └── predictions/     # Prediction displays
│   ├── hooks/               # Custom React hooks
│   ├── services/            # API client services
│   ├── stores/              # Zustand state stores
│   ├── types/               # TypeScript type definitions
│   └── utils/               # Utility functions
├── public/
└── tests/
```

**Key Dependencies:**
- `@tanstack/react-query` - Server state management
- `zustand` - Client state management
- `recharts` - Data visualization
- `react-router-dom` - Routing
- `axios` - HTTP client
- `date-fns` - Date manipulation

### 2. Backend API

**Technology:** Python FastAPI + SQLAlchemy + Pydantic

```
backend/
├── app/
│   ├── api/
│   │   ├── v1/
│   │   │   ├── endpoints/
│   │   │   │   ├── games.py
│   │   │   │   ├── players.py
│   │   │   │   ├── teams.py
│   │   │   │   ├── predictions.py
│   │   │   │   └── auth.py
│   │   │   └── router.py
│   │   └── deps.py          # Dependency injection
│   ├── core/
│   │   ├── config.py        # Settings management
│   │   ├── security.py      # Auth utilities
│   │   └── logging.py       # Logging configuration
│   ├── models/              # SQLAlchemy models
│   │   ├── game.py
│   │   ├── player.py
│   │   ├── team.py
│   │   └── prediction.py
│   ├── schemas/             # Pydantic schemas
│   ├── services/            # Business logic
│   │   ├── stats_service.py
│   │   └── prediction_service.py
│   ├── ml/                  # ML inference
│   │   ├── model_loader.py
│   │   └── predictor.py
│   └── db/
│       ├── session.py
│       └── migrations/
├── tests/
└── alembic/
```

**API Design Principles:**
- RESTful endpoints with consistent naming
- Pagination for list endpoints
- Filtering and sorting support
- Comprehensive error handling
- OpenAPI documentation auto-generated

### 3. Database Layer

**Primary Database:** PostgreSQL 15 with TimescaleDB extension

```sql
-- Core Schema Overview

-- Sports/Leagues
CREATE TABLE sports (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    code VARCHAR(10) UNIQUE NOT NULL  -- NFL, NBA, MLB
);

CREATE TABLE seasons (
    id SERIAL PRIMARY KEY,
    sport_id INTEGER REFERENCES sports(id),
    year INTEGER NOT NULL,
    start_date DATE,
    end_date DATE
);

-- Teams
CREATE TABLE teams (
    id SERIAL PRIMARY KEY,
    sport_id INTEGER REFERENCES sports(id),
    name VARCHAR(100) NOT NULL,
    city VARCHAR(100),
    abbreviation VARCHAR(10),
    conference VARCHAR(50),
    division VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Players
CREATE TABLE players (
    id SERIAL PRIMARY KEY,
    external_id VARCHAR(50),  -- Reference ID from source
    sport_id INTEGER REFERENCES sports(id),
    team_id INTEGER REFERENCES teams(id),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    position VARCHAR(20),
    jersey_number INTEGER,
    height_inches INTEGER,
    weight_lbs INTEGER,
    birth_date DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Games
CREATE TABLE games (
    id SERIAL PRIMARY KEY,
    sport_id INTEGER REFERENCES sports(id),
    season_id INTEGER REFERENCES seasons(id),
    external_id VARCHAR(50),
    home_team_id INTEGER REFERENCES teams(id),
    away_team_id INTEGER REFERENCES teams(id),
    game_date TIMESTAMP NOT NULL,
    venue VARCHAR(200),
    home_score INTEGER,
    away_score INTEGER,
    status VARCHAR(20) DEFAULT 'scheduled',  -- scheduled, in_progress, final
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Player Game Stats (TimescaleDB hypertable)
CREATE TABLE player_game_stats (
    id SERIAL,
    player_id INTEGER REFERENCES players(id),
    game_id INTEGER REFERENCES games(id),
    stat_date TIMESTAMP NOT NULL,
    minutes_played INTEGER,
    stats JSONB NOT NULL,  -- Flexible stats storage per sport
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (id, stat_date)
);

SELECT create_hypertable('player_game_stats', 'stat_date');

-- Team Game Stats
CREATE TABLE team_game_stats (
    id SERIAL,
    team_id INTEGER REFERENCES teams(id),
    game_id INTEGER REFERENCES games(id),
    stat_date TIMESTAMP NOT NULL,
    is_home BOOLEAN,
    stats JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (id, stat_date)
);

SELECT create_hypertable('team_game_stats', 'stat_date');

-- Predictions
CREATE TABLE predictions (
    id SERIAL PRIMARY KEY,
    game_id INTEGER REFERENCES games(id),
    model_version VARCHAR(50),
    prediction_type VARCHAR(50),  -- game_outcome, point_spread, player_stat
    predicted_value JSONB NOT NULL,
    confidence FLOAT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_games_date ON games(game_date);
CREATE INDEX idx_games_teams ON games(home_team_id, away_team_id);
CREATE INDEX idx_player_stats_player ON player_game_stats(player_id);
CREATE INDEX idx_predictions_game ON predictions(game_id);
```

### 4. Caching Layer

**Technology:** Redis 7

**Use Cases:**
- API response caching (TTL: 5-60 minutes)
- Session management
- Rate limiting
- Real-time prediction caching
- Pub/sub for live updates

```python
# Cache key patterns
CACHE_KEYS = {
    "game_list": "games:list:{sport}:{date}",
    "game_detail": "games:detail:{game_id}",
    "player_stats": "players:{player_id}:stats:{season}",
    "prediction": "predictions:{game_id}:{model_version}",
    "team_standings": "teams:standings:{sport}:{season}",
}
```

### 5. ML Infrastructure

**Model Training Pipeline:**
```
ml/
├── training/
│   ├── data_preparation.py
│   ├── feature_engineering.py
│   ├── models/
│   │   ├── game_outcome.py      # XGBoost classifier
│   │   ├── point_spread.py      # Gradient boosting regressor
│   │   └── player_stats.py      # Neural network
│   ├── evaluation.py
│   └── hyperparameter_tuning.py
├── inference/
│   ├── model_loader.py
│   └── batch_predictor.py
├── experiments/                  # MLflow experiments
└── artifacts/                    # Trained model storage
```

**Model Registry:** MLflow for model versioning, experiment tracking, and deployment

### 6. Data Ingestion Pipeline

**Technology:** Apache Airflow + Scrapy + Playwright

```
data_pipeline/
├── dags/
│   ├── daily_stats_ingestion.py
│   ├── historical_backfill.py
│   ├── model_retraining.py
│   └── data_quality_checks.py
├── scrapers/
│   ├── spiders/
│   │   ├── espn_spider.py
│   │   ├── basketball_ref_spider.py
│   │   ├── football_ref_spider.py
│   │   └── baseball_ref_spider.py
│   ├── playwright_scrapers/
│   │   └── dynamic_content.py
│   └── pipelines/
│       ├── cleaning.py
│       ├── validation.py
│       └── storage.py
├── transformers/
│   ├── normalize_stats.py
│   └── calculate_aggregates.py
└── quality/
    ├── schema_validation.py
    └── anomaly_detection.py
```

## Infrastructure Architecture

### Container Architecture

```yaml
# docker-compose.yml structure
services:
  frontend:
    build: ./frontend
    ports: ["3000:3000"]

  backend:
    build: ./backend
    ports: ["8000:8000"]
    depends_on: [postgres, redis]

  postgres:
    image: timescale/timescaledb:latest-pg15
    volumes: [postgres_data:/var/lib/postgresql/data]

  redis:
    image: redis:7-alpine

  airflow-webserver:
    build: ./data_pipeline
    depends_on: [postgres]

  airflow-scheduler:
    build: ./data_pipeline

  airflow-worker:
    build: ./data_pipeline

  mlflow:
    image: mlflow/mlflow
    ports: ["5000:5000"]
```

### Kubernetes Deployment

```
k8s/
├── base/
│   ├── namespace.yaml
│   ├── configmap.yaml
│   └── secrets.yaml
├── frontend/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
├── backend/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── hpa.yaml              # Horizontal Pod Autoscaler
├── database/
│   ├── postgres-statefulset.yaml
│   └── redis-deployment.yaml
└── monitoring/
    ├── prometheus/
    └── grafana/
```

## Security Architecture

### Authentication & Authorization

- **JWT-based authentication** for API access
- **OAuth 2.0** integration for social login (optional)
- **Role-based access control (RBAC)** for admin features
- **API key authentication** for service-to-service communication

### Security Measures

1. **Network Security**
   - TLS/HTTPS everywhere
   - VPC isolation for database
   - WAF for public endpoints

2. **Application Security**
   - Input validation (Pydantic schemas)
   - SQL injection prevention (SQLAlchemy ORM)
   - XSS prevention (React escaping + CSP headers)
   - Rate limiting per endpoint

3. **Data Security**
   - Encryption at rest (database)
   - Encryption in transit (TLS)
   - PII handling compliance

## Monitoring & Observability

### Metrics (Prometheus + Grafana)

- API latency percentiles
- Request throughput
- Error rates
- Database connection pool
- Cache hit rates
- ML model prediction latency
- Scraper success rates

### Logging (ELK Stack)

- Structured JSON logging
- Request tracing with correlation IDs
- Centralized log aggregation

### Alerting

- PagerDuty/Slack integration
- Anomaly detection on key metrics
- Scraper failure notifications
- Model accuracy degradation alerts

## Scalability Considerations

### Horizontal Scaling

- Stateless API servers (scale via HPA)
- Read replicas for database
- Redis cluster for caching
- Airflow worker scaling

### Performance Optimization

- Database query optimization with indexes
- Materialized views for complex aggregations
- Async API endpoints for heavy operations
- CDN for static frontend assets
- Prediction result caching

## Disaster Recovery

- **RTO:** 4 hours
- **RPO:** 1 hour
- Daily database backups to S3
- Multi-AZ deployment for production
- Runbook documentation for incident response
