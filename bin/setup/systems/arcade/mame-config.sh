#!/bin/bash

system='arcade'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/arcade/mame-config'
setup_module_desc='MAME configuration overrides for MAME 2016 and newer'

configure() {
  __configure_mame2016
  __configure_mame
}

__configure_mame2016() {
  file_cp "$system_config_dir/mame2016/plugin.ini" "$HOME/RetroPie/BIOS/mame2016/ini/plugin.ini"
  file_cp "$system_config_dir/mame2016/ui.ini" "$HOME/RetroPie/BIOS/mame2016/ini/ui.ini"
  file_cp "$system_config_dir/mame2016/default.cfg" "$HOME/RetroPie/roms/arcade/mame2016/cfg/default.cfg"
}

__configure_mame() {
  file_cp "$system_config_dir/mame/mame.ini" "$HOME/RetroPie/BIOS/mame/ini/mame.ini"
  file_cp "$system_config_dir/mame/plugin.ini" "$HOME/RetroPie/BIOS/mame/ini/plugin.ini"
  file_cp "$system_config_dir/mame/ui.ini" "$HOME/RetroPie/BIOS/mame/ini/ui.ini"
  file_cp "$system_config_dir/mame/default.cfg" "$HOME/RetroPie/roms/arcade/mame/cfg/default.cfg"
}

restore() {
  restore "$HOME/RetroPie/BIOS/mame2016/ini/plugin.ini" delete_src=true
  restore "$HOME/RetroPie/BIOS/mame2016/ini/ui.ini" delete_src=true
  restore "$HOME/RetroPie/roms/arcade/mame2016/cfg/default.cfg" delete_src=true
  restore "$HOME/RetroPie/BIOS/mame/ini/mame.ini" delete_src=true
  restore "$HOME/RetroPie/BIOS/mame/ini/plugin.ini" delete_src=true
  restore "$HOME/RetroPie/BIOS/mame/ini/ui.ini" delete_src=true
  restore "$HOME/RetroPie/roms/arcade/mame/cfg/default.cfg" delete_src=true
}

setup "${@}"
