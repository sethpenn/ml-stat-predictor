#!/bin/bash
# Comprehensive health check for all ML Sport Stat Predictor services

echo "=================================="
echo "ML STAT PREDICTOR - HEALTH CHECK"
echo "=================================="
echo ""

echo "=== ALL SERVICES STATUS ==="
docker-compose ps
echo ""

echo "=== HEALTH CHECK DETAILS ==="
for service in mlsp-postgres mlsp-pgbouncer mlsp-redis mlsp-airflow-webserver mlsp-airflow-scheduler mlsp-airflow-worker; do
    if docker inspect $service > /dev/null 2>&1; then
        echo "--- $service ---"
        docker inspect $service --format='Status: {{.State.Health.Status}}' 2>/dev/null || echo "Status: No health check defined"
        docker inspect $service --format='{{range .State.Health.Log}}  {{.ExitCode}}: {{.Output}}{{end}}' 2>/dev/null | head -3
        echo ""
    fi
done

echo "=== RESOURCE USAGE ==="
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
echo ""

echo "=== RECENT LOGS (Last 10 lines per service) ==="
echo ""
for service in postgres pgbouncer redis backend frontend airflow-webserver airflow-scheduler airflow-worker mlflow; do
    echo "--- $service ---"
    docker-compose logs $service --tail=10 2>/dev/null | tail -10
    echo ""
done

echo "=== ERRORS IN LOGS (Last 5 per service) ==="
echo ""
for service in postgres pgbouncer redis backend frontend airflow-webserver airflow-scheduler airflow-worker mlflow; do
    ERRORS=$(docker-compose logs $service 2>/dev/null | grep -i "error" | tail -5)
    if [ ! -z "$ERRORS" ]; then
        echo "--- $service ERRORS ---"
        echo "$ERRORS"
        echo ""
    fi
done

echo "=== WARNINGS IN LOGS (Last 3 per service) ==="
echo ""
for service in postgres pgbouncer redis backend frontend airflow-webserver airflow-scheduler airflow-worker mlflow; do
    WARNINGS=$(docker-compose logs $service 2>/dev/null | grep -i "warning\|warn" | grep -v "CPendingDeprecationWarning" | tail -3)
    if [ ! -z "$WARNINGS" ]; then
        echo "--- $service WARNINGS ---"
        echo "$WARNINGS"
        echo ""
    fi
done

echo "=== CRITICAL ISSUES (Last 3 per service) ==="
echo ""
for service in postgres pgbouncer redis backend frontend airflow-webserver airflow-scheduler airflow-worker mlflow; do
    CRITICAL=$(docker-compose logs $service 2>/dev/null | grep -i "critical\|fatal" | tail -3)
    if [ ! -z "$CRITICAL" ]; then
        echo "--- $service CRITICAL ---"
        echo "$CRITICAL"
        echo ""
    fi
done

echo "=== PORT AVAILABILITY ==="
echo "Checking if services are accessible on their ports..."
echo ""
curl -s http://localhost:8000/health > /dev/null && echo "✓ Backend (8000): Accessible" || echo "✗ Backend (8000): Not accessible"
curl -s http://localhost:3000 > /dev/null && echo "✓ Frontend (3000): Accessible" || echo "✗ Frontend (3000): Not accessible"
curl -s http://localhost:8080/health > /dev/null && echo "✓ Airflow (8080): Accessible" || echo "✗ Airflow (8080): Not accessible"
curl -s http://localhost:5000 > /dev/null && echo "✓ MLflow (5000): Accessible" || echo "✗ MLflow (5000): Not accessible"
nc -z localhost 5432 && echo "✓ PostgreSQL (5432): Accessible" || echo "✗ PostgreSQL (5432): Not accessible"
nc -z localhost 6432 && echo "✓ PgBouncer (6432): Accessible" || echo "✗ PgBouncer (6432): Not accessible"
nc -z localhost 6379 && echo "✓ Redis (6379): Accessible" || echo "✗ Redis (6379): Not accessible"
echo ""

echo "=== DISK USAGE ==="
docker system df
echo ""

echo "=== NETWORK CONNECTIVITY ==="
echo "Checking internal network connectivity..."
docker exec mlsp-backend nc -z postgres 5432 && echo "✓ Backend → PostgreSQL" || echo "✗ Backend → PostgreSQL"
docker exec mlsp-backend nc -z pgbouncer 6432 && echo "✓ Backend → PgBouncer" || echo "✗ Backend → PgBouncer"
docker exec mlsp-backend nc -z redis 6379 && echo "✓ Backend → Redis" || echo "✗ Backend → Redis"
docker exec mlsp-airflow-scheduler nc -z pgbouncer 6432 && echo "✓ Airflow → PgBouncer" || echo "✗ Airflow → PgBouncer"
echo ""

echo "=================================="
echo "HEALTH CHECK COMPLETE"
echo "=================================="
