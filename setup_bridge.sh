#!/usr/bin/env bash

# Run this inside a tmux session

set -ex

sudo brctl addbr bridge0
sudo brctl addif bridge0 ens5
sudo ifconfig ens5 0.0.0.0
sudo ifconfig bridge0 up
sudo ifconfig mybridge 10.1.0.135 netmask 255.255.255.0 up
