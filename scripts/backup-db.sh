#!/bin/bash
# Manual backup script for development

set -e

BACKUP_DIR="./backups/postgres"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
POSTGRES_USER=${POSTGRES_USER:-mlsp_user}
POSTGRES_DB=${POSTGRES_DB:-mlsp}

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

echo "Starting backup at $(date)"

# Backup all databases (full dump)
echo "Creating full database dump..."
docker exec mlsp-postgres pg_dumpall -U $POSTGRES_USER | gzip > $BACKUP_DIR/full_backup_$TIMESTAMP.sql.gz

# Backup individual databases (custom format for better compression and flexibility)
echo "Creating individual database backups..."
for DB in mlsp airflow mlflow; do
    docker exec mlsp-postgres pg_dump -U $POSTGRES_USER -Fc $DB > $BACKUP_DIR/${DB}_backup_$TIMESTAMP.dump
    echo "  - Backed up $DB database"
done

echo "Backup completed: $TIMESTAMP"
echo "Backup location: $BACKUP_DIR"
echo ""
echo "Files created:"
ls -lh $BACKUP_DIR/*_$TIMESTAMP.*
