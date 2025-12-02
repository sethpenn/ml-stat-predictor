#!/bin/bash
# Manual restore script for development

set -e

BACKUP_FILE=$1
POSTGRES_USER=${POSTGRES_USER:-mlsp_user}

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: ./scripts/restore-db.sh <backup_file>"
    echo ""
    echo "Examples:"
    echo "  ./scripts/restore-db.sh ./backups/postgres/full_backup_20240115_140000.sql.gz"
    echo "  ./scripts/restore-db.sh ./backups/postgres/mlsp_backup_20240115_140000.dump"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "WARNING: This will restore the database from backup."
echo "File: $BACKUP_FILE"
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

echo "Starting restore at $(date)"

# Restore from compressed SQL dump (full restore)
if [[ $BACKUP_FILE == *.sql.gz ]]; then
    echo "Restoring from full database dump..."
    gunzip -c $BACKUP_FILE | docker exec -i mlsp-postgres psql -U $POSTGRES_USER -d postgres

# Restore from custom format dump (individual database)
elif [[ $BACKUP_FILE == *.dump ]]; then
    # Extract database name from filename
    DB_NAME=$(basename $BACKUP_FILE | cut -d'_' -f1)
    echo "Restoring $DB_NAME database from custom format dump..."
    docker exec -i mlsp-postgres pg_restore -U $POSTGRES_USER -d $DB_NAME -c < $BACKUP_FILE
else
    echo "Error: Unsupported backup file format"
    echo "Supported formats: .sql.gz, .dump"
    exit 1
fi

echo "Restore completed at $(date)"
echo ""
echo "Please verify the restoration and restart dependent services if needed:"
echo "  docker-compose restart backend airflow-webserver airflow-scheduler mlflow"
