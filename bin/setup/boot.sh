#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  ini_merge "$config_dir/boot/config.txt" '/boot/config.txt' space_around_delimiters=false as_sudo=true

  # Note that we can't use crudini for dtoverlay additions because it doesn't
  # support repeating the same key multiple times in the same section

  # Wifi configuration
  if [ "$(setting '.hardware.wifi.enabled')" == 'false' ]; then
    sudo echo 'dtoverlay=disable-wifi' >> /boot/config.txt
  fi

  # IR configuration
  local ir_gpio_pin=$(setting '.hardware.ir.gpio_pin')
  local ir_keymap_path=$(setting '.hardware.ir.keymap')
  if [ -n "$ir_gpio_pin" ] || [ -n "$ir_keymap_path" ]; then
    local ir_keymap_filename=$(basename "$ir_keymap_path")
    local rc_map_name=$(grep "$ir_keymap_filename" '/etc/rc_maps.cfg' | tr $'\t' ' ' | cut -d' ' -f 2)

    sudo echo 'dtoverlay=gpio_pin=$ir_gpio_pin,rc-map-name=$rc_map_name' >> /boot/config.txt
  fi
}

uninstall() {
  restore '/boot/config.txt'
}

"${@}"
