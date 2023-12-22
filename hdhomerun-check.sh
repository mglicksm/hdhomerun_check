#!/bin/bash
set -e

# Slam 2023-06-12
# Check signal qualities for a list of channels using HDHomeRun config utility. 
# Current writes to a local CSV file. Eventually, Grafana! 
#
# TODO: Instead of one reading per channel, several readings per channel then average them. 
#
# 2023-12-22    Updated for Linux/Pi, added channel names, committed to Git
#

if [ $HOSTNAME = "Neuron" ]; then
    echo "Running on Neuron"
    hdhomerun_config_cmd=/mnt/d/users/Michael/Programs/SiliconDust/HDHomeRun/hdhomerun_config.exe
    hdhomerun_db_data=/mnt/c/users/Michael/hdhomerun_data.csv
else
    hdhomerun_config_cmd=/usr/bin/hdhomerun_config
    hdhomerun_db_data=/home/pi/Documents/hdhomerun_data.csv
fi
hdhomerun_id="1075247B"
hdhomerun_opt_get_tun3_sts="get /tuner3/status"
hdhomerun_opt_set_tun3="set /tuner3/channel "
channel_array=(auto:11 auto:12 auto:21 auto:26 auto:27 auto:31 none)
channel_name_array=("13.1" "11.1" "22.1" "45.1" "2.1" "26.1" none)

# echo "HDHomeRun check begins"

# Create a temp file for config output
hdhomerun_config_tmp=$(mktemp --tmpdir=/tmp --suffix=.tmp hdhomerun_XXXXXX)
trap "rm -rf ${hdhomerun_config_tmp}" EXIT

# Get tuner status, should be none to start
# echo "About to run ${hdhomerun_config_cmd} to file ${hdhomerun_config_tmp}"
${hdhomerun_config_cmd} ${hdhomerun_id} ${hdhomerun_opt_get_tun3_sts}  >${hdhomerun_config_tmp}

cur_chan=$(cat ${hdhomerun_config_tmp} | awk '{print $1}'| awk -F "=" '{print $2}' |tr -d \" )

# Check if channel is none and exit if not
if [ "${cur_chan}" != "none" ]; then
    echo "The channel is set to ${cur_chan}, exiting 1"    
    exit 1
fi

# Put the column headers if the file doesn't exist
if [ ! -f  ${hdhomerun_db_data} ]; then
    echo "channel,time,quality,strength,symbol" > ${hdhomerun_db_data}
fi

# Log all data on the same date/time
query_date=$(date '+%Y-%m-%d %H:%M:%S')

name_idx=0

for chan in "${channel_array[@]}"
do
    # proceed to set the tuner
    #echo "The channel is none"
    #echo "Setting a channel, but no output"
    #echo "Setting to channel ${chan}"
    ${hdhomerun_config_cmd} ${hdhomerun_id} ${hdhomerun_opt_set_tun3} ${chan}

    chan_name=${channel_name_array[name_idx]}
    name_idx=$((name_idx+1))

    sleep 3 # No valid signal strength until we sleep

    # Going to do 'none' last so for real channels we want to record signal
    if [ "${chan}" != "none" ]; then

        # Check the status of the tuner
        # echo "Getting new channel status"
        rm -f ${hdhomerun_config_tmp}   # We reuse this file name because it's only generated at the top
        ${hdhomerun_config_cmd} ${hdhomerun_id} ${hdhomerun_opt_get_tun3_sts}  >${hdhomerun_config_tmp}

        #cat ${hdhomerun_config_tmp}
        cur_chan=$(cat ${hdhomerun_config_tmp} | awk '{print $1}' | awk -F "=" '{print $2}' | tr -d \" )
        cur_ss=$(cat ${hdhomerun_config_tmp} | awk '{print $3}' | awk -F "=" '{print $2}' |tr -d \" )
        cur_snq=$(cat ${hdhomerun_config_tmp} | awk '{print $4}' | awk -F "=" '{print $2}' |tr -d \" )
        cur_seq=$(cat ${hdhomerun_config_tmp} | awk '{print $5}' | awk -F "=" '{print $2}' |tr -d \" )

        # channel, date/time, quality, strength, sympol
        echo "${cur_chan},${chan_name},${query_date},${cur_snq},${cur_ss},${cur_seq}" >> ${hdhomerun_db_data}
    fi
done

# Check that it is none again 
rm -f ${hdhomerun_config_tmp}   # We reuse this file name because it's only generated at the top
${hdhomerun_config_cmd} ${hdhomerun_id} ${hdhomerun_opt_get_tun3_sts}  >${hdhomerun_config_tmp}

cur_chan=$(cat ${hdhomerun_config_tmp} | awk '{print $1}' | awk -F "=" '{print $2}' |tr -d \" )
rm -f ${hdhomerun_config_tmp}

# Check if channel is none and exit if not
if [ "${cur_chan}" != "none" ]; then
    echo "The channel is set to ${cur_chan} when it should be none, exiting 1"    
    exit 1
fi

#rm -f ${hdhomerun_config_tmp}
exit 0