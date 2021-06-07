#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  ini_merge "$config_dir/boot/config.txt" '/boot/config.txt' space_around_delimiters=false as_sudo=true

  # Note that we can't use crudini for dtoverlay additions because it doesn't
  # support repeating the same key multiple times in the same section

  # Wifi configuration
  if [ "$(setting '.hardware.wifi.enabled')" == 'false' ]; then
    echo 'dtoverlay=disable-wifi' | sudo tee -a /boot/config.txt
  fi

  # IR configuration
  local ir_gpio_pin=$(setting '.hardware.ir.gpio_pin')
  local ir_keymap_path=$(setting '.hardware.ir.keymap')
  if [ -n "$ir_gpio_pin" ] || [ -n "$ir_keymap_path" ]; then
    sudo apt install -y ir-keytable
    local ir_keymap_filename=$(basename "$ir_keymap_path")
    local rc_map_name=$(grep "$ir_keymap_filename" '/etc/rc_maps.cfg' | tr $'\t' ' ' | cut -d' ' -f 2)

    echo "dtoverlay=gpio-ir,gpio_pin=$ir_gpio_pin,rc-map-name=$rc_map_name" | sudo tee -a /boot/config.txt
  fi

  # Add case-specific boot options.  We do this here instead of the case setup
  # in order to avoid multiple scripts modifying the /boot/config.txt file.
  local case=$(setting '.hardware.case.model')
  if [ -f "$config_dir/boot/config-$case.txt" ]; then
    cat "$config_dir/boot/config-$case.txt" | sudo tee -a /boot/config.txt >/dev/null
  fi
}

uninstall() {
  restore '/boot/config.txt' as_sudo=true delete_src=true
}

"${@}"
