# ML Sport Stat Predictor

An enterprise-grade machine learning platform for predicting sports game outcomes and player performance. Supports NFL, NBA, and MLB with automated data collection via web scraping.

## Features

- **Multi-Sport Support** - NFL, NBA, and MLB predictions
- **Game Outcome Predictions** - Win/loss, point spreads, over/under
- **Player Stat Predictions** - Points, rebounds, yards, touchdowns, and more
- **Automated Data Collection** - Web scraping with real-time updates during seasons
- **Modern Dashboard** - React-based UI for exploring predictions and stats

## Tech Stack

| Layer | Technologies |
|-------|--------------|
| Frontend | React 18, TypeScript, Vite, TailwindCSS, TanStack Query |
| Backend | Python FastAPI, SQLAlchemy, Pydantic |
| Database | PostgreSQL + TimescaleDB, Redis |
| ML | scikit-learn, XGBoost, PyTorch, MLflow |
| Data Pipeline | Apache Airflow, Scrapy, Playwright |
| Infrastructure | Docker, Kubernetes, GitHub Actions |

## Project Structure

```
ml-stat-predictor/
├── frontend/          # React application
├── backend/           # FastAPI application
├── data_pipeline/     # Airflow DAGs and scrapers
├── ml/                # ML training and inference
├── k8s/               # Kubernetes manifests
└── docs/              # Documentation
```

## Documentation

Detailed design documents are available in `/docs`:

- [Project Proposal](docs/00-PROJECT-PROPOSAL.md) - Overview, scope, and technology decisions
- [System Architecture](docs/architecture/01-SYSTEM-ARCHITECTURE.md) - Infrastructure and system design
- [Data Pipeline](docs/architecture/02-DATA-PIPELINE.md) - Web scraping and ETL specifications
- [ML Models](docs/architecture/03-ML-MODELS.md) - Machine learning model specifications
- [Frontend](docs/architecture/04-FRONTEND.md) - React frontend specification
- [Backend API](docs/architecture/05-BACKEND-API.md) - FastAPI backend specification
- [Docker Setup](docs/DOCKER.md) - Complete Docker configuration guide
- [Jira Stories](docs/stories/JIRA-STORIES.md) - Implementation stories

## Getting Started

### Prerequisites

- Docker 24.0 or higher
- Docker Compose 2.20 or higher
- 16 GB RAM (recommended)
- 50 GB free disk space (recommended)

### Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ml-stat-predictor
   ```

2. **Set up environment**
   ```bash
   make setup
   ```
   This will create a `.env` file and generate necessary keys.

3. **Start all services**
   ```bash
   make up
   ```

4. **Access the applications**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8000/docs
   - Airflow: http://localhost:8080 (admin/admin)
   - MLflow: http://localhost:5000

### Common Commands

```bash
make up              # Start all services
make down            # Stop all services
make logs            # View logs
make test            # Run tests
make db-shell        # Access database
make clean           # Clean up Docker resources
```

For detailed Docker documentation, see [docs/DOCKER.md](docs/DOCKER.md).

## License

MIT
