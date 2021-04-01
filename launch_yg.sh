#!/bin/bash

# Path to JoinMarket data directory - CHANGE ME
JM_DIR=/home/amnesia/Persistent/.joinmarket
# Path to the repository - CHANGE ME
JM_REPO=/home/amnesia/Persistent/joinmarket-clientserver

# Prevent this script from running as root

if [ "$EUID" -eq 0 ]
  then echo "Do not run me as root, exiting";
  exit 2
fi

# Modifies iptables

echo "
Insert admin password to modify iptables for RPC"
sudo iptables -I OUTPUT -p tcp -d 127.0.0.1 --dport 8332 -m owner --uid-owner amnesia -j ACCEPT

echo "
Insert admin password to modify iptables for JoinMarket"
sudo iptables -I OUTPUT -p tcp -d 127.0.0.1 --dport 27183 -m owner --uid-owner amnesia -j ACCEPT

cd $JM_REPO || exit
source jmvenv/bin/activate
cd scripts || exit
python3 yg-privacyenhanced.py --datadir=$JM_DIR "$@"