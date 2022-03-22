#!/bin/bash

system='arcade'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/arcade/mame-config'
setup_module_desc='MAME configuration overrides for MAME 2016 and newer'

configure() {
  restore
  __configure_mame2016
  __configure_mame
}

__configure_mame2016() {
  ini_merge '{system_config_dir}/mame2016/plugin.ini' "$HOME/RetroPie/BIOS/mame2016/ini/plugin.ini" backup=false
  ini_merge '{system_config_dir}/mame2016/ui.ini' "$HOME/RetroPie/BIOS/mame2016/ini/ui.ini" backup=false
  file_cp '{system_config_dir}/mame2016/default.cfg' "$HOME/RetroPie/roms/arcade/mame2016/cfg/default.cfg" backup=false
}

__configure_mame() {
  ini_merge '{system_config_dir}/mame/mame.ini' "$HOME/RetroPie/BIOS/mame/ini/mame.ini" backup=false
  ini_merge '{system_config_dir}/mame/plugin.ini' "$HOME/RetroPie/BIOS/mame/ini/plugin.ini" backup=false
  ini_merge '{system_config_dir}/mame/ui.ini' "$HOME/RetroPie/BIOS/mame/ini/ui.ini" backup=false
  file_cp '{system_config_dir}/mame/default.cfg' "$HOME/RetroPie/roms/arcade/mame/cfg/default.cfg" backup=false
}

restore() {
  rm -fv \
    "$HOME/RetroPie/BIOS/mame2016/ini/plugin.ini" \
    "$HOME/RetroPie/BIOS/mame2016/ini/ui.ini" \
    "$HOME/RetroPie/roms/arcade/mame2016/cfg/default.cfg" \
    "$HOME/RetroPie/BIOS/mame/ini/mame.ini" \
    "$HOME/RetroPie/BIOS/mame/ini/plugin.ini" \
    "$HOME/RetroPie/BIOS/mame/ini/ui.ini" \
    "$HOME/RetroPie/roms/arcade/mame/cfg/default.cfg"
}

setup "${@}"
