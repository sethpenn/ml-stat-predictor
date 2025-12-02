# PostgreSQL Backup Strategy

## Overview

This document outlines the backup and recovery strategy for the ML Sport Stat Predictor PostgreSQL database with TimescaleDB extension.

## Database Architecture

The system uses a single PostgreSQL 15 instance with TimescaleDB extension, hosting three databases:
- `mlsp` - Main application database (with TimescaleDB for time-series data)
- `airflow` - Apache Airflow metadata database
- `mlflow` - MLflow experiment tracking database

## Backup Strategy

### 1. Automated Daily Backups

**Schedule:** Daily at 2:00 AM UTC

**Method:** Full database dump using `pg_dump`

**Retention Policy:**
- Daily backups: 7 days
- Weekly backups (Sunday): 4 weeks
- Monthly backups (1st of month): 6 months

**Storage Location:**
- Development: Local volume mount at `./backups/postgres`
- Production: S3-compatible object storage (AWS S3, MinIO, etc.)

### 2. Continuous Archiving (WAL)

**Method:** Write-Ahead Log (WAL) archiving for point-in-time recovery (PITR)

**Configuration:**
- Archive mode: ON
- Archive command: Copy WAL files to backup location
- WAL retention: 7 days

**Benefits:**
- Point-in-time recovery to any moment in the last 7 days
- Minimal data loss (typically seconds)
- Continuous backup without performance impact

### 3. TimescaleDB-Specific Considerations

**Hypertable Backups:**
- TimescaleDB hypertables are automatically backed up with standard pg_dump
- Continuous aggregates are included in backups
- Compression policies are preserved

**Retention Policies:**
- Data retention policies are defined in application code
- Backed up data respects defined retention windows
- Old chunks are automatically dropped per retention policy

## Backup Implementation

### Development Environment

#### Manual Backup Script

Create `scripts/backup-db.sh`:

```bash
#!/bin/bash
# Manual backup script for development

BACKUP_DIR="./backups/postgres"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
POSTGRES_USER=${POSTGRES_USER:-mlsp_user}
POSTGRES_DB=${POSTGRES_DB:-mlsp}

mkdir -p $BACKUP_DIR

# Backup all databases
docker exec mlsp-postgres pg_dumpall -U $POSTGRES_USER | gzip > $BACKUP_DIR/full_backup_$TIMESTAMP.sql.gz

# Backup individual databases
for DB in mlsp airflow mlflow; do
    docker exec mlsp-postgres pg_dump -U $POSTGRES_USER -Fc $DB > $BACKUP_DIR/${DB}_backup_$TIMESTAMP.dump
done

echo "Backup completed: $TIMESTAMP"
```

#### Manual Restore Script

Create `scripts/restore-db.sh`:

```bash
#!/bin/bash
# Manual restore script for development

BACKUP_FILE=$1
POSTGRES_USER=${POSTGRES_USER:-mlsp_user}

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: ./scripts/restore-db.sh <backup_file>"
    exit 1
fi

# Restore from compressed SQL dump
if [[ $BACKUP_FILE == *.sql.gz ]]; then
    gunzip -c $BACKUP_FILE | docker exec -i mlsp-postgres psql -U $POSTGRES_USER
# Restore from custom format dump
elif [[ $BACKUP_FILE == *.dump ]]; then
    cat $BACKUP_FILE | docker exec -i mlsp-postgres pg_restore -U $POSTGRES_USER -d postgres
fi

echo "Restore completed from: $BACKUP_FILE"
```

### Production Environment

#### Automated Backup with Cron

Add to production server crontab:

```bash
# Daily backup at 2 AM UTC
0 2 * * * /opt/mlsp/scripts/backup-postgres-production.sh >> /var/log/mlsp-backup.log 2>&1

# Weekly cleanup of old backups
0 3 * * 0 /opt/mlsp/scripts/cleanup-old-backups.sh >> /var/log/mlsp-backup.log 2>&1
```

#### Production Backup Script

Create `scripts/backup-postgres-production.sh`:

