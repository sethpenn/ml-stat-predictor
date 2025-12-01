# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Enterprise-level machine learning platform for predicting sports game outcomes and player performance. Supports NFL, NBA, and MLB with automated data collection via web scraping.

## Documentation

All design documents are in `/docs`:
- `00-PROJECT-PROPOSAL.md` - Project overview, scope, and technology stack
- `architecture/01-SYSTEM-ARCHITECTURE.md` - System design and infrastructure
- `architecture/02-DATA-PIPELINE.md` - Web scraping and ETL pipeline
- `architecture/03-ML-MODELS.md` - Machine learning model specifications
- `architecture/04-FRONTEND.md` - React frontend specification
- `architecture/05-BACKEND-API.md` - FastAPI backend specification
- `stories/JIRA-STORIES.md` - All Jira stories for implementation

## Technology Stack

- **Frontend:** React 18, TypeScript, Vite, TailwindCSS, TanStack Query
- **Backend:** Python FastAPI, SQLAlchemy, Pydantic
- **Database:** PostgreSQL with TimescaleDB, Redis
- **ML:** scikit-learn, XGBoost, PyTorch, MLflow
- **Data Pipeline:** Apache Airflow, Scrapy, Playwright
- **Infrastructure:** Docker, Kubernetes

## Project Structure (Planned)

```
ml-stat-predictor/
├── frontend/          # React application
├── backend/           # FastAPI application
├── data_pipeline/     # Airflow DAGs and scrapers
├── ml/                # ML training and inference
├── k8s/               # Kubernetes manifests
└── docs/              # Documentation
```
