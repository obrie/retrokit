#!/bin/bash

system="${2:-pc}"
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/pc/roms-configs'
setup_module_desc='Configure game-specific dosbox configurations'

configure() {
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

restore() {
  while IFS=$'\t' read -r rom_path; do
    restore_file "$rom_path/dosbox.conf" delete_src=true
  done < <(romkit_cache_list | jq -r '.path')
}

setup "${@}"
