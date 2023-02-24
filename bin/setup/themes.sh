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
      sudo "$retropie_setup_dir/retropie_packages.sh" esthemes install_theme "$name" "$repo" "$branch"
    fi
  done < <(_list_installed_themes)
}

configure() {
  # Ensure we're starting with a clean slate
  restore

  # Add theme overrides
  while IFS=$'\t' read -r name repo branch; do
    while read -r theme_path; do
      file_cp "{config_dir}/themes/$name/$theme_path" "/etc/emulationstation/themes/$name/$theme_path" as_sudo=true envsubst=false
    done < <(_list_theme_override_paths "$name")
  done < <(_list_installed_themes)
}

clean() {
  declare -A installed_themes
  while IFS=$'\t' read -r name repo branch; do
    installed_themes["$name"]=1
  done < <(_list_installed_themes)

  # Remove unused themes
  while read -r name; do
    if [ ! "${installed_themes["$name"]}" ]; then
      sudo "$retropie_setup_dir/retropie_packages.sh" esthemes uninstall_theme "$name"
    fi
  done < <(ls /etc/emulationstation/themes/)
}

restore() {
  # Restore original theme
  while read backup_file; do
    restore_file "${backup_file%.rk-src*}" as_sudo=true delete_src=true
  done < <(find '/etc/emulationstation/themes' -name '*.rk-src' -o -name '*.rk-src.missing')
}

remove() {
  while IFS=$'\t' read -r name repo branch; do
    sudo "$retropie_setup_dir/retropie_packages.sh" esthemes uninstall_theme "$name"
  done < <(_list_installed_themes)
}

# Lists themes configured to be installed
_list_installed_themes() {
  setting '.themes.library[] | [.name, .repo, .branch] | @tsv'
}

# List the theme paths that are being overridden
_list_theme_override_paths() {
  local name=$1
  each_path "{config_dir}/themes/$name" find '{}' -type f -printf "%P\n"
}

setup "${@}"
