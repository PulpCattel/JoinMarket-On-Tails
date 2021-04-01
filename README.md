# JoinMarket on Tails

* [Requirements](#Requirements)
* [Get JoinMarket](#Get-JoinMarket)
* [Installation](#Installation)
    * [Debian dependencies](#Debian-dependencies)
    * [Python virtualenv](#Python-virtualenv)
    * [Libsecp256k1 library](#Libsecp256k1-library)
    * [Python dependencies](#Python-dependencies)
* [Configure](#Configure)
    * [Iptables](#Iptables)
    * [JoinMarket](#JoinMarket)
* [Scripts](#Scripts)

Straightforward tutorial on how to create a [JoinMarket](https://github.com/JoinMarket-Org/joinmarket-clientserver) setup on [Tails](https://tails.boum.org).

Since this setup involves a moderate amount of command line, a few bash scripts are provided.
They are nothing more than skinny list of commands (with comments), you are encouraged to review them and, as always, use at **your own risk**.

### Requirements

* A working installation of Tails with [persistent storage](https://tails.boum.org/doc/first_steps/persistence/index.en.html) enabled (persistent options: [`Personal Data`](https://tails.boum.org/doc/first_steps/persistence/configure/index.en.html#index1h2) and [`Additional Software`](https://tails.boum.org/doc/first_steps/persistence/configure/index.en.html#index5h2)).
  If you need assistance, you can refer to this [guide](https://github.com/PulpCattel/tails-bitcoincore-wasabi), which also includes a lot of links to the official documentation.
  
* Bitcoin Core.
The guide linked above covers also how to get and configure [Bitcoin Core](https://bitcoincore.org) on Tails.
  
### Get JoinMarket

You can either clone the repository via git (it's installed by default on Tails), or you can download the `tar.gz` file from the [release page](https://github.com/JoinMarket-Org/joinmarket-clientserver/releases) and extract it.
In any case, make sure to save the file **into the persistent folder**.

E.g., to download JoinMarket 0.8.2 (the latest version as of Bitcoin block 677199) directly from a Tails terminal, you can use the following command: 

(Torsocks is a command used to [torify](https://gitlab.torproject.org/legacy/trac/-/wikis/doc/TorifyHOWTO) applications, which is a requirement on Tails. Some programs, like `git`, are torified by default)

```bash
torsocks curl --tlsv1.3 --proto =https --location --remote-name https://github.com/JoinMarket-Org/joinmarket-clientserver/archive/refs/tags/v0.8.2.tar.gz  
```

Always make sure to verify the PGP signatures. Following the example above, you can use the same command to download the [signature file](https://github.com/JoinMarket-Org/joinmarket-clientserver/releases/download/v0.8.2/joinmarket-clientserver-0.8.2.tar.gz.asc) and the [maintainer PGP key](https://raw.githubusercontent.com/JoinMarket-Org/joinmarket-clientserver/master/pubkeys/AdamGibson.asc) by simply replacing the URL.

At this point, your persistent folder should look something like this:

`/Persistent`  
&emsp; `/bitcoin-0.21` (Bitcoin Core launcher folder)  
&emsp; `/.bitcoin`  (Bitcoin Core data folder)  
&emsp; `/joinmarket-clientserver-0.8.2` (JoinMarket repository)

### Installation

We need admin privileges for this part, make sure you have selected the corresponding option at Tails' boot.

#### Debian dependencies

First, we have to satisfy JoinMarket dependencies as per [here](https://github.com/JoinMarket-Org/joinmarket-clientserver/blob/master/docs/INSTALL.md#installation-on-linux
):


```bash
sudo apt update
sudo apt install python3-dev python3-pip git build-essential automake pkg-config libtool libffi-dev libssl-dev libgmp-dev libsodium-dev virtualenv
```

(Some packages are already installed, but there is no problem as they will be ignored by `apt`.)

After installation, Tails will [ask](https://tails.boum.org/doc/first_steps/additional_software/index.en.html#index4h2) if you want to install these packages every time you start Tails in the future.
Choose `Install Every Time`.

Whenever needed, you can also [remove](https://tails.boum.org/doc/first_steps/additional_software/index.en.html#index5h1) packages from the persistent storage.

#### Python virtualenv

We enter the `joinmarket-clientserver-0.8.2` folder and we create the Python virtualenv:

```bash
cd joinmarket-clientserver-0.8.2
virtualenv --python=python3 jmvenv
source jmvenv/bin/activate
```

#### Libsecp256k1 library

Following the JoinMarket documentation linked above, we download and install the `libsecp256k1` library.

The full list of commands is copied here for convenience, but you should try to refer to the official ones since they have a much greater chance of being up to date.

As explained in the doc, we have to replace `JM_ROOT`, in one of the commands below, with our path to `jmvenv`.
Normally, it will be something like: `/home/amnesia/Persistent/joinmarket-clientserver/jmvenv`.

```bash
mkdir -p deps
cd deps
git clone git://github.com/bitcoin-core/secp256k1
cd secp256k1
git checkout 0d9540b13ffcd7cd44cc361b8744b93d88aa76ba
make clean
./autogen.sh
./configure --prefix /home/amnesia/Persistent/joinmarket-clientserver-0.8.2/jmvenv --enable-module-recovery --disable-jni --enable-experimental --enable-module-ecdh --enable-benchmark=no
make
make check
make install
cd ../..
```

#### Python dependencies

Lastly, we install the Python dependencies:

```bash
torsocks pip3 install -r requirements/base.txt
```

If we also want the graphical user interface, we will do in addition:

```bash
torsocks pip3 install --upgrade pip
torsocks pip3 install -r requirements/gui.txt
```

JoinMarket is successfully installed.

## Configure

#### Iptables

Tails is heavily firewalled, to allow JoinMarket and Bitcoin Core to interact via RPC, we need to modify iptables rules with a command like:

```bash
sudo iptables -I OUTPUT -p tcp -d 127.0.0.1 --dport 8332 -m owner --uid-owner amnesia -j ACCEPT
```

We can use the same command, with a different `--dport`, to allow the JoinMarket server (used by both taker and maker role) and the [ob-watcher script](https://github.com/JoinMarket-Org/joinmarket-clientserver/blob/master/docs/orderbook.md) (default ports for them are `27183` and `62601` respectively).

This need to be done **every** time you restart Tails and requires admin privileges.
A few bash wrappers are provided to do it automatically. 

#### JoinMarket

As explained [here](https://github.com/JoinMarket-Org/joinmarket-clientserver/blob/master/docs/USAGE.md#portability), JoinMarket supports natively custom data folder locations.
We can leverage that to tell JoinMarket to create/use our data folder into/from the persistent storage.

E.g.,

```bash
python3 joinmarket-qt.py --datadir=/home/amnesia/Persistent/.joinmarket
```

Once we have the data folder saved in the persistent, we can set JoinMarket to use Tor.
We can achieve that easily by changing the relevant parts (`[MESSAGING:server]`) in the `joinmarket.cfg` configuration file. 

Some JoinMarket functionalities may require additional configuration (like [Payjoin](https://github.com/JoinMarket-Org/joinmarket-clientserver/blob/master/docs/PAYJOIN.md) and [SNICKER](https://github.com/JoinMarket-Org/joinmarket-clientserver/blob/master/docs/SNICKER.md)), I'll try to cover them here as time allows.
Any testing/reporting  is appreciated.

## Scripts

Currently, 4 bash scripts are provided (you can mark them as executables with `chmod +x script_name.sh`, and run them with `./script_name.sh`):

* [`tails_install.sh`](/tails_install.sh) covers all the installation part and iptables configuration for RPC, JoinMarket server and ob-watcher.

*  [`launch_qt.sh`](/launch_qt.sh) is a wrapper around `joinmarket-qt.py`, it launches the graphical user interface by prepending the `--datadir=` option and forwards all the options passed to the Python script.
It also takes care of modifying iptables.

* [`launch_ob-watcher.sh`](/launch_ob-watcher.sh) is a wrapper around `ob-watcher.py`, it launches the orderbook server by prepending the `--datadir=` option and forwards all the options passed to the Python script.
It also takes care of modifying iptables.
  
* [`launch_yg.sh`](/launch_yg.sh) is a wrapper around `yg-privacyenhanced.py`, it launches the yield generator by prepending the `--datadir=` option and forwards all the options passed to the Python script. It also takes care of modifying iptables.
  
You are supposed to change the paths used by the scripts by replacing the `CHANGE ME` parts.

Enjoy!

---

[Bibliography](/bibliography.md)