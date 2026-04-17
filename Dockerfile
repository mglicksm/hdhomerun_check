FROM python:3.11-slim-bookworm

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    cron \
    bc \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Copy the binary we just built on the host
COPY hdhomerun_config /usr/bin/hdhomerun_config
RUN chmod +x /usr/bin/hdhomerun_config

# Set up Python dependencies
RUN pip install influxdb pytz

# Set up the app directory
WORKDIR /app
COPY hdhomerun-check.sh hdhomerun-savedb.py ./
RUN chmod +x hdhomerun-check.sh

# Create the cron file
RUN echo "*/20 * * * * root /usr/local/bin/python3 /app/hdhomerun-check.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/hdhomerun-cron
RUN chmod 0644 /etc/cron.d/hdhomerun-cron && touch /var/log/cron.log

CMD ["cron", "-f"]