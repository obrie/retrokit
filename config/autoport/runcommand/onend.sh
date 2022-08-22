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
  __restore_joystick_config /opt/retropie/configs/dreamcast/redream/redream.cfg
}

__restore_ppsspp() {
  __restore_joystick_config /opt/retropie/configs/psp/PSP/SYSTEM/controls.ini
}

__restore_drastic() {
  __restore_joystick_config /opt/retropie/configs/nds/drastic/config/drastic.cfg
}

__restore_hypseus() {
  __restore_joystick_config /opt/retropie/configs/daphne/hypinput.ini
}

__restore_mupen64plus() {
  __restore_joystick_config /opt/retropie/configs/n64/mupen64plus.cfg
}

__restore_joystick_config() {
  local config_path=$1
  local config_backup_path="$config_path.autoport"

  if [ -f "$config_backup_path" ]; then
    mv -v "$config_backup_path" "$config_path"
  fi
}

run "${@}"
