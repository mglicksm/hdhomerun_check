# Stage 1: Build hdhomerun_config
FROM python:3.11-alpine AS builder
# Install build dependencies for Alpine
RUN apk add --no-cache git make gcc libc-dev
WORKDIR /build
RUN git clone https://github.com/Silicondust/libhdhomerun.git .
RUN make

# Stage 2: Final Image
FROM python:3.11-alpine
# Install runtime dependencies: cronie (modern cron), bc (math), procps (process management)
RUN apk add --no-cache \
    cronie \
    bc \
    procps

# Copy the compiled binary from the builder stage
COPY --from=builder /build/hdhomerun_config /usr/bin/hdhomerun_config

# Set up Python dependencies
RUN pip install --no-cache-dir influxdb pytz

# Set up the app directory
WORKDIR /app
COPY hdhomerun-check.sh hdhomerun-savedb.py ./
RUN chmod +x hdhomerun-check.sh

# Alpine uses /etc/crontabs/root instead of /etc/cron.d/
RUN echo "*/20 * * * * /usr/local/bin/python3 /app/hdhomerun-check.sh >> /var/log/cron.log 2>&1" > /etc/crontabs/root
RUN touch /var/log/cron.log

# Start cron in the foreground (-n for Alpine's crond)
CMD ["crond", "-f", "-l", "2"]