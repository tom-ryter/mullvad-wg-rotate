#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Non-Commercial Software License (Summary)
#
# Copyright (c) 2026 Tom Ryter + AI assistance
#
# You may use, modify, and share this software for non-commercial purposes.
#
# Requirements:
# - Attribution must be given to "Tom Ryter + AI assistance"
# - This notice must remain intact
#
# Restrictions:
# - No commercial use
# - No selling or monetizing
# - No offering as a hosted service (SaaS)
#
# Full license available in the LICENSE file in this repository.
# ------------------------------------------------------------------------------

set -euo pipefail

CONF_DIR="/home/soulless/Wireguardconfs"
DEFAULT_MTU="1300"
PREFIX="temp-mullvad-random-"

ACTION="${1:-}"
shift || true

INCLUDE=""
EXCLUDE=""
MTU="$DEFAULT_MTU"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --include) INCLUDE="$2"; shift 2 ;;
    --exclude) EXCLUDE="$2"; shift 2 ;;
    --mtu) MTU="$2"; shift 2 ;;
    *) shift ;;
  esac
done

usage() {
  echo "Usage: mullvad-wg-rotate {vpnup|vpndown|status} [--include STR] [--exclude STR] [--mtu N]"
}

die() {
  echo "FATAL: $*" >&2
  exit 1
}

require_cmds() {
  command -v nmcli >/dev/null || die "nmcli not found"
  command -v shuf >/dev/null || die "shuf not found"
  command -v ip >/dev/null || die "ip not found"
}

temp_connections() {
  nmcli -t -f NAME,TYPE connection show     | awk -F: -v p="$PREFIX" '$2=="wireguard" && index($1,p)==1 {print $1}'
}

stale_mullvad_interfaces() {
  ip -br link | awk '$1 ~ /^us-[a-z0-9]+-wg-[0-9]+$/ {print $1}'
}

cleanup_stale_interfaces() {
  mapfile -t stale_ifaces < <(stale_mullvad_interfaces)
  for iface in "${stale_ifaces[@]}"; do
    echo "Deleting stale WireGuard interface: $iface"
    sudo ip link delete "$iface" 2>/dev/null || true
  done
}

vpndown() {
  require_cmds
  mapfile -t conns < <(temp_connections)
  for conn in "${conns[@]}"; do
    echo "Disconnecting/deleting: $conn"
    nmcli connection down "$conn" >/dev/null 2>&1 || true
    nmcli connection delete "$conn" >/dev/null 2>&1 || true
  done
  cleanup_stale_interfaces
}

vpnup() {
  require_cmds

  mapfile -t confs < <(
    find "$CONF_DIR" -maxdepth 1 -type f -name '*.conf'     | grep -i "${INCLUDE:-.}"     | grep -vi "${EXCLUDE:-^$}"     | sort
  )

  [[ "${#confs[@]}" -gt 0 ]] || die "No matching configs found"

  vpndown >/dev/null 2>&1 || true

  selected_conf="$(printf '%s
' "${confs[@]}" | shuf -n 1)"
  base_name="$(basename "$selected_conf" .conf)"
  conn_name="${PREFIX}${base_name}"

  echo "Selected: $selected_conf"
  echo "Importing as: $conn_name"

  nmcli connection import type wireguard file "$selected_conf" >/dev/null

  nmcli connection modify "$base_name" connection.id "$conn_name"
  nmcli connection modify "$conn_name" wireguard.mtu "$MTU"

  echo "Bringing VPN up..."
  nmcli connection up "$conn_name"

  echo
  echo "Active VPN:"
  nmcli connection show --active | grep -E "$conn_name|NAME" || true

  echo
  echo "WireGuard interface:"
  ip -br link | grep wg || true

  echo
  echo "Public IP:"
  curl -4 --max-time 10 https://ifconfig.me || true
  echo
}

status() {
  require_cmds
  echo "Active connections:"
  nmcli connection show --active
  echo
  echo "Temp Mullvad profiles:"
  temp_connections || true
  echo
  echo "Interfaces:"
  ip -br link
}

case "$ACTION" in
  vpnup) vpnup ;;
  vpndown) vpndown ;;
  status) status ;;
  *) usage; exit 1 ;;
esac
