#!/bin/bash

system='ports'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"
. "$dir/helpers.sh"

setup_module_id='system/ports/roms-gamefiles'
setup_module_desc='Port file installation, using files from the system-roms-download setup script'

configure() {
  # Link over any optional game files
  while IFS=$'\t' read -r port_name target_name source_path; do
    file_ln "$source_path" "$roms_dir/ports/$port_name/$target_name"
  done < <(__list_gamefiles)
}

restore() {
  while IFS=$'\t' read -r port_name target_name source_path; do
    restore "$roms_dir/ports/$port_name/$target_name"
  done < <(__list_gamefiles)
}

__list_gamefiles() {
  port_setting 'to_entries[] | .key as $name | .value | select(.files) | .files | to_entries[] | [$name, .key, .value] | @tsv'
}

setup "${@}"
