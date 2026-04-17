import sys
import json
from influxdb import InfluxDBClient
from datetime import datetime
import pytz
import os

# Ensure correct usage
if len(sys.argv) != 8:
    print("Usage: python3 hdhomerun-savedb.py <channel> <channel name> <date> <time> <signal_quality> <signal_strength> <symbol_quality>")
    sys.exit(1)

# Extract arguments from the shell script
channel, name, query_date, query_time, signal_quality, signal_strength, symbol_quality = sys.argv[1:8]

# Convert the input time to a python time
time_string = f"{query_date} {query_time}"
time_format = "%Y-%m-%d %H:%M:%S"

# Parse the time string into a datetime object assuming it's in EST
est = pytz.timezone('US/Eastern')
try:
    est_time = est.localize(datetime.strptime(time_string, time_format))
    # Convert to UTC for InfluxDB standard storage
    utc_time = est_time.astimezone(pytz.utc)
except ValueError as e:
    print(f"Error parsing date/time: {e}")
    sys.exit(1)

# Convert arguments to an InfluxDB point object
antenna_data = [
    {
        "measurement" : "antenna_signal",
        "tags" : {
            "host": "Slam"
        },
        "time": utc_time.strftime('%Y-%m-%dT%H:%M:%SZ'),
        "fields" : {
            "channel": channel,
            "name": name, 
            "query_time": time_string,
            "signal_quality": float(signal_quality),
            "signal_strength": float(signal_strength),
            "symbol_quality": float(symbol_quality)
        }
    }
]

# InfluxDB Connection Configuration
# Host 'influxdb' matches the service name in your docker-compose.yml
INFLUX_HOST = os.getenv('INFLUX_HOST', 'influxdb')
INFLUX_PORT = 8086
INFLUX_USER = 'speedmonitor'
INFLUX_PASS = 'yy78UUn&hh'  # Consider moving this to an Env Var in docker