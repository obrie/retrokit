#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../common.sh"

pair_device() {
  local name=$1

  read -p "Do you have device \"$name\" ready for pairing? (y/n): " confirm
  if [[ $confirm == [yY] ]]; then
    echo 'Scanning for device...'
    local matching_devices=$(hcitool scan | grep "$name")

    if [ -n "$matching_devices" ]; then
      while read -r mac_address hci_name; do
        if bluetoothctl devices | grep "$mac_address"; then
          echo "Already paired with $mac_address.  Skipping."
          continue
        fi

        echo "Found device at $mac_address.  Scanning with bluetoothctl..."

        # Turn on agent
        bluetoothctl agent on </dev/null

        # Scan for device
        rm -f "$tmp_dir/bluetooth.out"
        stdbuf -i0 -o0 -e0 bluetoothctl --timeout 30 scan on </dev/null >> "$tmp_dir/bluetooth.out" &
        local scan_pid=$!

        # Wait for device to appear
        while ! grep "$mac_address" "$tmp_dir/bluetooth.out"; do
          echo "Waiting for $mac_address..."
          sleep 1
        done

        # Shut down scanner
        kill $scan_pid
        rm -f "$tmp_dir/bluetooth.out"

        # Pair device
        echo "Pairing with $mac_address"
        bluetoothctl trust "$mac_address" </dev/null
        bluetoothctl pair "$mac_address" </dev/null
        bluetoothctl connect "$mac_address" </dev/null
      done < <(echo "$matching_devices")
    else
      echo 'No devices found.  Please try again.'
    fi

    return 0
  else
    return 1
  fi
}

install() {
  if [ $(setting '.hardware | has("bluetooth")') == 'true' ]; then
    # Back up bluetooth settings
    if [ ! -d '/var/lib/bluetooth.rk-src' ]; then
      sudo cp -av /var/lib/bluetooth /var/lib/bluetooth.rk-src
    fi

    # Pair devices
    while IFS=$'\n' read -r name; do
      retval=0

      # So long as the user has more devices to pair, keep asking
      while [ $retval == 0 ]; do
        pair_device "$name" </dev/tty || retval=$?
      done
    done < <(setting '.hardware.bluetooth.devices[]')
  fi
}

uninstall() {
  if [ -d '/var/lib/bluetooth.rk-src' ]; then
    sudo rm -rfv /var/lib/bluetooth
    sudo mv -v /var/lib/bluetooth.rk-src /var/lib/bluetooth
  fi
}

"${@}"
