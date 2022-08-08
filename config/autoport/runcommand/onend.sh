#!/bin/bash

run() {
  local system=$1
  local emulator=$2
  local rom_path=$3

  # Determine what type of port configuration system we're dealing with
  local system_type=$(__get_system_type "$emulator")
  if [ -z "$system_type" ]; then
    return
  fi

  # Restore any permanently modified configurations for the given system type
  __restore_${system_type}
}

# Looks up what type of port configuration system we're working with.
#
# This determines how we'll enable the port priority order.
__get_system_type() {
  local emulator=$1

  if [[ "$emulator" == "lr-"* ]]; then
    echo 'libretro'
  elif [[ "$emulator" =~ (redream|drastic|ppsspp|hypseus) ]]; then
    echo "$emulator"
  fi
}

__restore_libretro() {
  # No-op
  return
}

__restore_redream() {
  echo 'redream autoport restore not implemented yet'
}

__restore_ppsspp() {
  echo 'ppsspp autoport restore not implemented yet'
}

__restore_drastic() {
  echo 'drastic autoport restore not implemented yet'
}

__restore_hypseus() {
  echo 'hypseus autoport restore not implemented yet'
}

run "${@}"
