#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

install() {
  __install_emulators
  __install_bios
  configure
}

# Install emulator packages
__install_emulators() {
  while IFS=$'\t' read -r package emulator build; do
    local package_type='emulators'
    if [[ "$package" == lr-* ]]; then
      package_type='libretrocores'
    fi

    install_retropie_package "$package_type" "$package" "$build"
  done < <(system_setting 'select(.emulators) | .emulators | to_entries[] | [.key, .value.name // .key, .value.build // "binary"] | @tsv')
}

# Install BIOS files required by emulators
__install_bios() {
  local bios_dir=$(system_setting '.bios.dir')
  local base_url=$(system_setting '.bios.url')

  while IFS=$'\t' read -r bios_name bios_url_template; do
    local bios_url="${bios_url_template/\{url\}/$base_url}"
    download "$bios_url" "$bios_dir/$bios_name"
  done < <(system_setting 'select(.bios) | .bios.files | to_entries[] | [.key, .value] | @tsv')
}

# Configure emulator settings
configure() {
  backup_file "$retropie_system_config_dir/emulators.cfg"

  # Set default emulator
  local default_emulator=$(system_setting 'select(.emulators) | .emulators | to_entries[] | select(.value.default == true) | .value.name // .key')
  crudini --set "$retropie_system_config_dir/emulators.cfg" '' 'default' "\"$default_emulator\""

  # Additional emulator settings
  ini_merge "$system_config_dir/emulators.cfg" "$retropie_system_config_dir/emulators.cfg" restore=false
}

restore() {
  # Remove any custom emulator settings
  if [ -f "$system_config_dir/emulators.cfg" ] && [ -f "$retropie_system_config_dir/emulators.cfg" ]; then
    while read -r emulator; do
      crudini --del "$retropie_system_config_dir/emulators.cfg" '' "$emulator"
    done < <(crudini --get "$system_config_dir/emulators.cfg" '')
  fi
}

uninstall() {
  # Remove bios files
  local bios_dir=$(system_setting '.bios.dir')
  while read -r bios_name; do
    rm -fv "$bios_dir/$bios_name"
  done < <(system_setting 'select(.bios) | .bios.files | keys[]')

  # Uninstall emulators (this will automatically change the default if applicable)
  while read -r package; do
    uninstall_retropie_package "$package" || true
  done < <(system_setting 'select(.emulators) | .emulators | keys[]')

  restore
}

"$1" "${@:3}"
