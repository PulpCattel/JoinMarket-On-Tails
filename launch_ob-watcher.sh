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

# Modifies iptables, to use a different port change the port number
echo "
Insert admin password to modify iptables for ob-watcher"
sudo iptables -I OUTPUT -p tcp -d 127.0.0.1 --dport 62601 -m owner --uid-owner amnesia -j ACCEPT

cd $JM_REPO || exit
source jmvenv/bin/activate
cd scripts/obwatch || exit
python3 ob-watcher.py --datadir=$JM_DIR "$@"