#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

setupmodules=(
  # Initial setup
  deps
  wifi
  upgrade
  boot

  # Tools
  tools-dev
  tools-chdman

  # Cases
  case-argon
  ir

  # Authentication
  auth-internetarchive

  # Remote access
  ssh
  vnc

  # Display
  display
  localization
  splashscreen

  # RetroPie
  scriptmodules

  # EmulationStation
  emulationstation
  scraper
  themes

  # Retroarch
  retroarch
  overlays
  cheats

  # Controllers
  bluetooth

  # RetroPie
  runcommand

  # ROM Management
  romkit
)

systemmodules=(
  # Emulator configurations
  emulators
  retroarch

  # Gameplay
  cheats

  # Themes
  bezels
  launchimages

  # ROMs
  roms
  scrape
)

usage() {
  echo "usage: $0 <install|uninstall> <setupmodule> [args]"
  exit 1
}

setup_all() {
  local action="$1"

  for setupmodule in "${setupmodules[@]}"; do
    setup "$setupmodule" "$actions"
  done

  # Add systems
  "$dir/setup/system-all.sh" restore_globals
  while read system; do
    for systemmodule in "${systemmodules[@]}"; do
      # Ports only get the scrape module
      if [ "$systemmodule" == 'scrape' ] || [ "$system" != 'ports' ]; then
        "$dir/setup/system-$systemmodule.sh" "$action" "$system"
      fi
    done

    # System-specific actions
    if [ -f "$dir/setup/systems/$system.sh" ]; then
      "$dir/setup/systems/$system.sh" "$action"
    fi
  done < <(setting '.systems[]')
}

setup() {
  local action="$1"
  local setupmodule="$2"
  if [ -z "$3" ] && [[ "$setupmodule" == system-* ]]; then
    # Run setup module for all systems
    while read system; do
      "$dir/setup/$setupmodule.sh" "$action" "$system"
    done < <(setting '.systems[]')
  else
    # Run individual script
    "$dir/setup/$setupmodule.sh" "$action" "${@:3}"
  fi
}

main() {
  local action="$1"
  local setupmodule="$2"

  if [ -n "$setupmodule" ]; then
    setup "$action" "$setupmodule" "${@:3}"
  else
    setup_all "$action"
  fi
}

if [[ $# -lt 1 ]]; then
  usage
fi

main "$@"
