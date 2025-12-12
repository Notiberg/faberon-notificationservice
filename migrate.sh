#!/bin/bash

set -e

# Database connection parameters
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_USER=${DB_USER:-postgres}
DB_PASSWORD=${DB_PASSWORD:-postgres}
DB_NAME=${DB_NAME:-smc_notificationservice}

echo "=== Database Migration Script ==="
echo "DB_HOST: $DB_HOST"
echo "DB_PORT: $DB_PORT"
echo "DB_USER: $DB_USER"
echo "DB_NAME: $DB_NAME"
echo "DB_PASSWORD length: ${#DB_PASSWORD}"
if [ -z "$DB_PASSWORD" ]; then
  echo "WARNING: DB_PASSWORD is empty!"
fi
echo "==================================="
echo ""

# Create .pgpass file for authentication
PGPASS_FILE="/tmp/.pgpass"
cat > "$PGPASS_FILE" << EOF
$DB_HOST:$DB_PORT:*:$DB_USER:$DB_PASSWORD
EOF
chmod 600 "$PGPASS_FILE"

# Export PGPASSFILE for psql to use
export PGPASSFILE=$PGPASS_FILE

# Wait for database server to be ready
max_attempts=30
attempt=1
echo "Waiting for PostgreSQL server to be ready..."
while [ $attempt -le $max_attempts ]; do
  if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "SELECT 1" > /dev/null 2>&1; then
    echo "PostgreSQL server is ready!"
    break
  fi
  echo "Waiting for PostgreSQL server... (attempt $attempt/$max_attempts)"
  sleep 2
  attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
  echo "Failed to connect to PostgreSQL server after $max_attempts attempts"
  rm -f "$PGPASS_FILE"
  exit 1
fi

# Create database if it doesn't exist
echo "Checking if database '$DB_NAME' exists..."
if ! psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" 2>/dev/null | grep -q 1; then
  echo "Database '$DB_NAME' does not exist. Creating it..."
  psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "CREATE DATABASE $DB_NAME;"
  echo "Database '$DB_NAME' created successfully!"
else
  echo "Database '$DB_NAME' already exists."
fi

# Run migrations
echo ""
echo "Running migrations..."
for f in ./migrations/*.up.sql; do
  if [ -f "$f" ]; then
    echo "Executing: $f"
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$f"
    if [ $? -eq 0 ]; then
      echo "✓ $f completed successfully"
    else
      echo "✗ $f failed"
      rm -f "$PGPASS_FILE"
      exit 1
    fi
  fi
done

# Clean up
rm -f "$PGPASS_FILE"

echo ""
echo "All migrations completed successfully!"
