ip netns add net_remote_ns

# Set namespace to use wlan0, after this point wlan0 is not usable by programs
# outside the namespace
ip link set wlan0 netns net_remote_ns

ip netns exec net_remote_ns ip link set wlan0 up

ip netns exec net_remote_ns dhclient wlan0

ip netns exec net_remote_ns ping -c 3 google.ca
