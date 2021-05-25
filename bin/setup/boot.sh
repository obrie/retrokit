#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  ini_merge "$config_dir/boot/config.txt" '/boot/config.txt' space_around_delimiters=false as_sudo=true

  # Enable IR configuration
  local ir_gpio_pin=$(setting '.hardware.ir.gpio_pin')
  local ir_keymap_path=$(setting '.hardware.ir.keymap')
  if [ -n "$ir_gpio_pin" ] || [ -n "$ir_keymap_path" ]; then
    local ir_keymap_filename=$(basename "$ir_keymap_path")
    local rc_map_name=$(grep "$ir_keymap_filename" '/etc/rc_maps.cfg' | tr $'\t' ' ' | cut -d' ' -f 2)

    crudini --set '/boot/config.txt' 'dtoverlay' "gpio_pin=$ir_gpio_pin,rc-map-name=$rc_map_name"
  fi
}

uninstall() {
  restore '/boot/config.txt'
}

"${@}"
