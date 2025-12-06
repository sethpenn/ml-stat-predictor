# CI/CD Setup Checklist

Use this checklist to track the setup and configuration of the CI/CD pipeline.

## Prerequisites

- [ ] GitHub repository created
- [ ] Docker installed locally
- [ ] GitHub CLI (`gh`) installed and authenticated
- [ ] Kubernetes cluster(s) available (staging and production)
- [ ] kubectl configured with cluster access

## GitHub Repository Configuration

### Secrets

- [ ] `KUBE_CONFIG_STAGING` - Base64-encoded kubeconfig for staging
- [ ] `KUBE_CONFIG_PRODUCTION` - Base64-encoded kubeconfig for production
- [ ] `STAGING_URL` - Staging environment URL
- [ ] `PRODUCTION_URL` - Production environment URL
- [ ] `CODECOV_TOKEN` - (Optional) Codecov upload token
- [ ] `SLACK_WEBHOOK_URL` - (Optional) Slack notifications
- [ ] `DISCORD_WEBHOOK_URL` - (Optional) Discord notifications

**Setup Command:**
```bash
./scripts/setup-github-secrets.sh
```

### Environments

- [ ] **staging** environment created
  - [ ] URL configured
  - [ ] No required reviewers (auto-deploy)
  - [ ] Optional wait timer configured

- [ ] **production** environment created
  - [ ] URL configured
  - [ ] Required reviewers added (1-2 people)
  - [ ] Optional wait timer configured (5+ minutes)

- [ ] **production-rollback** environment created
  - [ ] Required reviewers added (1 person)

**Setup Location:** Repository Settings → Environments

### Branch Protection Rules

- [ ] `main` branch protection enabled
  - [ ] Require pull request before merging
  - [ ] Require status checks to pass:
    - [ ] Backend Lint & Format
    - [ ] Backend Unit Tests
    - [ ] Frontend Lint & Format
    - [ ] Frontend Unit Tests
    - [ ] Data Pipeline Lint
    - [ ] All Checks Passed
  - [ ] Require conversation resolution before merging
  - [ ] Require signed commits (optional)
  - [ ] Include administrators in restrictions

**Setup Location:** Repository Settings → Branches → Add rule

## Kubernetes Setup

### Staging Environment

- [ ] Namespace created: `mlsp-staging`
- [ ] Deployments created:
  - [ ] `backend`
  - [ ] `frontend`
  - [ ] `data-pipeline`
- [ ] Services configured
- [ ] Ingress configured
- [ ] ConfigMaps created
- [ ] Secrets created
- [ ] Resource limits set
- [ ] Health checks configured

### Production Environment

- [ ] Namespace created: `mlsp-production`
- [ ] Deployments created:
  - [ ] `backend`
  - [ ] `frontend`
  - [ ] `data-pipeline`
- [ ] Services configured
- [ ] Ingress configured
- [ ] ConfigMaps created
- [ ] Secrets created
- [ ] Resource limits set
- [ ] Health checks configured
- [ ] Monitoring configured
- [ ] Alerts configured

## Container Registry

- [ ] GitHub Container Registry enabled
- [ ] Packages visibility set (public/private)
- [ ] Image pull secrets configured in Kubernetes (if private)

## Local Development

- [ ] `.env` file created from `.env.example`
- [ ] All services start with `make up`
- [ ] Tests pass locally with `make test`
- [ ] Lint checks pass with `make lint`
- [ ] Docker builds succeed with `make build-prod`

## Testing Workflows

### PR Workflow

- [ ] Create test branch
- [ ] Make a small change
- [ ] Create pull request
- [ ] Verify all checks run:
  - [ ] Backend lint passes
  - [ ] Frontend lint passes
  - [ ] Backend tests pass
  - [ ] Frontend tests pass
  - [ ] Data pipeline lint passes
- [ ] Merge PR (or close without merging)

### Main Branch Workflow

- [ ] Merge PR to main
- [ ] Verify integration tests run
- [ ] Verify Docker images build
- [ ] Verify images pushed to ghcr.io
- [ ] Verify staging deployment succeeds
- [ ] Check staging environment health
- [ ] Verify application works in staging

### Production Deployment

- [ ] Go to Actions → Deploy to Production
- [ ] Click "Run workflow"
- [ ] Enter test version/tag
- [ ] Type "DEPLOY" to confirm
- [ ] Verify validation passes
- [ ] Approve deployment (if you're a reviewer)
- [ ] Verify deployment succeeds
- [ ] Verify smoke tests pass
- [ ] Check production environment health
- [ ] Verify application works in production

### Rollback Test

- [ ] Trigger failed deployment (or simulate)
- [ ] Verify automatic rollback triggers
- [ ] Approve rollback
- [ ] Verify rollback succeeds
- [ ] Verify application restored to previous version

## Monitoring & Alerts

- [ ] Codecov integration working
- [ ] Coverage reports visible in PRs
- [ ] Slack/Discord notifications configured
- [ ] Test notification delivery
- [ ] Monitoring dashboards created
- [ ] Alerts configured for:
  - [ ] Failed deployments
  - [ ] Failed health checks
  - [ ] High error rates

## Documentation

- [ ] CI/CD documentation reviewed
- [ ] Team trained on deployment process
- [ ] Runbook created for common issues
- [ ] On-call rotation established
- [ ] Incident response plan created

## Security

- [ ] Dependabot enabled
- [ ] Security alerts enabled
- [ ] Secret scanning enabled
- [ ] Code scanning enabled (CodeQL)
- [ ] Container vulnerability scanning enabled
- [ ] SBOM (Software Bill of Materials) generated

## Optimization

- [ ] Workflow caching configured
- [ ] Build times optimized
- [ ] Parallelization maximized
- [ ] Unnecessary steps removed
- [ ] Resource usage optimized

## Compliance

- [ ] Deployment audit log configured
- [ ] Access controls reviewed
- [ ] Compliance requirements met
- [ ] Data retention policies configured
- [ ] Backup strategy implemented

## Future Enhancements

- [ ] E2E tests with Playwright
- [ ] Performance testing
- [ ] Load testing
- [ ] Security scanning (Snyk, Trivy)
- [ ] Blue-green deployments
- [ ] Canary deployments
- [ ] Automated database migrations
- [ ] Deployment dashboards
- [ ] Chaos engineering tests

## Sign-off

- [ ] CI/CD pipeline reviewed by: _______________
- [ ] Approved for production use by: _______________
- [ ] Date: _______________

---

## Quick Reference Commands

```bash
# Setup GitHub secrets
./scripts/setup-github-secrets.sh

# Run tests locally
make test

# Run linters locally
make lint

# Build production images
make build-prod

# Start local environment
make up

# View logs
make logs

# Deploy to production (via GitHub UI)
# Go to: https://github.com/<owner>/<repo>/actions/workflows/deploy-production.yml

# Check deployment status
gh run list --workflow=deploy-production.yml
gh run view <run-id>
```

## Support

- Documentation: [docs/CI-CD.md](../docs/CI-CD.md)
- Workflow README: [.github/workflows/README.md](.github/workflows/README.md)
- Issues: Create issue in repository
