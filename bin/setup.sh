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
  local action="$1"
  local setupmodule="$2"
  "$dir/setup/$setupmodule.sh" "$action"
}

main() {
  local action="$1"
  local setupmodule="$2"

  before_setup

  if [ -n "$setupmodule" ]; then
    setup "$action" "$setupmodule"
  else
    setup_all "$action"
  fi
}

if [[ $# -gt 2 ]]; then
  usage
fi

main "$@"
