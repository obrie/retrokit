#!/bin/bash

system='ports'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

packages_path="$(conf_prepare "$system_config_dir/packages.json")"

install() {
  while IFS=$'\t' read -r port_name; do
    local package_type=$(jq -r ".$port_name.package_type" "$packages_path")
    local package_name=$(jq -r ".$port_name.package" "$packages_path")

    # Install the package
    install_retropie_package "$package_type" "$package_name"

    # Link over any optional files for the game
    while IFS=$'\t' read -r target_name source_path; do
      local target_path="$HOME/RetroPie/roms/ports/$port_name/$target_name"
      file_ln "$source_path" "$target_path"
    done < <(jq -r ".$port_name.files | try to_entries[] | [.key, .value] | @tsv" "$packages_path")
  done < <(romkit_cache_list | jq -r '[.name] | @tsv')
}

uninstall() {
  while read -r port_name; do
    local package_name=$(jq -r ".$port_name.package" "$packages_path")
    uninstall_retropie_package "$package_name" || true
  done < <(romkit_cache_list | jq -r '[.name] | @tsv')
}

"${@}"
