# CI/CD Pipeline Documentation

This document describes the Continuous Integration and Continuous Deployment (CI/CD) pipeline for the ML Sport Stat Predictor project.

## Overview

The CI/CD pipeline is implemented using GitHub Actions and consists of three main workflows:

1. **PR Validation** (`pr.yml`) - Automated checks on pull requests
2. **Main Branch CI/CD** (`main.yml`) - Integration tests and deployment to staging
3. **Production Deployment** (`deploy-production.yml`) - Manual deployment to production

## Workflows

### 1. PR Validation Workflow

**Trigger:** Pull request opened, synchronized, or reopened against `main` or `develop` branches

**Jobs:**

- **Backend Lint & Format**
  - Black format checking
  - Ruff linting
  - MyPy type checking

- **Backend Unit Tests**
  - Runs pytest with coverage
  - Uses PostgreSQL and Redis test services
  - Uploads coverage to Codecov

- **Frontend Lint & Format**
  - ESLint checking
  - Prettier format checking
  - TypeScript type checking

- **Frontend Unit Tests**
  - Runs test suite with coverage
  - Uploads coverage to Codecov

- **Data Pipeline Lint**
  - Black format checking
  - Ruff linting

**Status Check:** All jobs must pass for PR to be mergeable

### 2. Main Branch CI/CD Workflow

**Trigger:** Push to `main` branch (typically via PR merge)

**Jobs:**

1. **Integration Tests**
   - Starts all services using Docker Compose
   - Runs health checks
   - Executes integration tests
   - Runs E2E tests (placeholder)

2. **Build & Push Docker Images**
   - Builds production Docker images for:
     - Backend (FastAPI)
     - Frontend (React)
     - Data Pipeline (Airflow)
   - Pushes images to GitHub Container Registry (ghcr.io)
   - Tags images with:
     - Branch name
     - Git SHA
     - `latest` tag

3. **Deploy to Staging**
   - Updates Kubernetes deployments in staging namespace
   - Waits for rollout completion
   - Runs smoke tests

4. **Notifications**
   - Success/failure notifications (configurable)

### 3. Production Deployment Workflow

**Trigger:** Manual workflow dispatch only

**Inputs:**
- `version`: Version/tag to deploy (e.g., `main-abc1234` or `latest`)
- `confirm`: Must type "DEPLOY" to proceed

**Jobs:**

1. **Validate Input**
   - Confirms deployment request
   - Displays deployment details

2. **Pre-deployment Checks**
   - Verifies Docker images exist
   - Runs security scans (placeholder)

3. **Deploy to Production**
   - Creates backup of current deployment
   - Updates Kubernetes deployments
   - Waits for rollout completion
   - Verifies pod status
   - Uploads backup artifacts (30-day retention)

4. **Smoke Tests**
   - Health checks
   - API endpoint verification
   - Critical feature tests

5. **Rollback (if needed)**
   - Automatically triggered on deployment failure
   - Restores from backup
   - Requires manual approval

6. **Notifications**
   - Deployment status notification

## GitHub Secrets Required

### General Secrets

- `GITHUB_TOKEN` - Automatically provided by GitHub
- `CODECOV_TOKEN` - (Optional) For uploading code coverage

### Staging Environment

- `KUBE_CONFIG_STAGING` - Base64-encoded kubeconfig for staging cluster
- `STAGING_URL` - Staging environment URL (e.g., `https://staging.mlsp.example.com`)

### Production Environment

- `KUBE_CONFIG_PRODUCTION` - Base64-encoded kubeconfig for production cluster
- `PRODUCTION_URL` - Production environment URL (e.g., `https://mlsp.example.com`)

### Optional Notification Secrets

- `SLACK_WEBHOOK_URL` - Slack webhook for notifications
- `DISCORD_WEBHOOK_URL` - Discord webhook for notifications

## Setting Up Secrets

### Kubernetes Configuration

1. **Encode your kubeconfig file:**
   ```bash
   cat ~/.kube/config | base64
   ```

2. **Add to GitHub Secrets:**
   - Go to Repository Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `KUBE_CONFIG_STAGING` or `KUBE_CONFIG_PRODUCTION`
   - Value: Paste the base64-encoded kubeconfig

### Environment URLs

Add the following secrets with your actual URLs:
- `STAGING_URL`: `https://staging.mlsp.example.com`
- `PRODUCTION_URL`: `https://mlsp.example.com`

## GitHub Environments

The workflows use GitHub Environments for deployment protection:

### Staging Environment

- **Name:** `staging`
- **Protection rules:**
  - No required reviewers (auto-deploys on main branch push)
  - Optional: Wait timer (e.g., 1 minute)

### Production Environment

- **Name:** `production`
- **Protection rules:**
  - Required reviewers: 1-2 senior developers
  - Optional: Wait timer (e.g., 5 minutes)

### Production Rollback Environment

- **Name:** `production-rollback`
- **Protection rules:**
  - Required reviewers: 1 senior developer
  - Used for manual rollback approval

### Setting Up Environments

1. Go to Repository Settings → Environments
2. Click "New environment"
3. Enter environment name (e.g., `staging`, `production`)
4. Configure protection rules:
   - Add required reviewers
   - Set wait timer if needed
   - Add environment secrets (same as above)

## Container Registry