```bash
#!/bin/bash
set -e

# Configuration
BACKUP_DIR="/backups/postgres"
S3_BUCKET="s3://mlsp-backups/postgres"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE=$(date +%Y%m%d)
DAY_OF_WEEK=$(date +%u)
DAY_OF_MONTH=$(date +%d)
POSTGRES_USER=${POSTGRES_USER:-mlsp_user}

mkdir -p $BACKUP_DIR

# Perform backup
echo "Starting backup at $(date)"

# Full backup of all databases
docker exec mlsp-postgres pg_dumpall -U $POSTGRES_USER | gzip > $BACKUP_DIR/full_backup_$TIMESTAMP.sql.gz

# Individual database backups (custom format for better compression and flexibility)
docker exec mlsp-postgres pg_dump -U $POSTGRES_USER -Fc mlsp > $BACKUP_DIR/mlsp_$TIMESTAMP.dump
docker exec mlsp-postgres pg_dump -U $POSTGRES_USER -Fc airflow > $BACKUP_DIR/airflow_$TIMESTAMP.dump
docker exec mlsp-postgres pg_dump -U $POSTGRES_USER -Fc mlflow > $BACKUP_DIR/mlflow_$TIMESTAMP.dump

# Upload to S3
aws s3 cp $BACKUP_DIR/full_backup_$TIMESTAMP.sql.gz $S3_BUCKET/daily/
aws s3 cp $BACKUP_DIR/mlsp_$TIMESTAMP.dump $S3_BUCKET/daily/
aws s3 cp $BACKUP_DIR/airflow_$TIMESTAMP.dump $S3_BUCKET/daily/
aws s3 cp $BACKUP_DIR/mlflow_$TIMESTAMP.dump $S3_BUCKET/daily/

# Weekly backup (Sunday)
if [ "$DAY_OF_WEEK" -eq 7 ]; then
    aws s3 cp $BACKUP_DIR/full_backup_$TIMESTAMP.sql.gz $S3_BUCKET/weekly/
fi

# Monthly backup (1st of month)
if [ "$DAY_OF_MONTH" -eq 01 ]; then
    aws s3 cp $BACKUP_DIR/full_backup_$TIMESTAMP.sql.gz $S3_BUCKET/monthly/
fi

# Cleanup local backups older than 3 days
find $BACKUP_DIR -name "*.sql.gz" -mtime +3 -delete
find $BACKUP_DIR -name "*.dump" -mtime +3 -delete

echo "Backup completed at $(date)"
```

#### Cleanup Script

Create `scripts/cleanup-old-backups.sh`:

```bash
#!/bin/bash
set -e

S3_BUCKET="s3://mlsp-backups/postgres"

# Delete daily backups older than 7 days
aws s3 ls $S3_BUCKET/daily/ | while read -r line; do
    CREATE_DATE=$(echo $line | awk '{print $1" "$2}')
    CREATE_DATE_UNIX=$(date -d "$CREATE_DATE" +%s)
    DAYS_OLD=$((($(date +%s) - $CREATE_DATE_UNIX) / 86400))

    if [ $DAYS_OLD -gt 7 ]; then
        FILE=$(echo $line | awk '{print $4}')
        aws s3 rm $S3_BUCKET/daily/$FILE
    fi
done

# Delete weekly backups older than 4 weeks
aws s3 ls $S3_BUCKET/weekly/ | while read -r line; do
    CREATE_DATE=$(echo $line | awk '{print $1" "$2}')
    CREATE_DATE_UNIX=$(date -d "$CREATE_DATE" +%s)
    WEEKS_OLD=$((($(date +%s) - $CREATE_DATE_UNIX) / 604800))

    if [ $WEEKS_OLD -gt 4 ]; then
        FILE=$(echo $line | awk '{print $4}')
        aws s3 rm $S3_BUCKET/weekly/$FILE
    fi
done

# Delete monthly backups older than 6 months
aws s3 ls $S3_BUCKET/monthly/ | while read -r line; do
    CREATE_DATE=$(echo $line | awk '{print $1" "$2}')
    CREATE_DATE_UNIX=$(date -d "$CREATE_DATE" +%s)
    MONTHS_OLD=$((($(date +%s) - $CREATE_DATE_UNIX) / 2592000))

    if [ $MONTHS_OLD -gt 6 ]; then
        FILE=$(echo $line | awk '{print $4}')
        aws s3 rm $S3_BUCKET/monthly/$FILE
    fi
done

echo "Cleanup completed at $(date)"
```

## Continuous Archiving Setup (WAL)

### PostgreSQL Configuration

Add to `scripts/postgres-wal-config.sh`:

```bash
#!/bin/bash
# Enable WAL archiving in PostgreSQL

docker exec mlsp-postgres psql -U postgres -c "ALTER SYSTEM SET wal_level = replica;"
docker exec mlsp-postgres psql -U postgres -c "ALTER SYSTEM SET archive_mode = on;"
docker exec mlsp-postgres psql -U postgres -c "ALTER SYSTEM SET archive_command = 'test ! -f /var/lib/postgresql/wal_archive/%f && cp %p /var/lib/postgresql/wal_archive/%f';"
docker exec mlsp-postgres psql -U postgres -c "ALTER SYSTEM SET archive_timeout = 300;"

# Restart PostgreSQL to apply changes
docker restart mlsp-postgres
```

### WAL Archive Volume

Add to `docker-compose.yml`:

```yaml
volumes:
  postgres_data:
    driver: local
  postgres_wal_archive:
    driver: local
```

Update postgres service:

