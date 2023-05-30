# Starlink Measure

Throughput measurements use `iperf3` to measure the per second TCP and UDP download and upload throughput:
```
./run_world_iperf3.sh [-nh] [-d udp_download_bits] [-u udp_upload_bits] path/to/dest/folder
```

The throughput is measured at a set time interval switching sequentially between all the specified regions.

The `-n` flag specifies not to create terraform instances just in case the instances have already been
created, for example, due to the ping measurements.

`-d` and `-u` are directly passed to `iperf3`, so values such as 10K is allowed denoting 10 Kbits/sec as described
in the `iperf3` documentation for the `--bitrate` flag.

Ping is used to measure the per second latency in a continuous fashion. Ping is sent to all the region instances
simultaneously as they should not necessarily interfere with each other much due to sending small packets.
```
./run_ping.sh [-nh] path/to/dest/folder
```

## Pantheon KVM

Run the following before setting up [Pantheon](https://github.com/StanfordSNR/pantheon).

```bash
wget https://bootstrap.pypa.io/pip/2.7/get-pip.py
python ./get-pip.py
```
```bash
echo 'net.ipv4.ip_forward=1
net.core.default_qdisc=fq' >> /etc/sysctl.conf
```
```bash
sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo apt install --install-recommends -y linux-generic-hwe-16.04
sudo reboot
```

On the server, copy the `src` folder into a created `pantheon` subdir:
```bash
mkdir pantheon
cp -r src pantheon
```

Always run the setup before running Pantheon on both the client and server:
```bash
src/experiments/setup.py [--all | --schemes "<cc1> <cc2> ..."]
```
