#!/bin/env bash
set -e

if [ $# -eq 0 ]; then
    echo "Please supply destination folder"
    exit 1
fi
dest_fold="$1"
length=600

unique_fname() {
    count=1
    name=$1
    fname="${name}.${count}.log"

    while [ -e "$fname" ]; do
        printf -v fname '%s.%02d.log' "$name" "$(( ++count ))"
    done

    echo "$fname"
}

run_iperf() {
    fname_down="$1"
    fname_up="$2"
    length=$3

    iperf3 -c "$instance_ip" -R -Z -t $length -P 4 -J > "$fname_down" & 
    iperf3 -c "$instance_ip" -p 5202 -Z -t $length -P 4 -J > "$fname_up"
}

regions=(ap-southeast-2 ap-southeast-1 ap-northeast-1 ap-south-1 eu-west-2 me-south-1 sa-east-1 us-west-1)
#regions=(ap-southeast-2 us-west-1)

for region in "${regions[@]}"; do 
    (cd instances; terraform apply -auto-approve -var "region=$region" || true)
    instance_ip="$(cd instances; terraform output -raw public_ip)"
    region_raw="$(cd instances; terraform output -raw region_name)"

    region_no_spaces="${region_raw// /_}" # Replace spaces with underscores
    region_name="${region_no_spaces//[^[:alnum:]_]/}" # Remove special charas except underscores

    dest_path="${dest_fold}/${region_name}"
    echo "Saving to dir $dest_path"
    mkdir "${dest_path}"
    name_down="${dest_path}/${region}_throughput_client_p4_down"
    name_up="${dest_path}/${region}_throughput_client_p4_up"

    echo "Attempting to run iperf3 for $length seconds"

    fname_down="$(unique_fname $name_down)"
    fname_up="$(unique_fname $name_up)"
    until run_iperf "$fname_down" "$fname_up" $length; do
        echo "Sleeping and trying again..."
        sleep 30
    done
    fg 2>/dev/null || true # Just in case the first one lags behind

    echo "Logged measurements to the following:"
    echo "$fname_down"
    echo "$fname_up"
done

(cd instances; terraform destroy -auto-approve -var "region=${regions[-1]}")
