#!/usr/bin/env bash

set -x

pantheon_dir="$1"
data_dir="$2"
ssh_cmd="$3"
sender="$4"

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <pantheon_dir> <data_dir> <ssh_cmd> <sender>" >&2
    exit 2
fi

cd "$pantheon_dir"
#schemes=(cubic vegas bbr ledbat pcc verus sprout quic scream webrtc copa taova vivace pcc_experimental fillp indigo fillp_sheep)
schemes=(cubic bbr)

# 20 tests of 20 runs of 30 seconds with 5 minute rest
for scheme in "${schemes[@]}"; do
    for i in {1..20}; do
        spec_data_dir="${data_dir}_${scheme}_test${i}"
        src/experiments/test.py remote --sender $sender -t 30 -f 4 --run-times 20 --data-dir "$spec_data_dir" --schemes "${scheme}" $ssh_cmd
        src/analysis/analyze.py --data-dir "$spec_data_dir"
        sleep 300
    done
done
