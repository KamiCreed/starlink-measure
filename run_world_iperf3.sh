#!/bin/env bash
set -e

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
    length=10

    iperf3 -c "$instance_ip" -R -Z -t $length -P 4 -J > "$fname_down" & 
    iperf3 -c "$instance_ip" -p 5202 -Z -t $length -P 4 -J > "$fname_up"
}

#regions=(ap-southeast-2 ap-southeast-1 ap-northeast-1 eu-west-2 us-west-1)
regions=(ap-southeast-2 us-west-1)

for region in "${regions[@]}"; do 
    (cd instances; terraform apply -auto-approve -var "region=$region" || true)
    instance_ip="$(cd instances; terraform output -raw public_ip)"

    name_down="${region}/dust-${region}-throughput-client-p4-down"
    name_up="${region}/dust-${region}-throughput-client-p4-up"

    fname_down="$(unique_fname $name_down)"
    fname_up="$(unique_fname $name_up)"
    until run_iperf "$fname_down" "$fname_up"; do
        echo "Sleeping and trying again..."
        sleep 30
    done
    fg || true # Just in case the first one lags behind

    (cd instances; terraform destroy -auto-approve -var "region=$region")
done
