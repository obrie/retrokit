#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../common.sh"

pair_device() {
  local name=$1

  read -p "Do you have device \"$name\" ready for pairing? (y/n): " confirm
  if [[ $confirm == [yY] ]]; then
    while read -r mac_address hci_name; do
      echo "Found device at $mac_address.  Scanning with bluetoothctl..."
      rm "$tmp_dir/bluetooth.out"
      bluetoothctl scan on >> "$tmp_dir/bluetooth.out" &
      local scan_pid=$!

      while ! grep "$mac_address" "$tmp_dir/bluetooth.out"; do
        echo "Waiting for $mac_address..."
        sleep 1
      done

      kill $scan_pid

      echo "Pairing with $mac_address"
      bluetoothctl trust "$mac_address"
      bluetoothctl pair "$mac_address"
      bluetoothctl connect "$mac_address"
    done < <(hcitool scan | grep "$name")

    return 0
  else
    return 1
  fi
}

install() {
  if [ $(setting '.hardware | has("bluetooth")') == 'true' ]; then
    # Back up bluetooth settings
    if [ ! -d '/var/lib/bluetooth.rk-src' ]; then
      sudo cp -R /var/lib/bluetooth/ /var/lib/bluetooth.rk-src
    fi

    # Pair devices
    while IFS=$'\n' read -r name; do
      retval=0

      # So longer as the user has more devices to pair, keep asking
      while [ $retval == 0 ]; do
        pair_device "$name" </dev/tty || retval=$?
      done
    done < <(setting '.hardware.bluetooth.devices[]')
  fi
}

uninstall() {
  echo 'No uninstall for bluetooth-pair'
}

"${@}"
