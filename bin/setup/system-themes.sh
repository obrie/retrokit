#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

install() {
  local system_theme=$(system_setting '.themes.system')

  if [ -n "$system_theme" ]; then
    xmlstarlet ed -L -u "systemList/system[name=\"$system\"]/theme" -v "$system_theme" "$HOME/.emulationstation/es_systems.cfg"
    xmlstarlet ed -L -u "systemList/system[name=\"$system\"]/platform" -v "$system_theme" "$HOME/.emulationstation/es_systems.cfg"
  fi
}

uninstall() {
  local system_theme=$(system_setting '.themes.system')

  if [ -n "$system_theme" ]; then
    xmlstarlet ed -L -u "systemList/system[name=\"$system_theme\"]/platform" -v "$system" "$HOME/.emulationstation/es_systems.cfg"
    xmlstarlet ed -L -u "systemList/system[name=\"$system_theme\"]/theme" -v "$system" "$HOME/.emulationstation/es_systems.cfg"
  fi
}

"$1" "${@:3}"
