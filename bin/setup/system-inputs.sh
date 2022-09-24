#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-inputs'
setup_module_desc='System-specific automatic port selection using autoport'

configure() {
  restore
  __configure_system_config
  __configure_emulator_configs
}

# System configuration overrides
__configure_system_config() {
  ini_merge '{system_config_dir}/autoport.cfg' "$retropie_system_config_dir/autoport.cfg" backup=false overwrite=true
}

# Emulator configuration overrides
__configure_emulator_configs() {
  local retroarch_config_dir=$(get_retroarch_path 'rgui_config_directory')

  while read -r emulator_name; do
    local source_path="{system_config_dir}/autoport/$emulator_name.cfg"
    local target_path="$retroarch_config_dir/autoport/$emulator_name.cfg"

    if any_path_exists "$source_path"; then
      ini_merge "$source_path" "$target_path"
    else
      rm -fv "$target_path"
    fi
  done < <(system_setting 'select(.emulators) | .emulators | keys[]')
}

restore() {
  rm -rfv "$retropie_system_config_dir/autoport.cfg"
}

setup "$1" "${@:3}"
