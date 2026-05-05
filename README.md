# mullvad-wg-rotate Quick Overview


## 🚀 Overview
This project demonstrates the setup and configuration of a secure VPN for private network communication and controlled remote access. It focuses on reliability, system-level networking, and practical deployment.

**Core capabilities:**
- Secure tunneling between systems
- Configuration of VPN services and clients
- Emphasis on privacy and data protection
- Network-level control and routing
- Designed for stability and repeatable setup

---

## ⚡ Quick Start

```bash
# clone
git clone https://github.com/tom-ryter/mullvad-wg-rotate.git
cd mullvad-wg-rotate

# follow setup instructions
# (see full documentation below)

# mullvad-wg-rotate

Randomized Mullvad WireGuard connection manager for NetworkManager.

Designed for quick VPN rotation with automatic cleanup and MTU tuning for unstable/mobile networks (e.g. T-Mobile, CGNAT).

---

## Features

- Random Mullvad WireGuard server selection
- Ephemeral NetworkManager connections (no clutter)
- Automatic cleanup of stale interfaces
- MTU tuning (default: 1300 for mobile networks)
- Optional include/exclude filters

---

## Requirements

- Linux system
- NetworkManager with WireGuard support
- `nmcli`, `ip`, `curl`, `shuf`

### Install dependencies

**Arch / CachyOS**
```bash
sudo pacman -S networkmanager wireguard-tools
```

**Debian / Ubuntu**
```bash
sudo apt install network-manager wireguard wireguard-tools
```

---

## Getting Mullvad WireGuard Configs

1. Go to:
   https://mullvad.net/en/account/#/wireguard-config

2. Select:
   - Platform: Linux
   - Protocol: WireGuard
   - Choose multiple locations

3. Download the `.conf` files

4. Place them in a directory:

```bash
~]$ mkdir -p ~/Wireguardconfs
~]$ mv *.conf ~/Wireguardconfs/
```

---

## Setup

Place the script in a usable location:

```bash
~]$ cp mullvad-wg-rotate.sh ~/scripts/
~]$ chmod +x ~/scripts/mullvad-wg-rotate.sh
```

Edit the config directory inside the script if needed:

```bash
CONF_DIR="/home/youruser/Wireguardconfs"
```

---

## Usage

### Connect (random server)

```bash
~]$ ./mullvad-wg-rotate.sh vpnup
```

Example output:

```text
Selected: /home/user/Wireguardconfs/us-nyc-wg-801.conf
Importing as: temp-mullvad-random-us-nyc-wg-801
Bringing VPN up...

Active VPN connection:
NAME                               TYPE       DEVICE
temp-mullvad-random-us-nyc-wg-801  wireguard  us-nyc-wg-801

WireGuard interface:
us-nyc-wg-801    <UP>

Public IP:
23.x.x.x
```

---

### Connect with filters

```bash
~]$ ./mullvad-wg-rotate.sh vpnup --include nyc
~]$ ./mullvad-wg-rotate.sh vpnup --exclude qas
```

---

### Override MTU

```bash
~]$ ./mullvad-wg-rotate.sh vpnup --mtu 1280
```

---

### Disconnect and cleanup

```bash
~]$ ./mullvad-wg-rotate.sh vpndown
```

---

### Status

```bash
~]$ ./mullvad-wg-rotate.sh status
```

Example output:

```text
Active connections:
NAME                               TYPE       DEVICE
temp-mullvad-random-us-nyc-wg-801  wireguard  us-nyc-wg-801

Temp Mullvad profiles:
temp-mullvad-random-us-nyc-wg-801

Interfaces:
lo
wlan0
us-nyc-wg-801
```

---

## Notes

- Default MTU is **1300**, optimized for mobile / CGNAT networks (T-Mobile, LTE, 5G)
- On stable wired connections, you may prefer:

```bash
--mtu 1420
```

- Only one VPN connection should be active at a time
- Script removes its own temporary connections automatically

---

## Limitations

- Designed for Mullvad-style WireGuard configs
- Requires NetworkManager (not compatible with wg-quick-only setups)
- Removes temporary profiles it creates (`temp-mullvad-random-*`)
- Removes stale Mullvad-style interfaces if present

---

## Disclaimer

Use at your own risk. This tool modifies network connections and routing.

---

## License

MIT
