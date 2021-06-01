#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  while IFS="$tab" read -r name repo; do
    sudo "$HOME/RetroPie-Setup/retropie_packages.sh" esthemes install_theme "$name" "$repo"
  done < <(setting '.themes.library[] | [.name, .repo] | @tsv')

  # Add theme overrides
  while read theme_path; do
    file_cp "$config_dir/themes/$theme_path" "/etc/emulationstation/$theme_path" as_sudo=true
  done < <(find "$config_dir/themes" -type f -printf "%P\n")
}

uninstall() {
  while IFS="$tab" read -r name repo; do
    sudo "$HOME/RetroPie-Setup/retropie_packages.sh" esthemes uninstall_theme "$name" "$repo"
  done < <(setting '.themes.library[] | [.name, .repo] | @tsv')
}

"${@}"
