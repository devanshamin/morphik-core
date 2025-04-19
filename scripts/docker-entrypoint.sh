#!/bin/bash
set -e

# Function to check PostgreSQL
check_postgres() {
    if [ -n "$POSTGRES_URI" ]; then
        echo "Waiting for PostgreSQL..."
        max_retries=30
        retries=0
        until PGPASSWORD=$PGPASSWORD pg_isready -h postgres -U morphik -d morphik; do
            retries=$((retries + 1))
            if [ $retries -eq $max_retries ]; then
                echo "Error: PostgreSQL did not become ready in time"
                exit 1
            fi
            echo "Waiting for PostgreSQL... (Attempt $retries/$max_retries)"
            sleep 2
        done
        echo "PostgreSQL is ready!"

        # Verify database connection
        if ! PGPASSWORD=$PGPASSWORD psql -h postgres -U morphik -d morphik -c "SELECT 1" > /dev/null 2>&1; then
            echo "Error: Could not connect to PostgreSQL database"
            exit 1
        fi
        echo "PostgreSQL connection verified!"
    fi
}

# Check PostgreSQL
check_postgres

# Start appropriate process based on RUN_MODE
if [ "$RUN_MODE" = "worker" ]; then
    echo "Starting ARQ worker..."
    exec arq core.workers.ingestion_worker.WorkerSettings
else
    echo "Starting API server..."
    exec uvicorn core.api:app --host $HOST --port $PORT --loop asyncio --http auto --ws auto --lifespan auto
fi
