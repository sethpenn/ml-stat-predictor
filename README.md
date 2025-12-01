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
- [Jira Stories](docs/stories/JIRA-STORIES.md) - Implementation stories

## Getting Started

*Coming soon* - Setup instructions will be added as the project develops.

## License

MIT
