#!/bin/bash

system='nds'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

config_path="$retropie_system_config_dir/nds/drastic/config/drastic.cfg"

restore_config() {
  if has_backup "$config_path"; then
    if [ -f "$config_path" ]; then
      # Keep track of the input_maps since we don't want to lose those
      grep -E '^controls_' "$config_path" > "$system_tmp_dir/controls.cfg"

      # Restore and remove any controls from the original file
      restore "$config_path" "${@}"
      sed -i '/^controls_/d' "$config_path"

      # Merge the controls back in
      crudini --inplace --merge "$config_path" < "$system_tmp_dir/controls.cfg"
      rm "$system_tmp_dir/controls.cfg"
    else
      restore "$config_path" "${@}"
    fi
  fi
}

install() {
  restore_config
  ini_merge "$system_config_dir/drastic.cfg" "$config_path" restore=false
}

uninstall() {
  restore_config delete_src=true
}

"${@}"
