FROM python:3.9-slim-buster

# Fix for 404 errors: Point apt to the Debian Archive mirrors
RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i 's|security.debian.org/debian-security|archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    sed -i '/stretch-updates/d' /etc/apt/sources.list

# Now apt-get update will work because it's looking at the archives
RUN apt-get update && apt-get install -y \
    cron \
    bc \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Copy the binary you built on the host
COPY hdhomerun_config /usr/bin/hdhomerun_config
RUN chmod +x /usr/bin/hdhomerun_config

# Set up Python dependencies
RUN pip install influxdb pytz

WORKDIR /app
COPY hdhomerun-check.sh hdhomerun-savedb.py ./
RUN chmod +x hdhomerun-check.sh

# Create the cron file
RUN echo "*/20 * * * * root /usr/local/bin/python3 /app/hdhomerun-check.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/hdhomerun-cron
RUN chmod 0644 /etc/cron.d/hdhomerun-cron && touch /var/log/cron.log

CMD ["cron", "-f"]