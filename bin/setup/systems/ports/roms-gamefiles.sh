#!/bin/bash

system='ports'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"
. "$dir/helpers.sh"

setup_module_id='system/ports/roms-gamefiles'
setup_module_desc='Port file installation, using files from the system-roms-download setup script'

configure() {
  # Look up which ports we have installed
  declare -A installed_ports
  while read port_name; do
    installed_ports[$port_name]=1
  done < <(romkit_cache_list | jq -r '.name')

  # Link over any optional game files
  while IFS=$'\t' read -r port_name target_name source_file; do
    if [ "${installed_ports[$port_name]}" ]; then
      file_ln "$source_file" "$roms_dir/ports/$port_name/$target_name"
    fi
  done < <(__list_gamefiles)
}

restore() {
  while IFS=$'\t' read -r port_name target_name source_file; do
    restore "$roms_dir/ports/$port_name/$target_name"
  done < <(__list_gamefiles)
}

__list_gamefiles() {
  port_setting 'to_entries[] | .key as $name | .value | select(.files) | .files | to_entries[] | [$name, .key, .value] | @tsv'
}

setup "${@}"
