#!/bin/bash

set -e

# Database connection parameters
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_USER=${DB_USER:-postgres}
DB_PASSWORD=${DB_PASSWORD:-postgres}
DB_NAME=${DB_NAME:-smc_notificationservice}

echo "Connecting to database: $DB_HOST:$DB_PORT/$DB_NAME as $DB_USER"

# Create .pgpass file for authentication
PGPASS_FILE="/tmp/.pgpass"
cat > "$PGPASS_FILE" << EOF
$DB_HOST:$DB_PORT:$DB_NAME:$DB_USER:$DB_PASSWORD
EOF
chmod 600 "$PGPASS_FILE"

# Export PGPASSFILE for psql to use
export PGPASSFILE=$PGPASS_FILE

# Wait for database to be ready
max_attempts=30
attempt=1
while [ $attempt -le $max_attempts ]; do
  if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 1" > /dev/null 2>&1; then
    echo "Database is ready!"
    break
  fi
  echo "Waiting for database... (attempt $attempt/$max_attempts)"
  sleep 2
  attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
  echo "Failed to connect to database after $max_attempts attempts"
  rm -f "$PGPASS_FILE"
  exit 1
fi

# Run migrations
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

echo "All migrations completed successfully!"
