# PostgreSQL with TimescaleDB Setup

## Overview

This document describes the PostgreSQL database configuration for the ML Sport Stat Predictor platform, including TimescaleDB extension, PgBouncer connection pooling, and backup strategies.

## Architecture

### Components

1. **PostgreSQL 15 with TimescaleDB Extension**
   - Image: `timescale/timescaledb:latest-pg15`
   - Port: 5432 (internal), mapped to host
   - Persistent storage: Docker volume `postgres_data`

2. **PgBouncer Connection Pooler**
   - Image: `edoburu/pgbouncer:1.21.0`
   - Port: 6432 (internal), mapped to host
   - Pool mode: Transaction
   - Max connections: 1000
   - Default pool size: 25

3. **Database Layout**
   - `mlsp` - Main application database (TimescaleDB enabled)
   - `airflow` - Apache Airflow metadata
   - `mlflow` - MLflow experiment tracking

### Connection Architecture

```
┌─────────────┐
│   Backend   │
│   (FastAPI) │
└──────┬──────┘
       │
       │ Port 6432
       │
┌──────▼──────────┐     ┌───────────────┐
│   PgBouncer     │────▶│  PostgreSQL   │
│ (Connection     │     │  TimescaleDB  │
│  Pooler)        │     │               │
└─────────────────┘     └───────────────┘
       ▲                        ▲
       │                        │
┌──────┴──────────┐     ┌──────┴────────┐
│    Airflow      │     │    MLflow     │
└─────────────────┘     └───────────────┘
```

## Database Features

### TimescaleDB Extension

TimescaleDB is enabled on the main `mlsp` database for efficient time-series data storage and querying.

**Key Features:**
- Automatic partitioning of time-series data (hypertables)
- Continuous aggregates for pre-computed queries
- Data retention policies
- Compression for historical data

**Use Cases in this Project:**
- Game statistics over time
- Player performance metrics
- Prediction accuracy tracking
- Model performance monitoring

### Additional PostgreSQL Extensions

The following extensions are enabled on the `mlsp` database:

1. **uuid-ossp** - UUID generation functions
2. **pgcrypto** - Cryptographic functions
3. **timescaledb** - Time-series database capabilities

## Connection Pooling with PgBouncer

### Why PgBouncer?

PgBouncer provides connection pooling to:
- Reduce connection overhead
- Support more concurrent clients than available database connections
- Improve application performance
- Reduce database server load

### Configuration

**Pool Mode:** Transaction (recommended for web applications)
- Connections are released back to the pool after each transaction
- Most efficient mode for stateless applications
- Compatible with most ORMs including SQLAlchemy

**Connection Limits:**
- Max client connections: 1000
- Default pool size per database: 25
- Min pool size: 10
- Reserve pool: 5 connections

**Timeouts:**
- Server idle timeout: 600s (10 minutes)
- Server lifetime: 3600s (1 hour)
- Query wait timeout: 120s

### Connection Strings

**Direct PostgreSQL Connection (for admin tasks):**
```
postgresql://mlsp_user:mlsp_password@localhost:5432/mlsp
```

**PgBouncer Pooled Connection (for applications):**
```
postgresql://mlsp_user:mlsp_password@localhost:6432/mlsp
```

**Application Configuration:**

All application services connect through PgBouncer:
- Backend API: `postgresql+asyncpg://mlsp_user:mlsp_password@pgbouncer:6432/mlsp`
- Airflow: `postgresql+psycopg2://mlsp_user:mlsp_password@pgbouncer:6432/airflow`
- MLflow: `postgresql://mlsp_user:mlsp_password@pgbouncer:6432/mlflow`

## Database Initialization

### Automatic Initialization

On first startup, the `scripts/init-db.sh` script automatically:
1. Creates `airflow` database
2. Creates `mlflow` database
3. Enables TimescaleDB extension on `mlsp` database
4. Enables `uuid-ossp` extension
5. Enables `pgcrypto` extension

### Manual Database Operations

**Access PostgreSQL Shell:**
```bash
docker exec -it mlsp-postgres psql -U mlsp_user -d mlsp
```

**Access PgBouncer Console:**
```bash
docker exec -it mlsp-pgbouncer psql -h localhost -p 6432 -U mlsp_user pgbouncer
```

**Useful PgBouncer Commands:**
```sql
SHOW POOLS;           -- Show pool statistics
SHOW DATABASES;       -- Show configured databases
SHOW CLIENTS;         -- Show client connections
SHOW SERVERS;         -- Show server connections
SHOW STATS;           -- Show statistics
RELOAD;               -- Reload configuration
```

## Backup and Recovery

### Quick Backup

Create a backup of all databases:
```bash
./scripts/backup-db.sh
```

This creates:
- Full dump: `backups/postgres/full_backup_TIMESTAMP.sql.gz`
- Individual dumps: `backups/postgres/{mlsp,airflow,mlflow}_backup_TIMESTAMP.dump`

### Quick Restore

Restore from a backup:
```bash
./scripts/restore-db.sh backups/postgres/full_backup_TIMESTAMP.sql.gz
```

### Advanced Backup Strategies

See [DATABASE-BACKUP-STRATEGY.md](./DATABASE-BACKUP-STRATEGY.md) for:
- Automated daily backups
- Point-in-time recovery (PITR)
- WAL archiving
- Production backup procedures
- Disaster recovery planning

## Performance Tuning

### PostgreSQL Configuration

The default TimescaleDB image comes pre-tuned for most use cases. For production deployments, consider adjusting:

