#!/usr/bin/env bash

set -euo pipefail

cd /app/backend

echo "Running Alembic migrations..."
alembic upgrade head

echo "Creating initial data..."
python scripts/initial_data.py

echo "Database initialization completed."