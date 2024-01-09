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
# 
#

if [ $HOSTNAME = "Neuron" ]; then
    echo "Running on Neuron"
    hdhomerun_config_cmd=/mnt/d/users/Michael/Programs/SiliconDust/HDHomeRun/hdhomerun_config.exe
    hdhomerun_db_data=/mnt/c/users/Michael/hdhomerun_data.csv
else
    hdhomerun_config_cmd=/usr/bin/hdhomerun_config
    hdhomerun_db_data=/var/www/hdhomerun/hdhomerun_data.csv
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
    echo "channel,name,time,quality,strength,symbol" > ${hdhomerun_db_data}
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

        sum_ss=0
        sum_snq=0
        sum_seq=0
        mean_ss=0
        mean_snq=0
        mean_seq=0

        for i in $(seq 1 3);
        do
            # Check the status of the tuner
            # echo "Getting new channel status"
            sleep 5 # Sleep between reads
            rm -f ${hdhomerun_config_tmp}   # We reuse this file name because it's only generated at the top
            ${hdhomerun_config_cmd} ${hdhomerun_id} ${hdhomerun_opt_get_tun3_sts}  >${hdhomerun_config_tmp}

            #cat ${hdhomerun_config_tmp}
            cur_chan=$(cat ${hdhomerun_config_tmp} | awk '{print $1}' | awk -F "=" '{print $2}' | tr -d \" )
            cur_ss=$(cat ${hdhomerun_config_tmp} | awk '{print $3}' | awk -F "=" '{print $2}' |tr -d \" )
            cur_snq=$(cat ${hdhomerun_config_tmp} | awk '{print $4}' | awk -F "=" '{print $2}' |tr -d \" )
            cur_seq=$(cat ${hdhomerun_config_tmp} | awk '{print $5}' | awk -F "=" '{print $2}' |tr -d \" )

            sum_ss=$((sum_ss + cur_ss))
            sum_snq=$((sum_snq + cur_snq))
            sum_seq=$((sum_seq + cur_seq))

        done

        mean_ss=$(echo "scale=2; 1.0 * $sum_ss / 3" | bc -l)
        mean_snq=$(echo "scale=2; 1.0 * $sum_snq / 3" | bc -l)
        mean_seq=$(echo "scale=2; 1.0 * $sum_seq / 3" | bc -l)

        # echo "${cur_chan},${chan_name},${query_date},${sum_snq},${sum_ss},${sum_seq}
        # echo "${cur_chan},${chan_name},${query_date},${mean_snq},${mean_ss},${mean_seq}

        # channel, name, date/time, quality, strength, symbol
        # echo "${cur_chan},${chan_name},${query_date},${cur_snq},${cur_ss},${cur_seq}" >> ${hdhomerun_db_data}
        echo "${cur_chan},${chan_name},${query_date},${mean_snq},${mean_ss},${mean_seq}"
        echo "${cur_chan},${chan_name},${query_date},${mean_snq},${mean_ss},${mean_seq}" >> ${hdhomerun_db_data}

        if [ $HOSTNAME != "Neuron" ]; then
            python3 hdhomerun-savedb.py ${cur_chan} ${chan_name} ${mean_snq} ${mean_ss} ${mean_seq}
        fi
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