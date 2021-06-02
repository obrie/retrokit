#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../common.sh"

install() {
  sudo apt install -y ir-keytable

  local keymap_path="$(setting '.hardware.ir.keymap')"
  local keymap_name=$(basename "$keymap_path")
  local target_path="/etc/rc_keymaps/$keymap_name"

  # Define a config file to be read by the configscript when setting up a controller
  local config_path='/opt/retropie/configs/rc_keymap.cfg'
  rm -f "$config_path"
  touch "$config_path"
  crudini --set "$config_path" '' 'source_keymap_path' "$keymap_path"
  crudini --set "$config_path" '' 'target_keymap_path' "$target_path"
}

uninstall() {
  local keymap_path="$(setting '.hardware.ir.keymap')"
  local keymap_name=$(basename "$keymap_path")
  sudo rm -f "/etc/rc_keymaps/$keymap_name" /opt/retropie/configs/rc_keymap.cfg
}

"${@}"
