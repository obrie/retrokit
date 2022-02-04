#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  # Install themes
  declare -A installed_themes
  while IFS=$'\t' read -r name repo; do
    sudo "$HOME/RetroPie-Setup/retropie_packages.sh" esthemes install_theme "$name" "$repo"
    installed_themes["$name"]=1
  done < <(_list_installed_themes)

  # Uninstall unused themes
  while read -r name; do
    if [ ! "${installed_themes["$name"]}" ]; then
      sudo "$HOME/RetroPie-Setup/retropie_packages.sh" esthemes uninstall_theme "$name"
    fi
  done < <(ls /etc/emulationstation/themes/)

  configure
}

configure() {
  # Add theme overrides
  while read -r theme_path; do
    file_cp "$config_dir/themes/$theme_path" "/etc/emulationstation/themes/$theme_path" as_sudo=true envsubst=false
  done < <(_list_theme_override_paths)
}

restore() {
  # Restore original theme
  while read -r theme_path; do
    restore_file "/etc/emulationstation/themes/$theme_path" as_sudo=true delete_src=true
  done < <(_list_theme_override_paths)
}

# Lists themes configured to be installed
_list_installed_themes() {
  setting '.themes.library[] | [.name, .repo] | @tsv'
}

# List the theme paths that are being overridden
_list_theme_override_paths() {
  find "$config_dir/themes" -type f -printf "%P\n"
}

uninstall() {
  while IFS=$'\t' read -r name repo; do
    sudo "$HOME/RetroPie-Setup/retropie_packages.sh" esthemes uninstall_theme "$name" "$repo"
  done < <(_list_installed_themes)
}

"${@}"
