#!/bin/env bash
if [ $# -eq 0 ]; then
    echo "Please supply destination folder"
    exit 1
fi

# For raspberry pi crontab
if [[ "$(uname -m)" == "armv7l" ]]; then
    export PATH=/home/pi/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games
fi

dest_fold="$1"
length=30
CLIENT=client
SERVER=server

unique_fname() {
    name=$1
    count=1

    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    fname="${name}.${timestamp}.log"

    echo "$fname"
}

run_iperf() {
    instance_ip=$1
    fname_down="$2"
    fname_up="$3"
    fname_down_udp="$4"
    fname_up_udp="$5"
    length=$6

    ( set -e # Subshell to exit on first error

    echo "Running TCP measurements"
    iperf3 -c "$instance_ip" -R -Z -t $length -P 4 -J > "$fname_down" & 
    iperf3 -c "$instance_ip" -p 5202 -Z -t $length -P 4 -J > "$fname_up"
    wait

    echo "Running UDP measurements"
    iperf3 -c "$instance_ip" -R -Z -t $length -u -b 65M -P 4 -J > "$fname_down_udp" & 
    iperf3 -c "$instance_ip" -p 5202 -Z -t $length -u -b 7M -P 4 -J > "$fname_up_udp"
    wait
    )
}

regions=(ap-southeast-2 ap-southeast-1 ap-northeast-1 ap-south-1 eu-west-2 me-south-1 sa-east-1 us-west-1)
#regions=(ap-southeast-2 us-west-1)

./gen_main_tf.py "${regions[@]}"

(cd instances; terraform init)
(cd instances; terraform apply -auto-approve) # Long spin up of instances

for region in "${regions[@]}"; do 
    instance_ip="$(cd instances; terraform output -raw ${region}_public_ip)"
    region_raw="$(cd instances; terraform output -raw ${region}_region_name)"

    region_no_spaces="${region_raw// /_}" # Replace spaces with underscores
    region_name="${region_no_spaces//[^[:alnum:]_]/}" # Remove special charas except underscores

    dest_path="${dest_fold}/${region_name}/${CLIENT}"
    echo "Saving to dir $dest_path"
    mkdir -p "${dest_path}"
    name="${dest_path}/${region}_throughput_client_p4"

    echo "Attempting to run iperf3 for $length seconds"

    fname_down="$(unique_fname ${name}_down)"
    fname_up="$(unique_fname ${name}_up)"
    fname_down_udp="$(unique_fname ${name}_down_udp)"
    fname_up_udp="$(unique_fname ${name}_up_udp)"
    err=1
    until [ "$err" == 0 ]; do
        # Must be run separately to properly exit the subshell upon error
        run_iperf "$instance_ip" "$fname_down" "$fname_up" "$fname_down_udp" "$fname_up_udp" $length
        err=$?
        if [ "$err" != 0 ]; then
            echo "Error. Sleeping and trying again..."
            sleep 30
            echo "Starting..."
        fi
    done

    echo "Logged measurements to the following:"
    echo "$fname_down"
    echo "$fname_up"

    ssh_host="terraform@${instance_ip}"
    dest_server_path="${dest_fold}/${region_name}/${SERVER}/"
    mkdir -p "$dest_server_path"
    scp -o "StrictHostKeyChecking=accept-new" ${ssh_host}:*.log "$dest_server_path"
done

(cd instances; terraform destroy -auto-approve)
