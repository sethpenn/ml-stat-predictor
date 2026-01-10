# GitHub Actions Workflows

This directory contains the CI/CD workflows for the ML Sport Stat Predictor project.

## Workflows

### 🔍 pr.yml - Pull Request Validation
**Trigger:** Pull requests to `main` or `develop`

Runs automated checks on every PR:
- Lint and format checks (backend, frontend, data pipeline)
- Unit tests with coverage
- Type checking

**Status:** Must pass before merging

---

### 🚀 main.yml - Main Branch CI/CD
**Trigger:** Push to `main` branch

Runs on every merge to main:
- Integration tests
- Docker image builds
- Push to container registry (ghcr.io)
- Deploy to staging environment

**Automatic:** Runs automatically on merge

---

### 🎯 deploy-production.yml - Production Deployment
**Trigger:** Manual workflow dispatch

Deploys to production with safeguards:
- Requires manual trigger
- Requires typing "DEPLOY" to confirm
- Requires approval from designated reviewers
- Creates backups before deployment
- Runs smoke tests after deployment
- Automatic rollback on failure

**Manual:** Must be triggered from Actions tab

---

### 👤 claude.yml - Claude Code Integration
**Trigger:** Comments mentioning `@claude`

Allows Claude to assist with:
- Code reviews
- Issue triage
- PR analysis

**Automatic:** Triggered by `@claude` mentions

---

### 👤 claude-code-review.yml - Claude Code Reviews
**Trigger:** Specific events (check workflow file)

Automated code review assistance using Claude.

**Automatic:** Triggered by configured events

---

## Quick Links

- [Full CI/CD Documentation](../docs/CI-CD.md)
- [GitHub Secrets Setup](../docs/CI-CD.md#setting-up-secrets)
- [Deployment Process](../docs/CI-CD.md#deployment-process)
- [Troubleshooting](../docs/CI-CD.md#troubleshooting)

## Required Secrets

### For Container Registry
- `GITHUB_TOKEN` - Automatically provided

### For Staging Deployment
- `KUBE_CONFIG_STAGING` - Kubernetes config (base64 encoded)
- `STAGING_URL` - Staging environment URL

### For Production Deployment
- `KUBE_CONFIG_PRODUCTION` - Kubernetes config (base64 encoded)
- `PRODUCTION_URL` - Production environment URL

### Optional
- `CODECOV_TOKEN` - For code coverage uploads
- `SLACK_WEBHOOK_URL` - For Slack notifications

## GitHub Environments

Create these environments in Repository Settings → Environments:

1. **staging**
   - No required reviewers
   - Auto-deploys on main branch push

2. **production**
   - 1-2 required reviewers
   - Manual deployment only

3. **production-rollback**
   - 1 required reviewer
   - For rollback approval

## Local Testing

```bash
# Run all checks locally
make lint        # Run linters
make test        # Run tests
make build-prod  # Build production images
```

## Deployment Commands

### Deploy to Staging
```bash
# Automatic - just merge to main
git checkout main
git merge feature-branch
git push
```

### Deploy to Production
1. Go to Actions tab
2. Select "Deploy to Production"
3. Click "Run workflow"
4. Enter version (e.g., `main-abc1234` or `latest`)
5. Type `DEPLOY` to confirm
6. Approve when prompted

## Monitoring

- **Actions Tab:** View all workflow runs
- **Staging Health:** `https://staging.mlsp.example.com/health`
- **Production Health:** `https://mlsp.example.com/health`

## Support

See [CI/CD Documentation](../docs/CI-CD.md) for detailed information.
