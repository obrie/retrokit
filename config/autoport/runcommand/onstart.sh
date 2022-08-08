#!/bin/bash

declare -g default_config_path system_override_path rom_override_path

run() {
  local system=$1
  local emulator=$2
  local rom_path=$3
  local rom_filename=${rom_path##*/}
  local rom_name=${rom_filename%.*}

  # Define config paths
  default_config_path='/opt/retropie/configs/all/autoport.cfg'
  system_override_path="/opt/retropie/configs/$system/autoport.cfg"
  rom_override_path="/opt/retropie/configs/$system/autoport/$rom_name.cfg"

  # Make sure we're actually setup for autoconfiguration
  if [ "$(__setting 'autoport' 'enabled')" != 'true' ]; then
    echo 'autoport disabled'
    return
  fi

  # Determine what type of input configuration system we're dealing with
  local system_type=$(__get_system_type "$emulator")
  if [ -z "$system_type" ]; then
    echo "autoport implementation unavailable for $emulator"
    return
  fi

  # Determine which is the active profile
  local profile=$(__setting 'autoport' 'profile')
  if [ -z "$profile" ]; then
    echo 'autoport profile selection missing'
    return
  fi

  __setup_${system_type} "$profile"
}

# Looks up the given INI configuration setting, looking at all relevant paths
# including (in priority order):
# * ROM overrides
# * System overrides
# * Default config
__setting() {
  local section=$1
  local key=$2

  __find_setting "$rom_override_path" "$section" "$key" ignore_section=true || \
  __find_setting "$system_override_path" "$section" "$key" || \
  __find_setting "$default_config_path" "$section" "$key"
}

# Finds an INI configuration setting within the given path
__find_setting() {
  local path=$1
  local section=$2
  local key=$3
  local ignore_section=false
  if [ $# -gt 3 ]; then local "${@:4}"; fi

  if [ ! -f "$path" ]; then
    return 1
  fi

  # Find the relevant section
  local section
  if [ "$ignore_section" == 'true' ]; then
    section=$(cat "$path")
  else
    section=$(sed -n "/^\[$section\]/,/^\[/p" "$path")
  fi

  # Find the associated key within that section
  local value=$(echo "$section" | sed -n "s/^[ \t]*$key[ \t]*=[ \t]*\"*\([^\"\r]*\)\"*.*/\1/p" | tail -n 1)
  if [ -n "$value" ]; then
    echo "$value"
  else
    return 1
  fi
}

# Looks up what type of input configuration system we're working with.
#
# This determines how we'll enable the input priority order.
__get_system_type() {
  local emulator=$1

  if [[ "$emulator" == "lr-"* ]]; then
    echo 'libretro'
  elif [[ "$emulator" =~ (redream|drastic|ppsspp|hypseus) ]]; then
    echo "$emulator"
  fi
}

# Libretro:
#
# Set up retroarch-compatible port index overrides
__setup_libretro() {
  local profile=$1

  __setup_libretro_input "$profile" mouse mouse
  __setup_libretro_input "$profile" joystick joypad
}

# Libretro:
#
# Set up port index overrides for the provided device type
__setup_libretro_input() {
  local profile=$1
  local device_type=$2
  local retroarch_device_type=$3
  local retroarch_config_path=/dev/shm/retroarch.cfg

  # Remove any existing runtime overrides
  sed -i "/^input_player.*$retroarch_device_type/d" "$retroarch_config_path"

  while IFS=$'\t' read player_index device_index device_name; do
    echo "Player $player_index: $device_name (index $device_index)"
    echo "input_player${player_index}_${retroarch_device_type}_index = $device_index" >> "$retroarch_config_path"
  done < <(__match_players "$profile" "$device_type")
}

# Redream:
#
# Rewrites the port{index} settings in redream.cfg based on the highest
# priority matches.
__setup_redream() {
  echo 'redream autoport setup not implemented yet'
}

# PPSSPP:
#
# Sets up a *single* joystick based on the highest priority match.
__setup_ppsspp() {
  local profile=$1
  __swap_joystick_config "$profile" joystick /opt/retropie/configs/psp/PSP/SYSTEM/controls.ini
}

# Drastic:
#
# Sets up a *single* joystick based on the highest priority match.
__setup_drastic() {
  local profile=$1
  __swap_joystick_config "$profile" joystick /opt/retropie/configs/nds/drastic/config/drastic.cfg
}

# Hypseus-Singe:
#
# Sets up a *single* joystick based on the highest priority match.
__setup_hypseus() {
  local profile=$1
  __swap_joystick_config "$profile" joystick /opt/retropie/configs/daphne/hypinput.ini
}

# Swaps the primary emulator input configuration with a device-specific configuration
#
# For example, if the input config path is /opt/retropie/configs/{system}/inputs.ini,
# then this will:
#
# * Create a backup to /opt/retropie/configs/{system}/inputs.ini.autoport
# * Override the primary config path with /opt/retropie/configs/{system}/inputs-{device_name}.ini
__swap_joystick_config() {
  local profile=$1
  local device_type=$2
  local config_path=$3
  local config_backup_path="$config_path.autoport"

  local device_name=$(__match_players "$profile" "$device_type" | head -n 1 | cut -d$'\t' -f 3)
  local device_config_path="${config_path%.*}-$device_name.${config_path##*.}"

  # Always restore the original configuration file if one was found
  if [ -f "$config_backup_path" ]; then
    mv -v "$config_backup_path" "$config_path"
  fi

  if [ -z "$device_name" ]; then
    echo "No control overrides found for profile \"$profile\""
    return
  fi

  if [ ! -f "$device_config_path" ]; then
    echo "No control overrides found at path: $device_config_path"
    return
  fi

  cp -v "$config_path" "$config_backup_path"
  cp -v "$device_config_path" "$config_path"
}

# Matches player ids with device input indexes (i.e. ports)
__match_players() {
  local profile=$1
  local device_type=$2

  # Store device type information
  local devices_count=0
  declare -A devices
  while read index sysfs vendor_id product_id name; do
    devices["$index/name"]=$name
    devices["$index/sysfs"]=$sysfs
    devices["$index/vendor_id"]=$vendor_id
    devices["$index/product_id"]=$product_id
    devices_count=$index
  done < <(__list_devices "$device_type")

  # Track which player is mapped to which port
  declare -A prioritized_devices
  local priority_index=1

  # Find the priority order that's preferred for this device type
  local config_index=1
  while true; do
    # Look up what we're matching
    local config_name=$(__setting "$profile" "${device_type}${config_index}")
    if [ -z "$config_name" ]; then
      # No more devices to process
      break
    fi
    local config_vendor_id=$(__setting "$profile" "${device_type}${config_index}_vendor_id")
    local config_product_id=$(__setting "$profile" "${device_type}${config_index}_product_id")
    local config_usb_path=$(__setting "$profile" "${device_type}${config_index}_usb_path")

    # Start working our way through each connected input
    for device_index in $(seq 1 $devices_count); do
      if [ "${devices["$device_index/matched"]}" ]; then
        # Already matched this device
        continue
      fi

      # Match vendor id
      local device_vendor_id=${devices["$device_index/vendor_id"]}
      if [ -n "$config_vendor_id" ] && [[ "$device_vendor_id" != "$config_vendor_id" ]]; then
        continue
      fi

      # Match product id
      local device_product_id=${devices["$device_index/product_id"]}
      if [ -n "$config_product_id" ] && [[ "$device_product_id" != "$config_product_id" ]]; then
        continue
      fi

      # Match sysfs (usb path)
      local device_sysfs=${devices["$device_index/sysfs"]}
      if [ -n "$config_usb_path" ] && [[ "$device_sysfs" != *"$config_usb_path"* ]]; then
        continue
      fi

      # Match name
      local device_name=${devices["$device_index/name"]}
      if [ "$device_name" != "$config_name" ]; then
        continue
      fi

      # Found a match!
      devices["$device_index/matched"]=1

      # Add it to the prioritized list
      prioritized_devices[$priority_index]=$device_index
      ((priority_index+=1))
    done

    # Move onto the next matcher
    ((config_index+=1))
  done
  local prioritized_devices_count=$((priority_index-1))

  # Start identifying players!
  local player_index=1

  # See if the profile specifies the order in which the prioritized devices should
  # be matched against player numbers.  Typically, it's a 1:1 mapping (i.e. player 1
  # is priority 1).  However, in some games we want player 1 to be priority 2 and
  # player 2 to be priority 1.
  declare -a device_order
  IFS=, read -ra device_order <<< $(__setting "$profile" "${device_type}_order")
  for priority_index in "${device_order[@]}"; do
    local device_index=${prioritized_devices[$priority_index]}
    if [ -n "$device_index" ]; then
      prioritized_devices["$device_index/processed"]=1
      echo "$player_index"$'\t'"$device_index"$'\t'"${devices["$device_index/name"]}"
    fi

    ((player_index+=1))
  done

  # Once we've gone through the specific ordered devices, we process the rest here,
  # taking precaution to not list the same device a 2nd time.
  for priority_index in $(seq 1 $prioritized_devices_count); do
    if [ "${prioritized_devices["$priority_index/processed"]}" ]; then
      # Already processed this device
      continue
    fi

    local device_index=${prioritized_devices[$priority_index]}
    echo "$player_index"$'\t'"$device_index"$'\t'"${devices["$device_index/name"]}"
    ((player_index+=1))
  done
}

# Lists the *ordered* inputs of the given device type which should match the index order
# that RetroArch uses.
#
# Output is: {index}\t{sysfs}\t{vendor_id}\t{product_id}\t{name}
#
# The *index* should be used as the port number configuration for specific players.
__list_devices() {
  local device_type=$1
  __list_raw_devices | sort | grep -F $'\t'"$device_type" | cut -d$'\t' -f 1,3- | nl -d$'\t' -w1
}

# Lists the raw input devices as they appear in /proc/bus/input/devices (I think this lists
# based on the order in which the input were registered).
#
# Output is: {sysfs}\t{device_type}\t{vendor_id}\t{product_id}\t{name}
#
# Where device_type is one of:
# * joystick
# * mouse
__list_raw_devices() {
  local sysfs
  local name
  local device_type
  local vendor_id
  local product_id
 
  while read key value; do
    case $key in
      N)
        name=${value#*Name=}
        name=${name//\"/}
        ;;

      S)
        sysfs=${value#*Sysfs=}
        ;;

      H)
        local handlers=${value#*Handlers=}
        if [[ "$handlers" == *mouse* ]]; then
          device_type=mouse
        elif [[ "$handlers" == *js* ]]; then
          device_type=joystick
        fi
        ;;

      I)
        vendor_id=${value#*Vendor=}
        vendor_id=${vendor_id%% *}

        product_id=${value#*Product=}
        product_id=${product_id%% *}
        ;;

      N|P|U)
        continue
        ;;

      *)

        if [ -n "$device_type" ]; then
          echo "$sysfs"$'\t'"$device_type"$'\t'"$vendor_id"$'\t'"$product_id"$'\t'"$name"
        fi

        # Reset attributes
        sysfs=
        name=
        device_type=
        vendor_id=
        product_id=
        ;;
    esac
  done < <(cat /proc/bus/input/devices | sed s'/^\([A-Z]\): /\1\t/g')
}

run "${@}"
