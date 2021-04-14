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
  tools-torrent
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
  themes

  # ROMs
  roms
  scrape
)

usage() {
  echo "usage: $0 <install|uninstall> <setupmodule> [args]"
  exit 1
}

before_setup() {
  stop_emulationstation
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
      "$dir/setup/system-$systemmodule.sh" "$action" "$system"
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
  "$dir/setup/$setupmodule.sh" "$action" "${@:3}"
}

main() {
  local action="$1"
  local setupmodule="$2"

  before_setup

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
