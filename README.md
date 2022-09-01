# Starlink Measure

Throughput measurements use `iperf3` to measure the per second TCP and UDP download and upload throughput:
```
./run_world_iperf3.sh [-nh] [-d udp_download_bits] [-u udp_upload_bits] path/to/dest/folder
```

The throughput is measured at a set time interval switching sequentially between all the specified regions.

The `-n` flag specifies not to create terraform instances just in case the instances have already been
created, for example, due to the ping measurements.

Ping is used to measure the per second latency in a continuous fashion. Ping is sent to all the region instances
simultaneously as they should not necessarily interfere with each other much due to sending small packets.
```
./run_ping.sh [-nh] path/to/dest/folder
```
