#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='retropie-menus'
setup_module_desc='RetroPie menu visibility configuration'

gamelist_file="$HOME/.emulationstation/gamelists/retropie/gamelist.xml"

build() {
  install_retropie_package 'supplementary' 'retrokit' 'binary'
}

configure() {
  stop_emulationstation
  backup_file "$gamelist_file"

  __reconfigure_retrokit
  __hide_menus
}

__reconfigure_retrokit() {
  configure_retropie_package 'retrokit'
}

__hide_menus() {
  # Look up which menus we've enabled
  declare -A enabled_menus
  while read menu; do
    enabled_menus["$menu"]=1
  done < <(setting '.retropie .menus[]')

  if [ ${#enabled_menus[@]} -gt 0 ]; then
    while read menu; do
      if [ "${enabled_menus["$menu"]}" ]; then
        # Ensure we've removed any previously added <hidden> tag
        xmlstarlet ed --inplace -d "/gameList/game[name=\"$menu\"]/hidden" "$gamelist_file"
      else
        # Add the <hidden> tag (as long as it's not there)
        xmlstarlet ed --inplace -s "/gameList/game[name=\"$menu\"][1][not(hidden)]" -t elem -n 'hidden' -v 'true' "$gamelist_file"
      fi
    done < <(xmlstarlet sel -t -v '/gameList/game/name' "$gamelist_file")
  else
    # Show all menus
    xmlstarlet ed --inplace -d '/gameList/game/hidden' "$gamelist_file"
  fi
}

restore() {
  # Revert "hide" flag
  xmlstarlet ed --inplace -d '/gameList/game/hidden' "$gamelist_file"
}

remove() {
  uninstall_retropie_package 'retrokit'
}

setup "${@}"
