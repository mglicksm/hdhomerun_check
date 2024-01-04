import os
import subprocess
import datetime
import tempfile
import platform

# Configuration and Initialization
hdhomerun_id = "1075247B"
hdhomerun_opt_get_tun3_sts = "get /tuner3/status"
hdhomerun_opt_set_tun3 = "set /tuner3/channel "
channel_array = ["auto:11", "auto:12", "auto:21", "auto:26", "auto:27", "auto:31", "none"]
channel_name_array = ["13.1", "11.1", "22.1", "45.1", "2.1", "26.1", "none"]


check_file_path = '/mnt/d/users/Michael/Programs/SiliconDust/HDHomeRun/hdhomerun_config.exe'

if os.path.exists(check_file_path):
    hostname = 'Neuron'
else:
    hostname = 'Other'

if hostname == 'Neuron':
    print("Running on Neuron")
    hdhomerun_config_cmd = "/mnt/d/users/Michael/Programs/SiliconDust/HDHomeRun/hdhomerun_config.exe"
    hdhomerun_db_data = "/mnt/c/users/Michael/hdhomerun_data.csv"
else:
    print("Not running on Neuron")
    hdhomerun_config_cmd = "/usr/bin/hdhomerun_config"
    hdhomerun_db_data = "/var/www/hdhomerun/hdhomerun_data.csv"

def run_cmd(command):
    print(f"{command}")
    result = subprocess.run(command, shell=True, text=True, capture_output=True)
    return result.stdout

def write_to_file(file_path, data):
    with open(file_path, 'a') as file:
        file.write(data + '\n')

# Create a temp file for config output
hdhomerun_config_tmp = tempfile.NamedTemporaryFile(suffix='.tmp', dir='/tmp', delete=False).name

try:
    #MJG - problem here, run_cmd isn't doing anything, maybe needs to be subprocess.run like below?
    #  Actually, run_cmd is defined above. 
    #  When I run on my own, the output is ch=none lock=none ss=0 snq=0 seq=0 bps=0 pps=0
    cur_chan = run_cmd(f"{hdhomerun_config_cmd} {hdhomerun_id} {hdhomerun_opt_get_tun3_sts}")
    cur_chan = cur_chan.strip().split('=')[1].replace('"', '')
    cur_chan = cur_chan.split(' ')[0]

    if cur_chan != "none":
        print(f"The channel is set to {cur_chan}, exiting 1")
        exit(1)

    if not os.path.exists(hdhomerun_db_data):
        write_to_file(hdhomerun_db_data, "channel,name,time,quality,strength,symbol")

    query_date = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    for idx, chan in enumerate(channel_array):
        subprocess.run(f"{hdhomerun_config_cmd} {hdhomerun_id} {hdhomerun_opt_set_tun3} {chan}", shell=True)
        chan_name = channel_name_array[idx]

        if chan != "none":
            os.remove(hdhomerun_config_tmp)
            run_cmd(f"{hdhomerun_config_cmd} {hdhomerun_id} {hdhomerun_opt_get_tun3_sts} >{hdhomerun_config_tmp}")

            with open(hdhomerun_config_tmp, 'r') as file:
                content = file.read()
                parts = content.strip().split()
                cur_chan, cur_ss, cur_snq, cur_seq = [part.split('=')[1].replace('"', '') for part in parts[:5]]

            data = f"{cur_chan},{chan_name},{query_date},{cur_snq},{cur_ss},{cur_seq}"
            write_to_file(hdhomerun_db_data, data)

    os.remove(hdhomerun_config_tmp)

finally:
    if os.path.exists(hdhomerun_config_tmp):
        os.remove(hdhomerun_config_tmp)
