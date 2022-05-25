#!/bin/bash

system='ports'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"
. "$dir/helpers.sh"

setup_module_id='system/ports/roms-packages'
setup_module_desc='RetroPie Port installation (games ported to linux)'

build() {
  while read -r port_name; do
    local package_type=$(port_setting ".$port_name.package_type")
    local package_name=$(port_setting ".$port_name.package")

    # Install the package
    install_retropie_package "$package_type" "$package_name"
  done < <(romkit_cache_list | jq -r '.name')
}

remove() {
  while read -r port_name; do
    local package_name=$(port_setting ".$port_name.package")
    uninstall_retropie_package "$package_name" || true
  done < <(romkit_cache_list | jq -r '.name')
}

setup "${@}"
