#!/bin/bash

system='arcade'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/arcade/mame-config'
setup_module_desc='MAME configuration overrides for MAME 2016 and newer'

configure() {
  restore
  __configure_mame2010
  __configure_mame2015
  __configure_mame2016
  __configure_mame0222
  __configure_mame0244
  __configure_mame
}

__configure_mame2010() {
  file_cp '{system_config_dir}/mame2010/mame.ini' "$bios_dir/mame2010/ini/mame.ini" backup=false
  dir_rsync '{system_config_dir}/mame/crosshair' "$bios_dir/mame2010/crosshairs"
}

__configure_mame2015() {
  file_cp '{system_config_dir}/mame2015/mame.ini' "$bios_dir/mame2015/ini/mame.ini" backup=false
  dir_rsync '{system_config_dir}/mame/crosshair' "$bios_dir/mame2015/crosshair"
}

__configure_mame2016() {
  file_cp '{system_config_dir}/mame2016/mame.ini' "$bios_dir/mame2016/ini/mame.ini" backup=false
  file_cp '{system_config_dir}/mame2016/plugin.ini' "$bios_dir/mame2016/ini/plugin.ini" backup=false
  file_cp '{system_config_dir}/mame2016/ui.ini' "$bios_dir/mame2016/ini/ui.ini" backup=false
  file_cp '{system_config_dir}/mame2016/default.cfg' "$roms_dir/arcade/mame2016/cfg/default.cfg" backup=false
  dir_rsync '{system_config_dir}/mame/crosshair' "$bios_dir/mame2016/crosshair"
}

__configure_mame0222() {
  file_cp '{system_config_dir}/mame0222/mame.ini' "$bios_dir/mame0222/ini/mame.ini" backup=false
  file_cp '{system_config_dir}/mame0222/ui.ini' "$bios_dir/mame0222/ini/ui.ini" backup=false
  file_cp "$(__find_mame_ini 0222 plugin)" "$bios_dir/mame0222/ini/plugin.ini" backup=false
  dir_rsync '{system_config_dir}/mame/crosshair' "$bios_dir/mame0222/crosshair"
}

__configure_mame0244() {
  file_cp '{system_config_dir}/mame0244/mame.ini' "$bios_dir/mame0244/ini/mame.ini" backup=false
  file_cp '{system_config_dir}/mame0244/ui.ini' "$bios_dir/mame0244/ini/ui.ini" backup=false
  file_cp "$(__find_mame_ini 0244 plugin)" "$bios_dir/mame0244/ini/plugin.ini" backup=false
  dir_rsync '{system_config_dir}/mame/crosshair' "$bios_dir/mame0244/crosshair"
}

__find_mame_ini() {
  local version=$1
  local ini_name=$2

  first_path "{system_config_dir}/mame$version/$ini_name.ini" || first_path "{system_config_dir}/mame/$ini_name.ini"
}

__configure_mame() {
  file_cp '{system_config_dir}/mame/default.cfg' "$roms_dir/arcade/mame/cfg/default.cfg" backup=false
}

restore() {
  rm -rfv \
    "$bios_dir/mame2010/ini/mame.ini" \
    "$bios_dir/mame2010/crosshairs" \
    "$bios_dir/mame2015/ini/mame.ini" \
    "$bios_dir/mame2015/crosshair" \
    "$bios_dir/mame2016/ini/mame.ini" \
    "$bios_dir/mame2016/ini/plugin.ini" \
    "$bios_dir/mame2016/ini/ui.ini" \
    "$roms_dir/arcade/mame2016/cfg/default.cfg" \
    "$bios_dir/mame2016/crosshair" \
    "$bios_dir/mame0222/ini/mame.ini" \
    "$bios_dir/mame0222/ini/plugin.ini" \
    "$bios_dir/mame0222/ini/ui.ini" \
    "$bios_dir/mame0222/crosshair" \
    "$bios_dir/mame0244/ini/mame.ini" \
    "$bios_dir/mame0244/ini/plugin.ini" \
    "$bios_dir/mame0244/ini/ui.ini" \
    "$bios_dir/mame0244/crosshair" \
    "$roms_dir/arcade/mame/cfg/default.cfg"
}

setup "${@}"
