#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

# Install emulators
install_emulators() {
  backup "$retropie_system_config_dir/emulators.cfg"

  # Install packages
  while IFS="$tab" read -r package emulator build is_default; do
    local package_type='emulators'
    if [[ "$package" == lr-* ]]; then
      package_type='libretrocores'
    fi

    install_retropie_package "$package_type" "$package" "$build"

    # Set defaults
    if [ "$is_default" == "true" ]; then
      crudini --set "$retropie_system_config_dir/emulators.cfg" '' 'default' "\"$emulator\""
    fi
  done < <(system_setting 'select(.emulators) | .emulators | to_entries[] | [.key, .value.name // .key, .value.build // "binary", .value.default // false] | @tsv')
}

# Install BIOS files required by emulators
install_bios() {
  local bios_dir=$(system_setting '.bios.dir')
  local base_url=$(system_setting '.bios.url')

  while IFS="$tab" read -r bios_name bios_url_template; do
    local bios_url="${bios_url_template/\{url\}/$base_url}"
    download "$bios_url" "$bios_dir/$bios_name"
  done < <(system_setting 'select(.bios) | .bios.files | to_entries[] | [.key, .value] | @tsv')
}

install_config() {
  local config_path="$system_config_dir/emulators.cfg"
  ini_merge "$config_path" "$retropie_system_config_dir/emulators.cfg" restore=false
}

install() {
  install_emulators
  install_bios
  install_config
}

uninstall() {
  # Remove bios files
  local bios_dir=$(system_setting '.bios.dir')
  while IFS="$tab" read -r bios_name; do
    rm -f "$bios_dir/$bios_name"
  done < <(system_setting 'select(.bios) | .bios.files | keys[]')

  # Uninstall emulators (this will automatically change the default if applicable)
  while IFS="$tab" read -r package; do
    uninstall_retropie_package "$package"
  done < <(system_setting 'select(.emulators) | .emulators | keys[]')

  # Remove any remaining custom emulators
  if [ -f "$system_config_dir/emulators.cfg" ]; then
    while read emulator; do
      crudini --del "$retropie_system_config_dir/emulators.cfg" '' "$emulator"
    done < <(crudini --get "$system_config_dir/emulators.cfg" '')
  fi
}

"$1" "${@:3}"
