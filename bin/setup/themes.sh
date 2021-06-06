#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  # Install themes
  declare -A installed_themes
  while IFS="$tab" read -r name repo; do
    sudo "$HOME/RetroPie-Setup/retropie_packages.sh" esthemes install_theme "$name" "$repo"
    installed_themes["$name"]=1
  done < <(setting '.themes.library[] | [.name, .repo] | @tsv')

  # Uninstall unused themes
  while read name; do
    if [ ! "${installed_themes["$name"]}" ]; then
      sudo "$HOME/RetroPie-Setup/retropie_packages.sh" esthemes uninstall_theme "$name"
    fi
  done < <(ls /etc/emulationstation/themes/)

  # Add theme overrides
  while read theme_path; do
    file_cp "$config_dir/themes/$theme_path" "/etc/emulationstation/themes/$theme_path" as_sudo=true envsubst=false
  done < <(find "$config_dir/themes" -type f -printf "%P\n")
}

uninstall() {
  while IFS="$tab" read -r name repo; do
    sudo "$HOME/RetroPie-Setup/retropie_packages.sh" esthemes uninstall_theme "$name" "$repo"
  done < <(setting '.themes.library[] | [.name, .repo] | @tsv')
}

"${@}"
