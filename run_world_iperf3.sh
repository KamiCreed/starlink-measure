#!/bin/env bash
set -e

if [ $# -eq 0 ]; then
    echo "Please supply destination folder"
    exit 1
fi
dest_fold="$1"
length=30
CLIENT=client
SERVER=server

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
    set -e

    fname_down="$1"
    fname_up="$2"
    fname_down_udp="$3"
    fname_up_udp="$4"
    length=$5

    # TCP
    iperf3 -c "$instance_ip" -R -Z -t $length -P 4 -J > "$fname_down" & 
    iperf3 -c "$instance_ip" -p 5202 -Z -t $length -P 4 -J > "$fname_up"
    wait

    # UDP
    iperf3 -c "$instance_ip" -R -Z -t $length -P 4 -J > "$fname_down_udp" & 
    iperf3 -c "$instance_ip" -p 5202 -Z -t $length -P 4 -J > "$fname_up_udp"
    wait
}

regions=(ap-southeast-2 ap-southeast-1 ap-northeast-1 ap-south-1 eu-west-2 me-south-1 sa-east-1 us-west-1)
#regions=(ap-southeast-2 us-west-1)

for region in "${regions[@]}"; do 
    if [ "$region" = 'me-south-1' ]; then
        (cd instances; terraform apply -auto-approve -var "region=$region" -var "instance_type=t3.micro")
    else
        (cd instances; terraform apply -auto-approve -var "region=$region")
    fi

    instance_ip="$(cd instances; terraform output -raw public_ip)"
    region_raw="$(cd instances; terraform output -raw region_name)"

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
    until run_iperf "$fname_down" "$fname_up" "$fname_down_udp" "$fname_up_udp" $length; do
        echo "Error. Sleeping and trying again..."
        sleep 30
        echo "Starting..."
    done
    wait || true # Just in case the first one lags behind

    echo "Logged measurements to the following:"
    echo "$fname_down"
    echo "$fname_up"

    ssh_host="terraform@${instance_ip}"
    dest_server_path="${dest_fold}/${region_name}/${SERVER}/"
    mkdir -p "$dest_server_path"
    scp ${ssh_host}:*.log "$dest_server_path"

    if [ region = 'me-south-1' ]; then
        (cd instances; terraform destroy -auto-approve -var "region=$region" -var "instance_type=t3.micro")
    else
        (cd instances; terraform destroy -auto-approve -var "region=$region")
    fi
done
