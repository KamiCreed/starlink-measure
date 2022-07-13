#!/usr/bin/env bash
export PATH=/home/pi/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games
cleanup() {
    kill -2 $1
    wait
}

output=starlink

(cd /home/pi/Starlink/starlink-measure; ./run_ping.sh "../${output}_ping" &> /home/pi/Starlink/ping_measure.log) &
ping_pid=$!
trap "cleanup $ping_pid" EXIT SIGTERM

while ! (cd /home/pi/Starlink/starlink-measure/instances/; ping -c 1 -n `terraform output -raw us-west-1_public_ip 2> /dev/null` &> /dev/null)
do
    printf "%c" "."
    sleep 1
done

while true
do
    (cd /home/pi/Starlink/starlink-measure; ./run_world_iperf3.sh -n "../${output}_iperf3") > /home/pi/Starlink/measure.log 2>&1
    sleep 1
done
