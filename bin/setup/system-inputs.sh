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
  while read -r emulator_filename; do
    local source_path="{system_config_dir}/autoport/emulators/$emulator_filename"
    local target_path="$retropie_system_config_dir/autoport/emulators/$emulator_filename"

    if any_path_exists "$source_path"; then
      ini_merge "$source_path" "$target_path" backup=false overwrite=true
    else
      rm -fv "$target_path"
    fi
  done < <(each_path '{system_config_dir}/autoport/emulators' find '{}' -name '*.cfg' -printf '%f\n' | sort | uniq)
}

restore() {
  rm -rfv \
    "$retropie_system_config_dir/autoport.cfg" \
    "$retropie_system_config_dir/autoport/emulators"

  # Check if the directory is now empty
  if [ -d "$retropie_system_config_dir/autoport" ] && [ -z "$(ls -A "$retropie_system_config_dir/autoport")" ]; then
    rmdir -v "$retropie_system_config_dir/autoport"
  fi
}

setup "${@}"
