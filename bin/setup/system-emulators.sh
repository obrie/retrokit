#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

# Install emulators
install_emulators() {
  # Install packages
  while IFS="$tab" read -r emulator build branch; do
    local package_type='emulators'
    if [[ "$emulator" == lr-* ]]; then
      package_type='libretrocores'
    fi

    install_retropie_package "$package_type" "$emulator" "$build" "$branch"
  done < <(system_setting '.emulators | to_entries[] | [.key, .value.build // "binary", .value.branch // "master"] | @tsv')

  # Set defaults
  backup "$retropie_system_config_dir/emulators.cfg"
  while IFS="$tab" read -r emulator is_default; do
    if [ "$is_default" == "true" ]; then
      crudini --set "$retropie_system_config_dir/emulators.cfg" '' 'default' "\"$emulator\""
    fi
  done < <(system_setting '.emulators | to_entries[] | [.key, .value.default // false] | @tsv')
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

install() {
  install_emulators
  install_bios
}

uninstall() {
  restore "$retropie_system_config_dir/emulators.cfg"
}

"$1" "${@:3}"
