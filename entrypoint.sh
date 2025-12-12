#!/bin/bash
set -e

echo "Running database migrations..."
./migrate.sh

echo "Starting application..."
exec ./main
