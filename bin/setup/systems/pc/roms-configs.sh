#!/bin/bash

system="${2:-pc}"
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/pc/roms-configs'
setup_module_desc='Configure game-specific dosbox configurations'

configure() {
  __configure_confs
  __configure_mapperfiles
}

__configure_confs() {
  while IFS=$'\t' read -r rom_name rom_path; do
    ini_merge "{system_config_dir}/conf/$rom_name.conf" "$rom_path/dosbox.conf" overwrite=true space_around_delimiters=false

    # Clean up [autoexec] mess that crudini leaves behind
    crudini --del "$rom_path/dosbox.conf" autoexec

    # Write the highest priority autoexec content
    while read conf_file; do
      local autoexec_content=$(sed -n '/\[autoexec\]/,$p' "$conf_file")
      if [ -n "$autoexec_content" ]; then
        echo "$autoexec_content" >> "$rom_path/dosbox.conf"
        break
      fi
    done < <(each_path "{system_config_dir}/conf/$rom_name.conf" | tac)
  done < <(romkit_cache_list | jq -r '[.name, .path] | @tsv')
}

__configure_mapperfiles() {
  mkdir -pv "$retropie_system_config_dir/mapperfiles"

  while IFS=$'\t' read -r rom_name rom_path; do
    if ! any_path_exists "{system_config_dir}/mapperfiles/$rom_name.map"; then
      continue
    fi

    local mapperfile_target="$retropie_system_config_dir/mapperfiles/$rom_name.map"
    ini_no_delimiter_merge "{system_config_dir}/mapperfiles/dosbox.map" "$mapperfile_target" backup=false overwrite=true
    ini_no_delimiter_merge "{system_config_dir}/mapperfiles/$rom_name.map" "$mapperfile_target" backup=false

    # Remove comments since dosbox doesn't support them in mapperfiles
    sed -i '/^[ \t]*#/d' "$mapperfile_target"

    # Delete lines that have no binds (since dosbox considers those invalid)
    sed -i '/^[^ ]\+ *$/d' "$mapperfile_target"
  done < <(romkit_cache_list | jq -r '.name')
}

restore() {
  while IFS=$'\t' read -r rom_path; do
    restore_file "$rom_path/dosbox.conf" delete_src=true
  done < <(romkit_cache_list | jq -r '.path')

  find "$retropie_system_config_dir/mapperfiles" -not -name 'dosbox*.map' -exec rm -fv '{}' +
}

setup "${@}"
