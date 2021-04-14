#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

# Install emulators
install_emulators() {
  backup_and_restore "$retropie_system_config_dir/emulators.cfg"

  while IFS="$tab" read -r emulator build branch is_default; do
    # Directories are different based on whether it's an LR core or standalone
    # emulator
    local install_dir
    local scriptmodule
    if [[ "$emulator" == lr-* ]]; then
      install_dir="/opt/retropie/libretrocores/$emulator"
      scriptmodule="$HOME/RetroPie-Setup/scriptmodules/libretrocores/$emulator.sh"
    else
      install_dir="/opt/retropie/emulators/$emulator"
      scriptmodule="$HOME/RetroPie-Setup/scriptmodules/emulators/$emulator.sh"
    fi

    # Determine whether we're updating an existing emulator or installing
    # a new one
    local mode
    if [ -d "$install_dir" ]; then
      mode='_update_'
    else
      mode=''
    fi

    if [ "$build" == "binary" ]; then
      sudo ~/RetroPie-Setup/retropie_packages.sh "$emulator" ${mode:-_binary_}
    else
      # Source install
      if [ -n "$branch" ]; then
        # Set to correct branch
        backup_and_restore "$scriptmodule"
        sed -i "s/.git master/.git $branch/g" "$scriptmodule"
      fi

      sudo __ignore_module_date=1 ~/RetroPie-Setup/retropie_packages.sh "$emulator" ${mode:-_source_}
    fi

    # Set default
    if [ "$is_default" == "true" ]; then
      crudini --set "$retropie_system_config_dir/emulators.cfg" '' 'default' "\"$emulator\""
    fi
  done < <(system_setting '.emulators | to_entries[] | [.key, .value.build // "binary", .value.branch // "master", .value.default // false] | @tsv')
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

"${@:2}"
