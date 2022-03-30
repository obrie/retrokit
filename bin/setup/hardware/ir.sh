#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../common.sh"

setup_module_id='hardware/ir'
setup_module_desc='IR autoconfig based on keyboard setup'

source_keymap_path=$(setting '.hardware.ir.keymap')
source_keymap_name=$(basename "$source_keymap_path")
target_keymap_path="/etc/rc_keymaps/$source_keymap_name"
keymap_config_path=/opt/retropie/configs/all/rc_keymap.cfg

depends() {
  sudo apt-get install -y ir-keytable
}

configure() {
  # Define a config file to be read by the autoconfig script when setting up a controller
  rm -f "$keymap_config_path"
  touch "$keymap_config_path"
  crudini --set "$keymap_config_path" '' 'source_keymap_path' "$source_keymap_path"
  crudini --set "$keymap_config_path" '' 'target_keymap_path' "$target_keymap_path"
}

remove() {
  sudo rm -fv "$target_keymap_path" "$keymap_config_path"
  sudo apt-get remove -y ir-keytable
}

setup "${@}"
