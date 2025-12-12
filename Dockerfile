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

# Install PostgreSQL client for migrations
RUN apk add --no-cache postgresql-client

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

# Run the application
CMD ["./main"]
