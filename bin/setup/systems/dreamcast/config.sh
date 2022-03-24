#!/bin/bash

system='dreamcast'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='system/dreamcast/config'
setup_module_desc='Dreamcast emulator configuration'

redream_dir="$retropie_system_config_dir/redream"
redream_config_path="$redream_dir/redream.cfg"

configure() {
  __restore_config
  ini_merge '{system_config_dir}/redream.cfg' "$redream_config_path" restore=false

  declare -A installed_files

  # Game overrides
  while read -r rom_config_path; do
    local filename=$(basename "$rom_config_path")
    local target_path="$redream_dir/cache/$filename"

    rm -fv "$target_path"
    ini_merge "$rom_config_path" "$target_path" backup=false

    installed_files["$target_path"]=1
  done < <(each_path '{system_config_dir}/redream' find '{}' -name '*.cfg')

  # Remove overrides no longer needed
  while read -r path; do
    [ "${installed_files["$path"]}" ] || rm -v "$path"
  done < <(find "$redream_dir/cache" -name '*.cfg')
}

restore() {
  __restore_config delete_src=true

  # Remove game-specific overrides
  find "$redream_dir/cache" -name '*.cfg' -exec rm -fv {} +
}

__restore_config() {
  if has_backup_file "$redream_config_path"; then
    if [ -f "$redream_config_path" ]; then
      # Keep track of the profiles since we don't want to lose those
      grep -E '^profile[0-9]+' "$redream_config_path" > "$system_tmp_dir/profiles.cfg"

      restore_file "$redream_config_path" "${@}"

      # Merge the profiles back in
      crudini --merge --inplace "$redream_config_path" < "$system_tmp_dir/profiles.cfg"
      rm "$system_tmp_dir/profiles.cfg"
    else
      restore_file "$redream_config_path" "${@}"
    fi
  fi
}

setup "${@}"
