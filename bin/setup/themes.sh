#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='themes'
setup_module_desc='Theme management and overrides'

build() {
  # Install configured themes
  while IFS=$'\t' read -r name repo branch; do
    # Only install if not already installed -- updates are done externally
    if [ ! -d "/etc/emulationstation/themes/$name" ] || [ "$FORCE_UPDATE" == 'true' ]; then
      sudo "$HOME/RetroPie-Setup/retropie_packages.sh" esthemes install_theme "$name" "$repo" "$branch"
    fi
  done < <(_list_installed_themes)
}

configure() {
  # Ensure we're starting with a clean slate
  restore

  # Add theme overrides
  while read -r theme_path; do
    file_cp "$config_dir/themes/$theme_path" "/etc/emulationstation/themes/$theme_path" as_sudo=true envsubst=false
  done < <(_list_theme_override_paths)
}

clean() {
  declare -A installed_themes
  while IFS=$'\t' read -r name repo branch; do
    installed_themes["$name"]=1
  done < <(_list_installed_themes)

  # Remove unused themes
  while read -r name; do
    if [ ! "${installed_themes["$name"]}" ]; then
      sudo "$HOME/RetroPie-Setup/retropie_packages.sh" esthemes uninstall_theme "$name"
    fi
  done < <(ls /etc/emulationstation/themes/)
}

restore() {
  # Restore original theme
  while read backup_file; do
    restore_file "${backup_file%.rk-src*}"
  done < <(find '/etc/emulationstation/themes' -name '*.rk-src' -o -name '*.rk-src.missing')
}

remove() {
  while IFS=$'\t' read -r name repo branch; do
    sudo "$HOME/RetroPie-Setup/retropie_packages.sh" esthemes uninstall_theme "$name"
  done < <(_list_installed_themes)
}

# Lists themes configured to be installed
_list_installed_themes() {
  setting '.themes.library[] | [.name, .repo, .branch] | @tsv'
}

# List the theme paths that are being overridden
_list_theme_override_paths() {
  find "$config_dir/themes" -type f -printf "%P\n"
}

setup "${@}"
