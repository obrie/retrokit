#!/bin/bash

system='ports'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='system/ports/packages'
setup_module_desc='MAME 0.230 tools, like chdman, not available through system packages'

packages_path="$(mktemp -p "$tmp_ephemeral_dir")"
echo '{}' > "$packages_path"
json_merge '{system_config_dir}/packages.json' "$packages_path"

build() {
  while IFS=$'\t' read -r port_name; do
    local package_type=$(__port_setting ".$port_name.package_type")
    local package_name=$(__port_setting ".$port_name.package")

    # Install the package
    install_retropie_package "$package_type" "$package_name"

    # Link over any optional files for the game
    while IFS=$'\t' read -r target_name source_path; do
      local target_path="$HOME/RetroPie/roms/ports/$port_name/$target_name"
      file_ln "$source_path" "$target_path"
    done < <(__port_setting ".$port_name.files | try to_entries[] | [.key, .value] | @tsv")
  done < <(romkit_cache_list | jq -r '[.name] | @tsv')
}

remove() {
  while read -r port_name; do
    local package_name=$(__port_setting ".$port_name.package")
    uninstall_retropie_package "$package_name" || true
  done < <(romkit_cache_list | jq -r '[.name] | @tsv')
}

__port_setting() {
  jq -r "$1 | values" "$packages_path"
}

setup "${@}"
