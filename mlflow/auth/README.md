# MLflow Authentication Configuration

This directory contains the authentication configuration for MLflow.

## Files

- `basic_auth.ini`: Configuration file for MLflow basic authentication
- `basic_auth.db`: SQLite database for user credentials (auto-generated, not in git)

## Default Credentials

- **Username**: admin
- **Password**: admin_password

**IMPORTANT**: Change these credentials in production by updating the `.env` file:
- `MLFLOW_ADMIN_USERNAME`
- `MLFLOW_ADMIN_PASSWORD`

## Authentication Setup

MLflow uses basic authentication with the following configuration:
- Default permission for authenticated users: READ
- Admin users have full permissions
- User database stored in SQLite for development

## Managing Users

To add new users, use the MLflow CLI:

```bash
# Access MLflow container
docker compose exec mlflow bash

# Create a new user
mlflow auth create-user --username <username> --password <password>

# Grant admin permission
mlflow auth update-user --username <username> --admin
```

## Accessing MLflow

When accessing MLflow UI or API, you'll need to provide credentials:
- UI: Login prompt will appear
- API: Use HTTP Basic Auth with username/password

## Production Considerations

For production deployments:
1. Use strong passwords
2. Consider using external authentication (LDAP, OAuth)
3. Enable HTTPS
4. Rotate credentials regularly
