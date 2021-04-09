#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup() {
  local bezelproject_bin="$HOME/RetroPie/retropiemenu/bezelproject.sh"
  download 'https://raw.githubusercontent.com/thebezelproject/BezelProject/master/bezelproject.sh' "$bezelproject_bin"
  chmod +x "$bezelproject_bin"

  # Patch to allow non-interactive mode
  sed -i -r -z 's/# Welcome.*\|\| exit/if [ -z "$1" ]; then\n\0\nfi/g' "$bezelproject_bin"
  sed -i -z 's/# Main\n\nmain_menu/# Main\n\n"${1:-main_menu}" "${@:2}"/g' "$bezelproject_bin"
}

setup
