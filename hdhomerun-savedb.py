import sys
import json
# from influxdb_client import InfluxDBClient, Point, WritePrecision
# from influxdb_client.client.write_api import SYNCHRONOUS
from influxdb import InfluxDBClient
from datetime import datetime
import pytz

# Ensure correct usage
if len(sys.argv) != 8:
    print("Usage: python3 hdhomerun-savedb.py <channel> <channel name> <date> <time> <signal_strength> <signal_quality> <symbol_quality>")
    print()
    sys.exit(1)

# print("args are " + sys.argv[0] + " 1=" + sys.argv[1] + " 2=" + sys.argv[2] + " 3=" + sys.argv[3] + " 4=" + sys.argv[4] + " 5=" + sys.argv[5] + " 6=" + sys.argv[6] + " 7=" + sys.argv[7])

# Extract arguments
channel, name, query_date, query_time, signal_quality, signal_strength, symbol_quality = sys.argv[1:8]

# convert the input time to a python time
time_string = query_date + " " + query_time
format = "%Y-%m-%d %H:%M:%S"

# Parse the time string into a datetime object assuming it's in EST
est = pytz.timezone('US/Eastern')
est_time = est.localize(datetime.strptime(time_string, format))

# Convert to UTC
utc_time = est_time.astimezone(pytz.utc)

# Convert arguments to a JSON object
antenna_data = [
    {
        "measurement" : "antenna_signal",
        "tags" : {
            "host": "Slam"
        },
        "fields" : {
            "channel": channel,
            "name": name, 
            "query_time": utc_time,
            "signal_quality": float(signal_quality),
            "signal_strength": float(signal_strength),
            "symbol_quality": float(symbol_quality)
        }
    }
]

# InfluxDB credentials and details
# url = "http://localhost:8086"
# token = "your_token"
# org = "your_organization"
# bucket = "your_bucket"

# Connect to InfluxDB
# client = InfluxDBClient(url=url, token=token, org=org)
client = InfluxDBClient('localhost', 8086, 'speedmonitor', 'yy78UUn&hh', 'antennasignal')
# write_api = client.write_api(write_options=SYNCHRONOUS)

# Create a point and write it to the database
# point = Point("signals").tag("location", "office").field("data", json.dumps(antenna_data)).time(datetime.utcnow(), WritePrecision.NS)
# write_api.write(bucket, org, point)

client.write_points(antenna_data)

# Close the client
client.close()

print("Data inserted successfully.")