**Memory Settings:**
```sql
ALTER SYSTEM SET shared_buffers = '4GB';
ALTER SYSTEM SET effective_cache_size = '12GB';
ALTER SYSTEM SET maintenance_work_mem = '1GB';
ALTER SYSTEM SET work_mem = '64MB';
```

**Connection Settings:**
```sql
ALTER SYSTEM SET max_connections = 200;
```

**TimescaleDB Settings:**
```sql
ALTER SYSTEM SET timescaledb.max_background_workers = 8;
```

### PgBouncer Tuning

Adjust pool sizes in `pgbouncer/pgbouncer.ini`:

```ini
default_pool_size = 25      # Increase for higher load
max_client_conn = 1000      # Increase for more concurrent clients
reserve_pool_size = 5       # Reserve connections for high-priority queries
```

## Monitoring

### Health Checks

All database services include health checks:

**PostgreSQL:**
```bash
docker exec mlsp-postgres pg_isready -U mlsp_user -d mlsp
```

**PgBouncer:**
```bash
docker exec mlsp-pgbouncer pg_isready -h localhost -p 6432 -U mlsp_user
```

### Monitoring Queries

**Active Connections:**
```sql
SELECT * FROM pg_stat_activity WHERE state = 'active';
```

**Database Size:**
```sql
SELECT pg_size_pretty(pg_database_size('mlsp'));
```

**Table Sizes:**
```sql
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;
```

**PgBouncer Statistics:**
```sql
-- Connect to PgBouncer console
\c pgbouncer

-- Show pool stats
SHOW POOLS;

-- Show server connections
SHOW SERVERS;
```

### Logs

**PostgreSQL Logs:**
```bash
docker logs mlsp-postgres
```

**PgBouncer Logs:**
```bash
docker logs mlsp-pgbouncer
```

## Security

### Authentication

- **Method:** SCRAM-SHA-256 (default)
- **User:** `mlsp_user` (configurable via environment)
- **Password:** Set via `POSTGRES_PASSWORD` environment variable

### Network Security

**Development:**
- Ports exposed on localhost for debugging
- Not recommended for production use

**Production:**
- Keep PostgreSQL port (5432) internal to Docker network
- Only expose PgBouncer port (6432) if external access is needed
- Use SSL/TLS for connections
- Implement firewall rules
- Use secrets management for credentials

### Best Practices

1. **Change default passwords** in production
2. **Use environment variables** for credentials (never hardcode)
3. **Enable SSL** for production deployments
4. **Implement least privilege** access control
5. **Regular security updates** for PostgreSQL and PgBouncer
6. **Audit logging** for compliance requirements

## Troubleshooting

### Common Issues

**1. Connection Refused**
```bash
# Check if services are running
docker-compose ps

# Check logs
docker logs mlsp-postgres
docker logs mlsp-pgbouncer
```

**2. Too Many Connections**
```bash
# Check active connections
docker exec mlsp-postgres psql -U mlsp_user -d mlsp -c "SELECT count(*) FROM pg_stat_activity;"

# Increase PgBouncer pool size or max_connections
```

**3. PgBouncer Authentication Failed**
```bash
# Verify userlist.txt is correctly configured
docker exec mlsp-pgbouncer cat /etc/pgbouncer/userlist.txt

# Restart PgBouncer
docker-compose restart pgbouncer
```

**4. TimescaleDB Extension Not Found**
```bash
# Verify extension is installed
docker exec mlsp-postgres psql -U mlsp_user -d mlsp -c "SELECT * FROM pg_extension WHERE extname = 'timescaledb';"

# If not found, create it manually
docker exec mlsp-postgres psql -U mlsp_user -d mlsp -c "CREATE EXTENSION timescaledb;"
```

## Maintenance

### Regular Tasks

**Weekly:**
- Review database growth
- Check slow query logs
- Monitor connection pool usage
- Verify backup completion

**Monthly:**
- Test backup restoration
- Review and optimize slow queries
- Update table statistics (ANALYZE)
- Check for unused indexes

**Quarterly:**
- Review data retention policies
- Perform VACUUM FULL on large tables (during maintenance window)
- Review and adjust PgBouncer pool sizes
- Security audit

### Useful Commands

**Vacuum Database:**
```bash
docker exec mlsp-postgres vacuumdb -U mlsp_user -d mlsp --analyze --verbose
```

**Reindex Database:**
```bash
docker exec mlsp-postgres reindexdb -U mlsp_user -d mlsp
```

**Analyze Tables:**
```bash
docker exec mlsp-postgres psql -U mlsp_user -d mlsp -c "ANALYZE;"
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_DB` | `mlsp` | Main database name |
| `POSTGRES_USER` | `mlsp_user` | PostgreSQL username |
| `POSTGRES_PASSWORD` | `mlsp_password` | PostgreSQL password |
| `POSTGRES_PORT` | `5432` | PostgreSQL port |
| `POSTGRES_HOST_AUTH_METHOD` | `scram-sha-256` | Authentication method |
| `PGBOUNCER_PORT` | `6432` | PgBouncer port |
| `AIRFLOW_DB` | `airflow` | Airflow database name |
| `MLFLOW_DB` | `mlflow` | MLflow database name |

## References

- [PostgreSQL 15 Documentation](https://www.postgresql.org/docs/15/)
- [TimescaleDB Documentation](https://docs.timescale.com/)
- [PgBouncer Documentation](https://www.pgbouncer.org/)
- [PostgreSQL High Availability](https://www.postgresql.org/docs/15/high-availability.html)
- [Database Backup Strategy](./DATABASE-BACKUP-STRATEGY.md)
