#!/bin/env bash
set -e

unique_fname() {
    count=1
    name=$1
    fname="${name}.${count}.log"

    while [ -e "$fname" ]; do
        printf -v fname '%s.%02d.log' "$fname" "$(( ++count ))"
    done
}

#regions=(ap-southeast-2 ap-southeast-1 ap-northeast-1 eu-west-2 us-west-1)
regions=(ap-southeast-2 us-west-1)

for region in "${regions[@]}"; do 
    terraform apply -auto-approve -var "$region"

    name_down="dust-${region}-throughput-client-p4-down.1"
    name_up="dust-${region}-throughput-client-p4-up.1"
    iperf3 -c "$(terraform output -raw public_ip)" -R -Z -t 10 -P 4 -J > "$(unique_fname $name_down)" &
    iperf3 -c "$(terraform output -raw public_ip)" -p 5202 -Z -t 10 -P 4 -J > "$(unique_fname $name_up)"
    fg || true # Just in case the first one lags behind
    terraform destroy -auto-approve -var "$region"
done
