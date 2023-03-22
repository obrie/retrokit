#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-bios'
setup_module_desc='System BIOS installation'

build() {
  local bios_dir=$(system_setting '.bios.dir')
  local base_url=$(system_setting '.bios.url')

  while IFS=$'\t' read -r bios_name bios_url_template; do
    local bios_url=$(render_template "$bios_url_template" url="$base_url")
    download "$bios_url" "$bios_dir/$bios_name"
  done < <(system_setting 'select(.bios) | .bios.files | to_entries[] | [.key, .value] | @tsv')
}

remove() {
  local bios_dir=$(system_setting '.bios.dir')
  while read -r bios_name; do
    rm -fv "$bios_dir/$bios_name"
  done < <(system_setting 'select(.bios) | .bios.files | keys[]')
}

setup "${@}"
