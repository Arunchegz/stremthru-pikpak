FROM golang:1.25 AS builder

WORKDIR /workspace

# Download dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy project files
COPY migrations ./migrations
COPY core ./core
COPY internal ./internal
COPY store ./store
COPY stremio ./stremio
COPY *.go ./

# Build the binary
RUN CGO_ENABLED=1 GOOS=linux go build --tags 'fts5' -o ./stremthru -a \
    -ldflags '-linkmode external -extldflags "-static"'

# ---------------- Runtime image ----------------
FROM alpine

RUN apk add --no-cache git

WORKDIR /app

# Create required data directory (fixes Koyeb crash)
RUN mkdir -p /app/data

# Copy built binary
COPY --from=builder /workspace/stremthru ./stremthru

# Declare volume for optional persistence
VOLUME ["/app/data"]

ENV STREMTHRU_ENV=prod

EXPOSE 8080

ENTRYPOINT ["./stremthru"]