```yaml
volumes:
  - postgres_data:/var/lib/postgresql/data
  - postgres_wal_archive:/var/lib/postgresql/wal_archive
  - ./scripts/init-db.sh:/docker-entrypoint-initdb.d/init-db.sh
```

## Recovery Procedures

### Full Database Restore

```bash
# Stop all services except postgres
docker-compose stop backend frontend airflow-webserver airflow-scheduler airflow-worker mlflow

# Drop existing databases (WARNING: destructive)
docker exec mlsp-postgres psql -U postgres -c "DROP DATABASE IF EXISTS mlsp;"
docker exec mlsp-postgres psql -U postgres -c "DROP DATABASE IF EXISTS airflow;"
docker exec mlsp-postgres psql -U postgres -c "DROP DATABASE IF EXISTS mlflow;"

# Restore from backup
gunzip -c backups/postgres/full_backup_TIMESTAMP.sql.gz | docker exec -i mlsp-postgres psql -U postgres

# Restart all services
docker-compose up -d
```

### Individual Database Restore

```bash
# Restore specific database (e.g., mlsp)
docker exec mlsp-postgres pg_restore -U mlsp_user -d mlsp -c backups/postgres/mlsp_TIMESTAMP.dump
```

### Point-in-Time Recovery (PITR)

```bash
# 1. Stop PostgreSQL
docker-compose stop postgres

# 2. Restore base backup
rm -rf postgres_data/*
tar -xzf backups/postgres/base_backup.tar.gz -C postgres_data/

# 3. Create recovery.conf
cat > postgres_data/recovery.conf <<EOF
restore_command = 'cp /var/lib/postgresql/wal_archive/%f %p'
recovery_target_time = '2024-01-15 14:30:00'
recovery_target_action = 'promote'
EOF

# 4. Start PostgreSQL
docker-compose up -d postgres
```

## Monitoring and Alerts

### Backup Verification

Create `scripts/verify-backup.sh`:

```bash
#!/bin/bash
# Verify latest backup integrity

LATEST_BACKUP=$(ls -t backups/postgres/mlsp_*.dump | head -1)

# Test restore to temporary database
docker exec mlsp-postgres createdb -U postgres test_restore
docker exec mlsp-postgres pg_restore -U postgres -d test_restore $LATEST_BACKUP

# Verify restoration success
if [ $? -eq 0 ]; then
    echo "Backup verification successful: $LATEST_BACKUP"
    docker exec mlsp-postgres dropdb -U postgres test_restore
    exit 0
else
    echo "Backup verification failed: $LATEST_BACKUP"
    exit 1
fi
```

### Monitoring Checklist

- [ ] Daily backup completion status
- [ ] Backup file size consistency
- [ ] S3 upload success (production)
- [ ] WAL archive growth rate
- [ ] Available disk space
- [ ] Backup restore test (monthly)

### Alerting

Configure alerts for:
- Backup job failures
- Missing daily backups
- Disk space below 20%
- WAL archive disk usage above 80%

## Disaster Recovery Plan

### RTO (Recovery Time Objective)
- Development: 1 hour
- Production: 30 minutes

### RPO (Recovery Point Objective)
- Development: 24 hours (last daily backup)
- Production: 5 minutes (WAL-based PITR)

### Recovery Steps

1. **Assess the situation**
   - Identify the type of failure (data corruption, hardware failure, etc.)
   - Determine the recovery point needed

2. **Prepare recovery environment**
   - Provision new infrastructure if needed
   - Ensure network connectivity

3. **Restore from backup**
   - Use latest full backup
   - Apply WAL files if PITR is needed

4. **Verify data integrity**
   - Check critical tables
   - Verify TimescaleDB hypertables
   - Test application connectivity

5. **Resume operations**
   - Start all dependent services
   - Monitor application health
   - Notify stakeholders

## Testing Schedule

- **Monthly:** Test restore from latest backup
- **Quarterly:** Full disaster recovery drill
- **Annually:** Review and update backup strategy

## Additional Considerations

### Security

- Encrypt backups at rest (AES-256)
- Encrypt backups in transit (TLS)
- Restrict access to backup storage (IAM policies)
- Regular security audits of backup access logs

### Compliance

- Retain backups according to regulatory requirements
- Document retention policies
- Maintain audit trail of backup operations

### Cost Optimization

- Use S3 lifecycle policies to transition old backups to cheaper storage classes
- Compress backups to reduce storage costs
- Monitor and optimize backup size

## References

- [PostgreSQL Backup Documentation](https://www.postgresql.org/docs/15/backup.html)
- [TimescaleDB Backup Best Practices](https://docs.timescale.com/self-hosted/latest/backup-and-restore/)
- [pg_dump Documentation](https://www.postgresql.org/docs/15/app-pgdump.html)
- [Point-in-Time Recovery](https://www.postgresql.org/docs/15/continuous-archiving.html)
