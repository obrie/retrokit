#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='retropie-autostart'
setup_module_desc='RetroPie autostart hook extensions'

build() {
  file_cp '{ext_dir}/autostart/autostart.sh' "$retropie_configs_dir/all/autostart.sh" envsubst=false
  mkdir -p "$retropie_configs_dir/all/autostart.d"
}

configure() {
  file_cp '{config_dir}/autostart/autostart-launch.sh' "$retropie_configs_dir/all/autostart-launch.sh" envsubst=false backup=false
}

restore() {
  rm -fv "$retropie_configs_dir/all/autostart-launch.sh"
}

remove() {
  restore_file "$retropie_configs_dir/all/autostart.sh" delete_src=true
}

setup "${@}"
