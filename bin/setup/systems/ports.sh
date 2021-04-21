#!/bin/bash

set -ex

system='ports'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../system-common.sh"

install() {
  while IFS="$tab" read -r port_name package_name package_type; do
    install_retropie_package "$package_type" "$package_name"

    # Link over any optional files for the game
    while read -r target_name source_path; do
      local target_path="$HOME/RetroPie/roms/ports/$port_name/$target_name"
      file_ln "$source_path" "$target_path"
    done < <(system_setting '.ports.$port_name.files | try to_entries[] | [.key, .value] | @tsv')
  done < <(system_setting '.ports | to_entries[] | [.key, .value.package, .value.package_type] | @tsv')
}

uninstall() {
  echo 'No uninstall for ports'
}

"${@}"
