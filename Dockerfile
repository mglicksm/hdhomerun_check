# Stage 1: Build hdhomerun_config
FROM python:3.11-slim-bookworm AS builder
RUN apt-get update && apt-get install -y git make gcc libc6-dev
WORKDIR /build
RUN git clone https://github.com/Silicondust/libhdhomerun.git .
RUN make

# Stage 2: Final Image
FROM python:3.11-slim-bookworm
RUN apt-get update && apt-get install -y \
    cron \
    bc \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Copy the compiled binary from the builder stage
COPY --from=builder /build/hdhomerun_config /usr/bin/hdhomerun_config

# Set up Python dependencies
RUN pip install influxdb pytz

# Set up the app directory
WORKDIR /app
COPY hdhomerun-check.sh hdhomerun-savedb.py ./
RUN chmod +x hdhomerun-check.sh

# Create the cron file
RUN echo "*/20 * * * * root /usr/local/bin/python3 /app/hdhomerun-check.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/hdhomerun-cron
RUN chmod 0644 /etc/cron.d/hdhomerun-cron && touch /var/log/cron.log

# Start cron in the foreground
CMD ["cron", "-f"]