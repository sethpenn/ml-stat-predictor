#!/bin/sh
set -e

# Generate password hash for userlist.txt
if [ -n "$POSTGRES_PASSWORD" ]; then
    # Create a temporary PostgreSQL password hash
    # PgBouncer expects: "username" "SCRAM-SHA-256$<iterations>:<salt>$<StoredKey>:<ServerKey>"
    # For simplicity in development, we'll use plain password (not recommended for production)
    # In production, you should generate proper SCRAM-SHA-256 hashes
    echo "\"$POSTGRES_USER\" \"$POSTGRES_PASSWORD\"" > /etc/pgbouncer/userlist.txt
fi

# Start PgBouncer
exec pgbouncer /etc/pgbouncer/pgbouncer.ini
