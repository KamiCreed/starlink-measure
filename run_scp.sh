#!/bin/env bash
show_help() {
    echo "$0 [-n] path/to/dest_measurement_folder"
}

OPTIND=1 # Reset in case getopts has been used previously in the shell.

while getopts "h?n" opt; do
   case "$opt" in
      h|\?) # display Help
         show_help
         exit 0
         ;;
     n) # Turns off starting up instances
         no_instances=true
         ;;
   esac
done

shift $((OPTIND-1))

if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

# For raspberry pi crontab
if [[ "$(uname -m)" == "armv7l" ]]; then
    export PATH=/home/pi/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games
fi

dest_fold="$1"
MAX_RETRY=10

unique_fname() {
    name=$1
    count=1

    timestamp=$(date -u +"%Y-%m-%d_%H-%M-%S")
    fname="${name}.${timestamp}.csv"

    echo "$fname"
}

run_iperf() {
    instance_ip=$1
    dest_path="$2"
    region="$3"
    length=$4

    ( set -e # Subshell to exit on first error

    name="${dest_path}/${region}_scp"
    fname_down="$(unique_fname ${name}_down)"
    fname_up="$(unique_fname ${name}_up)"

    sizes=(1 10 100 500 1000)
    echo "Running SCP measurements"
    echo "region,1MB,10MB,100MB,500MB,1000MB" > "$fname_down"
    echo "region,1MB,10MB,100MB,500MB,1000MB" > "$fname_up"
    echo -n "${region}," >> "$fname_down"
    echo -n "${region}," >> "$fname_up"

    TIMEFORMAT='%R'
    fallocate -l 1M test_1M.img
    { time scp test_${sizes[0]}M.img terraform@${instance_ip}: ; } |& egrep ^[0-9]+.[0-9]+ | \
        tr '\n' ',' >> "$fname_up"

    for i in $(seq 0 $(expr ${#sizes[@]} - 1)); do 
        { time scp terraform@${instance_ip}:test_${sizes[i]}M.img . ; } |& egrep ^[0-9]+.[0-9]+ | \
            tr '\n' ',' >> "$fname_down" &
        
        next_id=$(expr ${i} + 1)
        forward=${sizes[next_id]}
        fallocate -l ${forward}M test_${forward}M.img
        { time scp test_${forward}M.img terraform@${instance_ip}: ; } |& egrep ^[0-9]+.[0-9]+ | \
            tr '\n' ',' >> "$fname_up"
        wait # In case download is slower
    done

    { time scp terraform@${instance_ip}:test_${sizes[-1]}M.img . ; } |& egrep ^[0-9]+.[0-9]+ | \
        tr -d '\n' >> "$fname_down"
    )
}

# 9 regions
regions=(ap-southeast-2 ap-southeast-1 ap-northeast-1 ap-south-1 eu-west-2 me-south-1 sa-east-1 us-west-1 af-south-1)
#regions=(ap-southeast-2 us-west-1)

./gen_main_tf.py "${regions[@]}"

#if [ "$no_instances" != true ]; then
#    (cd instances; terraform init)
#    (cd instances; terraform apply -auto-approve) # Long spin up of instances
#fi

#./run_ping.sh -n "${dest_fold}_ping" &

for region in "${regions[@]}"; do 
    instance_ip="$(cd instances; terraform output -raw ${region}_public_ip)"
    region_raw="$(cd instances; terraform output -raw ${region}_region_name)"

    region_no_spaces="${region_raw// /_}" # Replace spaces with underscores
    region_name="${region_no_spaces//[^[:alnum:]_]/}" # Remove special charas except underscores

    dest_path="${dest_fold}/${region_name}"
    echo "Saving to dir $dest_path"
    mkdir -p "${dest_path}"

    echo "Attempting to run iperf3 for $length seconds"

    err=1
    count=0
    until [ "$err" == 0 ] && [ "$count" -lt "$MAX_RETRY" ]; do
        # Must be run separately to properly exit the subshell upon error
        run_iperf "$instance_ip" "$dest_path" "$region" $length
        err=$?
        if [ "$err" != 0 ]; then
            echo "Error. Sleeping and trying again..."
            sleep 30
            echo "Restarting..."
            ((count++))
        fi
    done

    echo "Logged measurements to the following:"
    echo "$fname"

    if [ "$count" -ge "$MAX_RETRY" ]; then
        echo "ERROR: Max Retries reached. Quitting measurements."
    fi
done

if [ "$no_instances" != true ]; then
    (cd instances; terraform destroy -auto-approve)
fi
