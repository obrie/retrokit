#!/bin/bash

system='nds'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='system/nds/config'
setup_module_desc='NDS emulator configuration'

config_path="$retropie_system_config_dir/drastic/config/drastic.cfg"

configure() {
  __restore_config
  ini_merge '{system_config_dir}/drastic.cfg' "$config_path" restore=false
}

restore() {
  __restore_config delete_src=true
}

__restore_config() {
  if has_backup_file "$config_path"; then
    if [ -f "$config_path" ]; then
      # Keep track of the input_maps since we don't want to lose those
      grep -E '^controls_' "$config_path" > "$tmp_ephemeral_dir/controls.cfg"

      # Restore and remove any controls from the original file
      restore_file "$config_path" "${@}"
      sed -i '/^controls_/d' "$config_path"

      # Merge the controls back in
      crudini --inplace --merge "$config_path" < "$tmp_ephemeral_dir/controls.cfg"
    else
      restore_file "$config_path" "${@}"
    fi
  fi
}

setup "${@}"
