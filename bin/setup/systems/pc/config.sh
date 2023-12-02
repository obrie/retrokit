#!/bin/bash

system='pc'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='system/pc/config'
setup_module_desc='PC emulator configuration'
setup_module_reconfigure_after_update=true

configure() {
  __configure_conf
  __configure_mapperfiles
}

__configure_conf() {
  ini_merge '{system_config_dir}/dosbox-staging.conf' "$retropie_system_config_dir/dosbox-staging.conf"
}

__configure_mapperfiles() {
  mkdir -p "$retropie_system_config_dir/mapperfiles"
  each_path '{system_config_dir}/mapperfiles' find '{}' -name '*.map' -exec cp -v -t "$retropie_system_config_dir/mapperfiles/" '{}' +
  sed -i '/^[ \t]*#/d' "$retropie_system_config_dir/mapperfiles/"*.map
}

restore() {
  restore_file "$retropie_system_config_dir/dosbox-staging.conf" delete_src=true
  rm -rfv "$retropie_system_config_dir/mapperfiles"
}

setup "${@}"
