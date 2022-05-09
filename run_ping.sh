#!/bin/env bash
if [ $# -eq 0 ]; then
    echo "Please supply destination folder"
    exit 1
fi

dest_fold="$1"

unique_fname() {
    name=$1
    count=1

    timestamp=$(date -u +"%Y-%m-%d_%H-%M-%S")
    fname="${name}.${timestamp}.csv"

    echo "$fname"
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

    dest_path="${dest_fold}/${region_name}"
    echo "Saving to dir $dest_path"
    mkdir -p "${dest_path}"

    name="${dest_path}/ping"
    fname="$(unique_fname ${name})"

    ./ping-csv.sh --add-timestamp -c 10 -I eth0 -4 "${instance_ip}" > "${fname}" &
done

wait
(cd instances; terraform destroy -auto-approve)
