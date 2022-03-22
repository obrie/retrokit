#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='retroarch'
setup_module_desc='Retroarch and core configuration options'

retroarch_config_path='/opt/retropie/configs/all/retroarch.cfg'
retroarch_core_options_path='/opt/retropie/configs/all/retroarch-core-options.cfg'
retroarch_default_overlay_path='/opt/retropie/configs/all/retroarch/overlay/base.cfg'

configure() {
  __restore_config
  ini_merge '{config_dir}/retroarch/retroarch.cfg' "$retroarch_config_path" restore=false
  ini_merge '{config_dir}/retroarch/retroarch-core-options.cfg' "$retroarch_core_options_path"
  ini_merge '{config_dir}/retroarch/overlay.cfg' "$retroarch_default_overlay_path"
}

restore() {
  restore_file "$retroarch_core_options_path" delete_src=true
  restore_file "$retroarch_default_overlay_path" delete_src=true
  __restore_config delete_src=true
}

__restore_config() {
  if has_backup_file "$retroarch_config_path"; then
    if [ -f "$retroarch_config_path" ]; then
      # Keep track of the inputs since we don't want to lose those
      grep -E '^input_.+' "$retroarch_config_path" > "$tmp_ephemeral_dir/retroarch-inputs.cfg"

      restore_file "$retroarch_config_path" "${@}"

      # Merge the inputs back in
      crudini --merge --inplace "$retroarch_config_path" < "$tmp_ephemeral_dir/retroarch-inputs.cfg"
      rm "$tmp_ephemeral_dir/retroarch-inputs.cfg"
    else
      restore_file "$retroarch_config_path" "${@}"
    fi
  fi
}

setup "${@}"
