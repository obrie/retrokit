#!/bin/bash

system='dreamcast'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='system/dreamcast/config'
setup_module_desc='Dreamcast emulator configuration'

redream_dir="$retropie_system_config_dir/redream"
redream_config_file="$redream_dir/redream.cfg"

configure() {
  __restore_config
  ini_merge '{system_config_dir}/redream.cfg' "$redream_config_file" restore=false

  declare -A installed_files

  # Game overrides
  while read -r rom_config_file; do
    local filename=$(basename "$rom_config_file")
    local target_file="$redream_dir/cache/$filename"

    rm -fv "$target_file"
    ini_merge "$rom_config_file" "$target_file" backup=false

    installed_files["$target_file"]=1
  done < <(each_path '{system_config_dir}/redream' find '{}' -name '*.cfg')

  # Remove overrides no longer needed
  while read -r path; do
    [ "${installed_files["$path"]}" ] || rm -v "$path"
  done < <(find "$redream_dir/cache" -name '*.cfg')

  # Check for the redream premium key
  file_cp '{system_config_dir}/redream.key' "$retropie_emulators_dir/redream/redream.key"
}

restore() {
  # Restore redream key
  restore_file "$retropie_emulators_dir/redream/redream.key" delete_src=true

  # Remove game-specific overrides
  find "$redream_dir/cache" -name '*.cfg' -exec rm -fv '{}' +

  # Restore original redream config (sans input changes)
  __restore_config delete_src=true
}

__restore_config() {
  restore_partial_ini "$config_file" '^profile[0-9]+' "${@}"
}

setup "${@}"
