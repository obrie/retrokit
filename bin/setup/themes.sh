#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  while IFS="$tab" read -r name repo; do
    sudo "$HOME/RetroPie-Setup/retropie_packages.sh" esthemes install_theme "$name" "$repo"
  done < <(setting '.themes.library[] | [.name, .repo] | @tsv')
}

uninstall() {
  while IFS="$tab" read -r name repo; do
    sudo "$HOME/RetroPie-Setup/retropie_packages.sh" esthemes uninstall_theme "$name" "$repo"
  done < <(setting '.themes.library[] | [.name, .repo] | @tsv')
}

"${@}"
