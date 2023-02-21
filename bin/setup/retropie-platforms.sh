#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='retropie-platforms'
setup_module_desc='RetroPie platform metadata'

configure() {
  ini_merge '{config_dir}/retropie/platforms.cfg' "$retropie_configs_dir/all/platforms.cfg"
}

restore() {
  restore_file "$retropie_configs_dir/all/platforms.cfg" delete_src=true
}

setup "${@}"
