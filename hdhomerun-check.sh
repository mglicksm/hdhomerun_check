#!/bin/bash
set -e

# Slam 2023-06-12
# Check signal qualities for a list of channels using HDHomeRun config utility. 
# Current writes to a local CSV file. Eventually, Grafana! 
#
# TODO: Instead of one reading per channel, several readings per channel then average them. 
#
# 2023-12-22    Updated for Linux/Pi, added channel names, committed to Git
# 2024-01-03    Loop 3 times for each channel and average the reading
# 2024-01-09    Increased to sleep 5 seconds during the loop, between reads of a channel
# 2024-01-10    Added InfluxDB support
# 2026-04-17    Make it run in docker
# 

# Updated for Dockerized Home Lab Environment
# Uses Environment Variables for ID and Tuner selection

# Use Environment Variables with defaults if not provided
hdhomerun_id=${HDHOMERUN_ID:-"1075247B"}
tuner=${HDHOMERUN_TUNER:-"tuner3"}

# Internal container paths
hdhomerun_config_cmd=/usr/bin/hdhomerun_config
hdhomerun_db_data=/data/hdhomerun_data.csv
python_exe=/usr/local/bin/python3
db_script=/app/hdhomerun-savedb.py

# Dynamic options based on chosen tuner
hdhomerun_opt_get_tun_sts="get /${tuner}/status"
hdhomerun_opt_set_tun="set /${tuner}/channel "

# Channels to monitor
channel_array=(auto:11 auto:12 auto:21 auto:26 auto:27 auto:31 none)
channel_name_array=("13.1" "11.1" "22.1" "45.1" "2.1" "26.1" none)

# Create a temp file for config output
hdhomerun_config_tmp=$(mktemp --tmpdir=/tmp --suffix=.tmp hdhomerun_XXXXXX)
trap "rm -rf ${hdhomerun_config_tmp}" EXIT

# Verify tuner is available (should be 'none')
${hdhomerun_config_cmd} ${hdhomerun_id} ${hdhomerun_opt_get_tun_sts} >${hdhomerun_config_tmp}
cur_chan=$(cat ${hdhomerun_config_tmp} | awk '{print $1}'| awk -F "=" '{print $2}' |tr -d \" )

if [ "${cur_chan}" != "none" ]; then
    echo "Tuner ${tuner} is currently set to ${cur_chan}, exiting to avoid interrupting recording."    
    exit 1
fi

# Initialize CSV headers if file is new
if [ ! -f  ${hdhomerun_db_data} ]; then
    echo "channel,name,time,quality,strength,symbol" > ${hdhomerun_db_data}
fi

query_date=$(date '+%Y-%m-%d %H:%M:%S')
name_idx=0

for chan in "${channel_array[@]}"
do
    # Set the tuner to the target channel
    ${hdhomerun_config_cmd} ${hdhomerun_id} ${hdhomerun_opt_set_tun} ${chan}

    chan_name=${channel_name_array[name_idx]}
    name_idx=$((name_idx+1))

    # Wait for signal lock
    sleep 3 

    if [ "${chan}" != "none" ]; then
        sum_ss=0
        sum_snq=0
        sum_seq=0

        # Loop 3 times and average for better accuracy
        for i in $(seq 1 3);
        do
            sleep 5 
            ${hdhomerun_config_cmd} ${hdhomerun_id} ${hdhomerun_opt_get_tun_sts} >${hdhomerun_config_tmp}

            cur_chan=$(cat ${hdhomerun_config_tmp} | awk '{print $1}' | awk -F "=" '{print $2}' | tr -d \" )
            cur_ss=$(cat ${hdhomerun_config_tmp} | awk '{print $3}' | awk -F "=" '{print $2}' |tr -d \" )
            cur_snq=$(cat ${hdhomerun_config_tmp} | awk '{print $4}' | awk -F "=" '{print $2}' |tr -d \" )
            cur_seq=$(cat ${hdhomerun_config_tmp} | awk '{print $5}' | awk -F "=" '{print $2}' |tr -d \" )

            sum_ss=$((sum_ss + cur_ss))
            sum_snq=$((sum_snq + cur_snq))
            sum_seq=$((sum_seq + cur_seq))
        done

        # Calculate means using bc
        mean_ss=$(echo "scale=2; 1.0 * $sum_ss / 3" | bc -l)
        mean_snq=$(echo "scale=2; 1.0 * $sum_snq / 3" | bc -l)
        mean_seq=$(echo "scale=2; 1.0 * $sum_seq / 3" | bc -l)

        # Write to local CSV
        echo "${cur_chan},${chan_name},${query_date},${mean_snq},${mean_ss},${mean_seq}" >> ${hdhomerun_db_data}

        # Push to InfluxDB via Python script
        ${python_exe} ${db_script} ${cur_chan} ${chan_name} ${query_date} ${mean_snq} ${mean_ss} ${mean_seq}
    fi
done

# Ensure tuner is released
${hdhomerun_config_cmd} ${hdhomerun_id} ${hdhomerun_opt_set_tun} none

exit 0