Docker images are stored in GitHub Container Registry (ghcr.io).

### Image Naming Convention

```
ghcr.io/<username>/<repository>/<service>:<tag>
```

Example:
```
ghcr.io/sethpenn/ml-stat-predictor/backend:main-abc1234
ghcr.io/sethpenn/ml-stat-predictor/frontend:latest
```

### Pulling Images

Images are public by default. To pull:

```bash
docker pull ghcr.io/sethpenn/ml-stat-predictor/backend:latest
```

For private images, authenticate first:

```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
```

## Deployment Process

### Deploying to Staging

Staging deployment is automatic:

1. Create a pull request
2. Ensure all PR checks pass
3. Merge PR to `main`
4. GitHub Actions will:
   - Run integration tests
   - Build Docker images
   - Push to container registry
   - Deploy to staging

### Deploying to Production

Production deployment requires manual trigger:

1. **Navigate to Actions tab**
2. **Select "Deploy to Production" workflow**
3. **Click "Run workflow"**
4. **Fill in inputs:**
   - Version: `main-abc1234` (or `latest`)
   - Confirm: `DEPLOY`
5. **Click "Run workflow" button**
6. **Approve deployment** when prompted (if you're a required reviewer)
7. **Monitor deployment progress**

### Rolling Back Production

If deployment fails, rollback is automatic. For manual rollback:

1. Go to failed deployment run
2. Re-run the `rollback` job
3. Approve rollback when prompted

## Local Testing

### Test Lint/Format Checks

```bash
# Backend
cd backend
black --check .
ruff check .
mypy app --ignore-missing-imports

# Frontend
cd frontend
npm run lint
npx prettier --check "src/**/*.{ts,tsx,css}"
npx tsc --noEmit

# Or use Makefile
make lint
```

### Run Unit Tests

```bash
# Using Docker Compose
make test

# Or individually
make test-backend
make test-frontend
```

### Run Integration Tests

```bash
# Start services
make up

# Wait for services to be ready
sleep 30

# Run integration tests
docker compose exec backend pytest tests/integration/

# Cleanup
make down
```

### Build Docker Images Locally

```bash
# Build all production images
make build-prod

# Or build individual services
docker build -f backend/Dockerfile.prod -t mlsp-backend:local backend/
docker build -f frontend/Dockerfile.prod -t mlsp-frontend:local frontend/
docker build -f data_pipeline/Dockerfile.prod -t mlsp-pipeline:local data_pipeline/
```

## Troubleshooting

### PR Checks Failing

1. **Check logs in GitHub Actions**
2. **Run checks locally** (see above)
3. **Common issues:**
   - Format issues: Run `make format` and commit changes
   - Type errors: Fix TypeScript/MyPy errors
   - Test failures: Fix failing tests

### Integration Tests Failing

1. **Check service logs:**
   ```bash
   docker compose logs backend
   docker compose logs postgres
   ```

2. **Verify services are healthy:**
   ```bash
   docker compose ps
   ```

3. **Common issues:**
   - Database not ready: Increase wait time
   - Port conflicts: Stop local services
   - Environment variables: Check `.env` file

### Deployment Failures

1. **Check Kubernetes pod status:**
   ```bash
   kubectl get pods -n mlsp-staging
   kubectl describe pod <pod-name> -n mlsp-staging
   kubectl logs <pod-name> -n mlsp-staging
   ```

2. **Common issues:**
   - Image pull errors: Verify image exists in registry
   - Configuration errors: Check ConfigMaps and Secrets
   - Resource limits: Check CPU/memory limits

### Rollback Not Working

1. **Verify backup artifacts exist**
2. **Check kubeconfig is valid**
3. **Manual rollback:**
   ```bash
   kubectl rollout undo deployment/backend -n mlsp-production
   kubectl rollout undo deployment/frontend -n mlsp-production
   kubectl rollout undo deployment/data-pipeline -n mlsp-production
   ```

## Monitoring

### GitHub Actions

- **View all workflows:** Repository → Actions tab
- **View specific run:** Click on workflow run
- **View logs:** Click on job → Expand steps

### Deployment Status

- **Staging:** Check staging URL health endpoint
- **Production:** Check production URL health endpoint

```bash
# Check staging
curl https://staging.mlsp.example.com/health

# Check production
curl https://mlsp.example.com/health
```

## Best Practices

1. **Always create PRs** - Never push directly to main
2. **Wait for checks to pass** - Don't merge failing PRs
3. **Review changes carefully** - Especially for production deployments
4. **Test locally first** - Run tests and lint before pushing
5. **Monitor deployments** - Watch deployment progress and logs
6. **Use meaningful commit messages** - Helps with debugging
7. **Tag releases** - Create git tags for production deployments
8. **Document changes** - Update changelog and documentation

## Future Improvements

- [ ] Add E2E tests with Playwright
- [ ] Implement performance testing
- [ ] Add security scanning (Snyk, Trivy)
- [ ] Set up monitoring and alerting (Datadog, Sentry)
- [ ] Implement blue-green deployments
- [ ] Add canary deployments
- [ ] Automated database migrations
- [ ] Slack/Discord notifications
- [ ] Deployment dashboards

## Support

For issues or questions:
1. Check this documentation
2. Review GitHub Actions logs
3. Check Kubernetes pod logs
4. Create an issue in the repository
