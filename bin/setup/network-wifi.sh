#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='network-wifi'
setup_module_desc='Wifi authentication configuration'

configure() {
  if any_path_exists '{config_dir}/network/wpa_supplicant/wpa_supplicant.conf'; then
    file_cp '{config_dir}/network/wpa_supplicant/wpa_supplicant.conf' '/etc/wpa_supplicant/wpa_supplicant.conf' as_sudo=true

    # Explicitly enable the country in order to trigger rfkill changes
    country=$(crudini --get /etc/wpa_supplicant/wpa_supplicant.conf '' 'country')
    if [ -n "$country" ]; then
      sudo raspi-config nonint do_wifi_country "$country" >/dev/null
    fi

    if [ -n "$WIFI_SSID" ]; then
      each_path '{config_dir}/network/wpa_supplicant/wpa_supplicant.auth.conf' cat '{}' | envsubst | sudo tee -a '/etc/wpa_supplicant/wpa_supplicant.conf' >/dev/null
    else
      echo 'Missing wifi auth (skipping)'
    fi
  fi
}

restore() {
  restore_file '/etc/wpa_supplicant/wpa_supplicant.conf' as_sudo=true delete_src=true
}

setup "${@}"
