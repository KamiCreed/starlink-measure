#!/usr/bin/env bash

pantheon_dir="$1"
data_dir="$2"
ssh_cmd="$3"
sender="$4"

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <pantheon_dir> <data_dir> <ssh_cmd> <sender>" >&2
    exit 2
fi

cd "$pantheon_dir"

# 20 runs of 30 seconds with 5 minute rest
src/experiments/test.py remote --sender $sender -t 30 -f 4 --run-times 20 --data-dir "$data_dir" --all $ssh_cmd
src/analysis/analyze.py --data-dir "$data_dir"
