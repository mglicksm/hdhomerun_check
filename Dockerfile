FROM python:3.9-slim-buster

# 1. Fix Archive URLs for Buster
RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i 's|security.debian.org/debian-security|archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    sed -i '/stretch-updates/d' /etc/apt/sources.list

# 2. Install dependencies (added gcc and python3-dev for msgpack)
RUN apt-get update && apt-get install -y \
    cron \
    bc \
    procps \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# 3. Copy the binary you built on the host
COPY hdhomerun_config /usr/bin/hdhomerun_config
RUN chmod +x /usr/bin/hdhomerun_config

# 4. Install Python libraries
RUN pip install --no-cache-dir influxdb pytz

# 5. App Setup
WORKDIR /app
COPY hdhomerun-check.sh hdhomerun-savedb.py ./
RUN chmod +x hdhomerun-check.sh

# 6. Cron Configuration
RUN echo "*/20 * * * * root /usr/local/bin/python3 /app/hdhomerun-check.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/hdhomerun-cron
RUN chmod 0644 /etc/cron.d/hdhomerun-cron && touch /var/log/cron.log

CMD ["cron", "-f"]