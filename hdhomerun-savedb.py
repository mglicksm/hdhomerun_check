import sys
import json
# from influxdb_client import InfluxDBClient, Point, WritePrecision
# from influxdb_client.client.write_api import SYNCHRONOUS
from influxdb import InfluxDBClient

# Ensure correct usage
if len(sys.argv) != 8:
    print("Usage: python3 hdhomerun-savedb.py <channel> <channel name> <date> <time> <signal_strength> <signal_quality> <symbol_quality>")
    print()
    sys.exit(1)

print("args are " + sys.argv[0] + " " + sys.argv[1] + " " + sys.argv[2] + " " + sys.argv[3] + " " + sys.argv[4] + " " + sys.argv[5] + " " + sys.argv[6])


# Extract arguments
channel, name, query_date, query_time, signal_quality, signal_strength, symbol_quality = sys.argv[1:7]
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
            "time": query_date + " " + query_time,
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
