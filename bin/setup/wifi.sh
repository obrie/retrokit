#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='wifi'
setup_module_desc='Wifi authentication configuration'

configure() {
  if any_path_exists '{config_dir}/wifi/wpa_supplicant.conf'; then
    file_cp '{config_dir}/wifi/wpa_supplicant.conf' '/etc/wpa_supplicant/wpa_supplicant.conf' as_sudo=true

    if [ -n "$WIFI_SSID" ]; then
      each_path '{config_dir}/wifi/wpa_supplicant.auth.conf' cat '{}' | tee -a '/etc/wpa_supplicant/wpa_supplicant.conf' >/dev/null
    else
      echo 'Missing wifi auth (skipping)'
    fi

    # Explicitly enable the country in order to trigger rfkill changes
    country=$(crudini --get /etc/wpa_supplicant/wpa_supplicant.conf '' 'country')
    if [ -n "$country" ]; then
      sudo raspi-config nonint do_wifi_country "$country" >/dev/null
    fi
  fi
}

restore() {
  restore_file '/etc/wpa_supplicant/wpa_supplicant.conf' as_sudo=true delete_src=true
}

setup "${@}"
