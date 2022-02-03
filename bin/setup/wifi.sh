#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  if [ -n "$WIFI_SSID" ]; then
    file_cp "$config_dir/wifi/wpa_supplicant.conf" '/etc/wpa_supplicant/wpa_supplicant.conf' as_sudo=true
  else
    echo 'Missing wifi auth (skipping)'
  fi
}

uninstall() {
  restore_file '/etc/wpa_supplicant/wpa_supplicant.conf' as_sudo=true delete_src=true
}

"${@}"
