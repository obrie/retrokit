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
  mkdir -pv "$retropie_system_config_dir/mapperfiles"

  while read mapperfile_name; do
    local mapperfile_target="$retropie_system_config_dir/mapperfiles/$mapperfile_name"
    ini_no_delimiter_merge "{system_config_dir}/mapperfiles/$mapperfile_name" "$mapperfile_target" backup=false overwrite=true

    # Remove comments since dosbox doesn't support them in mapperfiles
    sed -i '/^[ \t]*#/d' "$mapperfile_target"

    # Delete lines that have no binds (since dosbox considers those invalid)
    sed -i '/^[^ ]\+ *$/d' "$mapperfile_target"
  done < <(each_path '{system_config_dir}/mapperfiles' find '{}' -name 'dosbox*.map' -exec basename {} .conf \; | sort | uniq)
}

restore() {
  restore_file "$retropie_system_config_dir/dosbox-staging.conf" delete_src=true
  rm -rfv "$retropie_system_config_dir/mapperfiles/dosbox*.map"
}

setup "${@}"
