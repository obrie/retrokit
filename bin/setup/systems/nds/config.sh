#!/bin/bash

system='nds'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='system/nds/config'
setup_module_desc='NDS emulator configuration'

drastic_config_file="$retropie_system_config_dir/drastic/config/drastic.cfg"

configure() {
  __restore_config
  ini_merge '{system_config_dir}/drastic.cfg' "$drastic_config_file" restore=false
}

restore() {
  __restore_config delete_src=true
}

__restore_config() {
  if has_backup_file "$drastic_config_file"; then
    if [ -f "$drastic_config_file" ]; then
      # Keep track of the input_maps since we don't want to lose those
      grep -E '^controls_' "$drastic_config_file" > "$tmp_ephemeral_dir/controls.cfg"

      # Restore and remove any controls from the original file
      restore_file "$drastic_config_file" "${@}"
      sed -i '/^controls_/d' "$drastic_config_file"

      # Merge the controls back in
      crudini --inplace --merge "$drastic_config_file" < "$tmp_ephemeral_dir/controls.cfg"
    else
      restore_file "$drastic_config_file" "${@}"
    fi
  fi
}

setup "${@}"
