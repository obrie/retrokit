#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

install() {
  # Name of the cheats for this system
  local cheats_name=$(system_setting '.cheats')

  if [ -n "$cheats_name" ]; then
    local cheats_dir="$retroarch_config_dir/cheats"

    # Get cheat database path for this system
    local system_cheats_dir=$(crudini --get "$retropie_system_config_dir/retroarch.cfg" '' 'cheat_database_path' 2>/dev/null || true)
    system_cheats_dir="${system_cheats_dir//\"}"
    if [ -z "$system_cheats_dir" ]; then
      system_cheats_dir="$cheats_dir"
    fi
    mkdir -p "$system_cheats_dir"

    # Link the named Retroarch cheats to the emulator in the system cheats namespace
    while IFS="$tab" read emulator core_title; do
      local emulator_cheats_dir="$system_cheats_dir/$core_title"

      rm -rf "$emulator_cheats_dir"
      ln -fs "$cheats_dir/$cheats_name" "$emulator_cheats_dir"
    done < <(system_setting '.emulators | try to_entries[] | select(.value.core_title) | [.key, .value.core_title] | @tsv')
  fi
}

uninstall() {
  echo 'No uninstall for cheats'
}

"$1" "${@:3}"
