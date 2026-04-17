# Match the base image to your Pi's Host OS (Buster)
FROM python:3.9-slim-buster

# Install runtime dependencies
# This will now work because the GPG keys match your host's libseccomp version
RUN apt-get update && apt-get install -y \
    cron \
    bc \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Copy the binary you built on the host
# Ensure hdhomerun_config is in the same folder as this Dockerfile
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

# Start cron
CMD ["cron", "-f"]