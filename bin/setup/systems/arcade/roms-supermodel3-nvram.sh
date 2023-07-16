#!/bin/bash

system="${2:-arcade}"
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/arcade/roms-supermodel3-nvram'
setup_module_desc='SuperModel3 nvram data'

nvram_dir="$retropie_configs_dir/supermodel3/NVRAM"

configure() {
  while read -r rom_name; do
    local nvram_path=$(first_path "{cache_dir}/supermodel3/NVRAM/$rom_name.nv")

    if [ -n "$nvram_path" ]; then
      file_cp "$nvram_path" "$nvram_dir/$rom_name.nv"
    fi
  done < <(romkit_cache_list | jq -r 'select(.emulator == "supermodel3") | .name')
}

restore() {
  rm -rfv "$nvram_dir"/*
}

setup "${@}"
