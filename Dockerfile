FROM golang:1.24.1-alpine AS builder
WORKDIR /app

# Copy go mod files first for better caching
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Tidy dependencies to fix any inconsistencies
RUN go mod tidy

# Build the application
RUN GOGC=off CGO_ENABLED=0 GOOS=linux go build -v -o prometheus_bot

FROM alpine:3.21 as alpine
RUN apk add --no-cache ca-certificates tzdata

FROM scratch
EXPOSE 9087
WORKDIR /

# Copy necessary files from alpine
COPY --from=alpine /etc/passwd /etc/group /etc/
COPY --from=alpine /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=alpine /usr/share/zoneinfo /usr/share/zoneinfo

# Copy the built binary
COPY --from=builder /app/prometheus_bot /prometheus_bot

# Use nobody user for security
USER nobody

# Run the application
CMD ["/prometheus_bot"]