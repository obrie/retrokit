#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../common.sh"

pair_device() {
  local name=$1

  read -p "Do you have device \"$name\" ready for pairing? (y/n): " confirm
  if [[ $confirm == [yY] ]]; then
    while read -r mac_address hci_name; do
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

    echo 'Starting Bluetooth device scan.'
    bluetoothctl scan off || true
    bluetoothctl scan on &
    local scan_pid=$!

    # Pair devices
    while IFS=$'\n' read -r name; do
      retval=0

      # So longer as the user has more devices to pair, keep asking
      while [ $retval == 0 ]; do
        pair_device "$name" </dev/tty || retval=$?
      done
    done < <(setting '.hardware.bluetooth.devices[]')

    echo 'Stopping Bluetooth device scan.'
    kill $scan_pid
    bluetoothctl scan off || true
  fi
}

uninstall() {
  echo 'No uninstall for bluetooth-pair'
}

"${@}"
