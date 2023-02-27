#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../common.sh"

setup_module_id='hardware/ir'
setup_module_desc='IR autoconfig based on keyboard setup'

source_keymap_file=$(setting '.hardware.ir.keymap')
source_keymap_name=$(basename "$source_keymap_file")
target_keymap_file="/etc/rc_keymaps/$source_keymap_name"
keymap_config_file="$retropie_configs_dir/all/rc_keymap.cfg"

depends() {
  sudo apt-get install -y ir-keytable
}

configure() {
  # Define a config file to be read by the autoconfig script when setting up a controller
  rm -f "$keymap_config_file"
  touch "$keymap_config_file"
  crudini --set "$keymap_config_file" '' 'source_keymap_path' "$source_keymap_file"
  crudini --set "$keymap_config_file" '' 'target_keymap_path' "$target_keymap_file"
}

restore() {
  sudo rm -fv "$target_keymap_file" "$keymap_config_file"
}

remove() {
  sudo apt-get remove -y ir-keytable
  sudo apt-get autoremove --purge -y
}

setup "${@}"
