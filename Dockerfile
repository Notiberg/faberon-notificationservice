# SMC-NotificationService Dockerfile
# This Dockerfile automatically runs database migrations before starting the application
# Required environment variables:
# - DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME, DB_SSLMODE
# - TELEGRAM_BOT_TOKEN
# See RAILWAY_DEPLOYMENT.md for full configuration

# Build stage
FROM golang:1.25-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./cmd/main.go

# Final stage
FROM alpine:latest

WORKDIR /app

# Install PostgreSQL client for migrations and bash
RUN apk add --no-cache postgresql-client bash

# Copy binary from builder
COPY --from=builder /app/main .

# Copy config file
COPY --from=builder /app/config.toml .

# Copy migration scripts
COPY migrations/ ./migrations/
COPY migrate.sh ./

# Make migrate.sh executable
RUN chmod +x ./migrate.sh

# Create logs directory
RUN mkdir -p /app/logs

# Expose port
EXPOSE 8085

# Create entrypoint script that runs migrations then starts the app
RUN echo '#!/bin/bash\nset -e\necho "Running database migrations..."\n./migrate.sh\necho "Starting application..."\nexec ./main' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

# Run the application with entrypoint
CMD ["/app/entrypoint.sh"]
