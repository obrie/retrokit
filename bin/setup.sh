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

  # EmulationStation
  emulationstation
  scraper
  themes

  # Retroarch
  retroarch
  overlays
  cheats

  # RetroPie
  runcommand

  # ROM Management
  romkit
)

usage() {
  echo "usage: $0 [command]"
  exit 1
}

install_dependencies() {
  # Ini editor
  sudo pip3 install crudini

  # Env editor
  download 'https://raw.githubusercontent.com/bashup/dotenv/master/dotenv' "$tmp_dir/dotenv"

  # JSON reader
  sudo apt install -y jq
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
  while read system; do
    "$dir/setup/system.sh" "$system" setup
  done < <(setting '.systems[]')
}

setup() {
  local setupmodule="$1"
  local action="$2"
  "$dir/setup/$setupmodule.sh" "$2"
}

after_setup() {
  emulationstation
}

setup() {
  # Reset inputs
  sudo $HOME/RetroPie-Setup/retropie_packages.sh emulationstation init_input
}

main() {
  local setupmodule="$1"
  local action="$2"

  before_setup

  if [ -n "$setupmodule" ]; then
    setup "$setupmodule" "$action"
  else
    setup_all "$action"
  fi

  after_setup
}

if [[ $# -gt 1 ]]; then
  usage
fi

main "$@"
