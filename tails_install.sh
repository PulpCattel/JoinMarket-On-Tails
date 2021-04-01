#!/bin/bash

# Path to the repository - CHANGE ME
JM_DIR=/home/amnesia/Persistent/joinmarket-clientserver

set -e
tput reset

# Prevent this script from running as root

if [ "$EUID" -eq 0 ]
  then echo "Do not run me as root, exiting";
  exit 2
fi

# Enter in joinmarket-clientserver folder

cd $JM_DIR || exit

# Update apt sources
echo "
Insert admin password to update apt sources (apt update)"
sudo apt update

# Install JoinMarket OS dependencies
echo "
Insert admin password to install dependencies (apt install)"
sudo apt install python3-dev python3-pip git build-essential automake pkg-config libtool libffi-dev libssl-dev libgmp-dev libsodium-dev virtualenv

# Python virtualenv

virtualenv --python=python3 jmvenv
source jmvenv/bin/activate

# Secp256k1 library

mkdir -p deps
cd deps || exit
git clone git://github.com/bitcoin-core/secp256k1
cd secp256k1 || exit
git checkout 0d9540b13ffcd7cd44cc361b8744b93d88aa76ba
make clean || true
./autogen.sh
./configure --prefix "${JM_DIR}/jmvenv" --enable-module-recovery --disable-jni --enable-experimental --enable-module-ecdh --enable-benchmark=no
make
make check
make install
cd ../..

# Installing JoinMarket Python dependencies

torsocks pip3 install -r requirements/base.txt
read -r -p "Want to install Qt dependencies? (y/Y to install, anything else skips): " reply
if [[ "$reply" == [yY] ]]
  then torsocks pip3 install --upgrade pip
  torsocks pip3 install -r requirements/gui.txt
fi

# Allow listening to Bitcoin Core by modifying iptables rules

echo "
Insert admin password to modify iptables for RPC"
sudo iptables -I OUTPUT -p tcp -d 127.0.0.1 --dport 8332 -m owner --uid-owner amnesia -j ACCEPT

# Allow listening to JoinMarket server by modifying iptables rules

echo "
Insert admin password to modify iptables for JoinMarket"
sudo iptables -I OUTPUT -p tcp -d 127.0.0.1 --dport 27183 -m owner --uid-owner amnesia -j ACCEPT

# Allow listening to ob-watcher by modifying iptables rules

echo "
Insert admin password to modify iptables for ob-watcher"
sudo iptables -I OUTPUT -p tcp -d 127.0.0.1 --dport 62601 -m owner --uid-owner amnesia -j ACCEPT

echo "
Installation completed, you are ready to use JoinMarket."
exit 0