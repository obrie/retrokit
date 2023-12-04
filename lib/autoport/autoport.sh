#!/bin/bash

declare -g \
  system emulator rom_path rom_filename rom_name rom_command \
  default_config_file system_override_file emulator_override_file rom_override_file \
  joystick_profile mouse_profile keyboard_profile

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
retropie_configs_dir=/opt/retropie/configs

# Allows individual systems to override what metadata is for
# input devices.  This is helpful for dealing with non-libretro
# systems that may use metadata from other frameworks like X11.
declare -A input_overrides

usage() {
  echo "usage: $0 <setup|restore> <system_name> <emulator_name> <rom_path> <runcommand>"
  exit 1
}

# Initializes the autoport context
init() {
  [ "$#" -eq 4 ] || usage

  system=$1
  emulator=$2
  rom_path=$3
  rom_command=$4
  rom_filename=${rom_path##*/}
  rom_name=${rom_filename%.*}

  local autoport_script="${dir}/emulators/$(__get_system_type).sh"
  if [ -f "$autoport_script" ]; then
    source "$autoport_script"
  fi
}

# Sets up the port configurations for the given system running the
# given emulator / rom
# 
# * system - Name of the system (e.g. arcade)
# * emulator - Name of the emulator (e.g. lr-fbneo)
# * rom_path - Path to the ROM being loaded
setup() {
  init "${@}"

  # Define config paths
  default_config_file="$retropie_configs_dir/all/autoport.cfg"
  system_override_file="$retropie_configs_dir/$system/autoport.cfg"
  emulator_override_file="$retropie_configs_dir/$system/autoport/emulators/$emulator.cfg"
  rom_override_file="$retropie_configs_dir/$system/autoport/$rom_name.cfg"

  # Determine what type of input configuration system we're dealing with
  local system_type=$(__get_system_type)
  if [ -z "$system_type" ]; then
    echo "autoport implementation unavailable for $emulator"
    return
  fi

  # Always make sure we restore first in case there's something left behind
  __restore_${system_type}

  # Make sure we're actually setup for autoconfiguration
  if [ "$(__setting 'autoport' 'enabled')" != 'true' ]; then
    echo 'autoport disabled'
    return
  fi

  local default_profile=$(__setting 'autoport' 'profile')
  joystick_profile=$(__setting 'autoport' 'joystick_profile' || __setting "$default_profile" 'joystick_profile' || echo "$default_profile")
  mouse_profile=$(__setting 'autoport' 'mouse_profile' || __setting "$default_profile" 'mouse_profile' || echo "$default_profile")
  keyboard_profile=$(__setting 'autoport' 'keyboard_profile' || __setting "$default_profile" 'keyboard_profile' || echo "$default_profile")

  # Joystick setup
  if [ -n "$joystick_profile" ]; then
    __setup_${system_type} "$joystick_profile" joystick
  else
    echo 'autoport joystick profile selection missing'
  fi

  # Mouse setup
  if [ -n "$mouse_profile" ]; then
    __setup_${system_type} "$mouse_profile" mouse
  else
    echo 'autoport mouse profile selection missing'
  fi

  # Keyboard setup
  if [ -n "$keyboard_profile" ]; then
    __setup_${system_type} "$keyboard_profile" keyboard
  else
    echo 'autoport keyboard profile selection missing'
  fi
}

# Looks up the given INI configuration setting, looking at all relevant paths
# including (in priority order):
# * ROM overrides
# * System overrides
# * Default config
__setting() {
  local section=$1
  local key=$2

  __find_setting "$rom_override_file" "$section" "$key" || \
  __find_setting "$emulator_override_file" "$section" "$key" || \
  __find_setting "$system_override_file" "$section" "$key" || \
  __find_setting "$default_config_file" "$section" "$key"
}

# Finds an INI configuration setting within the given path
__find_setting() {
  local path=$1
  local section=$2
  local key=$3
  if [ $# -gt 3 ]; then local "${@:4}"; fi

  if [ ! -f "$path" ]; then
    return 1
  fi

  # Find the relevant section
  local section_content
  if [ -n "$section" ]; then
    section_content=$(sed -n "/^\[$section\]/,/^\[/p" "$path")
  else
    section_content=$(cat "$path")
  fi

  # Find the associated key within that section
  if echo "$section_content" | grep -Eq "^[ \t]*$key[ \t]*="; then
    echo "$section_content" | sed -n "s/^[ \t]*$key[ \t]*=[ \t]*\"*\([^\"\r]*\)\"*.*/\1/p" | tail -n 1
  else
    return 1
  fi
}

# Looks up what type of input configuration system we're working with.
#
# This determines how we'll enable the input priority order.
__get_system_type() {
  if [[ "$emulator" == "lr-"* ]]; then
    echo 'libretro'
  elif [[ "$emulator" =~ ^(redream|drastic|ppsspp|hypseus|mupen64plus|supermodel3|dosbox-staging) ]]; then
    echo "${BASH_REMATCH[1]}"
  fi
}

# Sets input overrides based on how X11 interprets input devices.
# 
# Specifically, X11 has some different logic around what's considered a
# "mouse" (or pointer) device.  Typically this would involve just looking
# for a mouse handler, but X11 reads the input's attributes and interprets
# them differently.
__setup_x11() {
  local driver_name=$1

  if [ "$driver_name" == 'mouse' ]; then
    local xinput_outfile=$(mktemp)
    local xinput_initfile=$(mktemp)
    echo "exec xinput list > $xinput_outfile" > "$xinput_initfile"

    # Use devices as reported by X11
    # It would be nice to be able to interpret this just from device capabilities
    # (and not have to launch a dummy X session), but I haven't figured out how
    # to do that reliably yet
    if [ -f /etc/X11/dummy.conf ]; then
      # dummy drivers are faster in X11 (almost 2x), but require that the appropriate
      # configure file be present on the filesystem relative to /etc/X11
      xinit "$xinput_initfile" -- /usr/bin/X -config dummy.conf
    else
      local tty_path=$(tty)
      xinit "$xinput_initfile" -- vt${tty_path:8:1} -keeptty
    fi

    while read input_name; do
      input_overrides["$input_name/driver_name"]='mouse'
    done < <(cat "$xinput_outfile" | grep pointer | grep slave | grep -Ev XTEST | cut -d$'\t' -f 1 | grep -oE '[a-zA-Z]+.+$')

    rm -f "$xinput_outfile" "$xinput_initfile"
  else
    input_overrides=()
  fi
}

# Prepares the primary emulator input configuration to be merged with a
# device-specific configuration
#
# For example, if the input config path is /opt/retropie/configs/{system}/inputs.ini,
# then this will:
#
# * Create a backup to /opt/retropie/configs/{system}/inputs.ini.autoport (if one doesn't already exist)
# * Print the expected device-specific configuration path
__prepare_config_overwrite() {
  local profile=$1
  local driver_name=$2
  local config_file=$3
  local config_backup_file="$config_file.autoport"

  __match_players "$profile" "$driver_name"

  local device_index=${players["1/device_index"]}
  local device_name=${devices["$device_index/name"]}
  if [ -z "$device_name" ]; then
    >&2 echo "No control overrides found for profile \"$profile\""
    return 1
  fi

  local device_config_file=$(__device_config_for_player "$config_file" 1)
  if [ ! -f "$device_config_file" ]; then
    >&2 echo "No control overrides found at path: $device_config_file"
    return 1
  fi

  # Create config backup (only if one doesn't already exist)
  cp -n "$config_file" "$config_backup_file"

  echo "$device_config_file"
}

# Look up the device-specific configuration file for the given player
__device_config_for_player() {
  local config_file=$1
  local player_index=$2

  local device_index=${players["$player_index/device_index"]}
  local device_name=${devices["$device_index/name"]}

  if [ -n "$device_name" ]; then
    local prefix=${config_file%.*}
    local extension=${config_file##*.}
    local safe_device_name=${device_name//[:><?\"\/\\|*]/}

    local device_config_file
    if [ -d "$prefix" ]; then
      device_config_file="${prefix}/${safe_device_name}.${extension}"
    else
      device_config_file="${prefix}-${safe_device_name}.${extension}"
    fi

    if [ -f "$device_config_file" ]; then
      echo "$device_config_file"
    else
      return 1
    fi
  else
    return 1
  fi
}

# Matches player ids with device input indexes (i.e. ports)
__match_players() {
  local profile=$1
  local driver_name=$2

  # Shared variables
  declare -Ag devices=()
  declare -Ag players=()
  declare -ag player_indexes=()

  # Store device type information
  local devices_count=0
  while IFS=$'\t' read index sysfs bus vendor_id product_id version name uniq_id; do
    devices["$index/name"]=$name
    devices["$index/sysfs"]=$sysfs
    devices["$index/bus"]=$bus
    devices["$index/vendor_id"]=$vendor_id
    devices["$index/product_id"]=$product_id
    devices["$index/version"]=$version
    devices["$index/uniq_id"]=$uniq_id
    devices["$index/guid"]="${bus:2:2}${bus:0:2}0000${vendor_id:2:2}${vendor_id:0:2}0000${product_id:2:2}${product_id:0:2}0000${version:2:2}${version:0:2}0000"
    devices_count=$((index+1))
  done < <(__list_devices "$driver_name")

  if [ $devices_count -eq 0 ]; then
    # No devices found
    return
  fi

  # Track which player is mapped to which port
  declare -A prioritized_devices
  local priority_index=1

  # Find the priority order that's preferred for this device type
  local config_index=1
  while true; do
    # Look up what we're matching
    local config_name=$(__setting "$profile" "${driver_name}${config_index}")
    if [ -z "$config_name" ]; then
      # No more devices to process
      break
    fi
    local config_vendor_id=$(__setting "$profile" "${driver_name}${config_index}_vendor_id")
    local config_product_id=$(__setting "$profile" "${driver_name}${config_index}_product_id")
    local config_usb_path=$(__setting "$profile" "${driver_name}${config_index}_usb_path")
    local config_related_usb_path=$(__setting "$profile" "${driver_name}${config_index}_related_usb_path")
    local config_device_id=$(__setting "$profile" "${driver_name}${config_index}_device_id")
    local config_running_process=$(__setting "$profile" "${driver_name}${config_index}_running_process")
    local config_limit=$(__setting "$profile" "${driver_name}${config_index}_limit")
    local config_device_type=$(__setting "$profile" "${driver_name}${config_index}_set_device_type" || __setting "$profile" "${driver_name}_set_device_type")

    # Track how many matches we've found for this config in case there's a limit
    local matched_count=0

    # Start working our way through each connected input
    for device_index in $(seq 0 $((devices_count-1))); do
      if [ "${devices["$device_index/matched"]}" ]; then
        # Already matched this device
        continue
      fi

      # Match vendor id
      local device_vendor_id=${devices["$device_index/vendor_id"]}
      if [ -n "$config_vendor_id" ] && [[ ! "${device_vendor_id,,}" =~ ${config_vendor_id,,} ]]; then
        continue
      fi

      # Match product id
      local device_product_id=${devices["$device_index/product_id"]}
      if [ -n "$config_product_id" ] && [[ ! "${device_product_id,,}" =~ ${config_product_id,,} ]]; then
        continue
      fi

      # Match sysfs (usb path)
      local device_sysfs=${devices["$device_index/sysfs"]}
      if [ -n "$config_usb_path" ] && [[ ! "${device_sysfs,,}" =~ ${device_sysfs,,} ]]; then
        continue
      fi

      local device_id=${devices["$device_index/uniq_id"]}
      if [ -n "$config_device_id" ] && [[ ! "${device_id,,}" =~ ${config_device_id,,} ]]; then
        continue
      fi

      # Match related usb path
      if [ -n "$config_related_usb_path" ] && { [[ "$device_sysfs" != *usb* ]] || ! find "/sys$device_sysfs/../../../.." | grep -Eiq "$config_related_usb_path"; }; then
        continue
      fi

      # Match running process
      if [ -n "$config_running_process" ] && ! pgrep -fi "$config_running_process" >/dev/null; then
        continue
      fi

      # Match name
      local device_name=${devices["$device_index/name"]}
      if [[ ! "${device_name,,}" =~ ${config_name,,} ]]; then
        continue
      fi

      # Found a match!
      devices["$device_index/matched"]=1
      devices["$device_index/device_type"]=$config_device_type
      ((matched_count+=1))

      # Add it to the prioritized list
      prioritized_devices[$priority_index]=$device_index
      ((priority_index+=1))

      # Stop going through the inputs if we've hit our limit
      if [ -n "$config_limit" ] && [ $matched_count -ge $config_limit ]; then
        break
      fi
    done

    # Move onto the next matcher
    ((config_index+=1))
  done
  local prioritized_devices_count=$((priority_index-1))

  # See if the profile specifies the order in which the prioritized devices should
  # be matched against player numbers.  Typically, it's a 1:1 mapping (i.e. player 1
  # is priority 1).  However, in some games we want player 1 to be priority 2 and
  # player 2 to be priority 1.
  declare -a device_order
  IFS=, read -ra device_order <<< $(__setting "$profile" "${driver_name}_order")
  if [ ${#device_order[@]} -gt 0 ]; then
    # Assume we always start at Player 1
    local player_index=1

    for priority_index in "${device_order[@]}"; do
      if [ -n "$priority_index" ] && [ "$priority_index" != 'nul' ]; then
        local device_index=${prioritized_devices[$priority_index]}

        if [ -n "$device_index" ]; then
          # Determine player-specific device type override
          local default_default_type=${devices["$device_index/device_type"]}
          local player_device_type=$(__setting "$profile" "${driver_name}_set_device_type_p$player_index" || echo "$default_default_type")

          # Found a matching device: update the player
          players["$player_index/device_index"]=$device_index
          players["$player_index/device_type"]=$player_device_type
          player_indexes+=($player_index)
        fi
      fi

      ((player_index+=1))
    done
  else
    # No order was specified -- use a 1:1 mapping between player
    # and priority.

    # Overall player matching limit
    local player_limit=$(__setting "$profile" "${driver_name}_limit")

    # Identify which player numbers we're skipping
    local player_skip=$(__setting "$profile" "${driver_name}_skip")

    # Start identifying players!
    local player_index_start=$(__setting "$profile" "${driver_name}_start")
    local player_index=${player_index_start:-1}

    for priority_index in $(seq 1 $prioritized_devices_count); do
      # Increment the player index until we have one that isn't skipped
      while [[ "$player_skip" =~ (^|,)$player_index($|,) ]]; do
        ((player_index+=1))
      done

      local device_index=${prioritized_devices[$priority_index]}

      # Determine player-specific device type override
      local player_device_type=$(__setting "$profile" "${driver_name}_set_device_type_p$player_index")
      player_device_type=${player_device_type:-${devices["$device_index/device_type"]}}

      players["$player_index/device_index"]=$device_index
      players["$player_index/device_type"]=$player_device_type

      player_indexes+=($player_index)
      ((player_index+=1))

      # Stop going through the players if we've hit our limit
      if [ -n "$player_limit" ] && [ ${#player_indexes[@]} -ge $player_limit ]; then
        return
      fi
    done
  fi
}

# Lists the *ordered* inputs of the given device type which should match the index order
# that RetroArch uses.
#
# Output is: {index}\t{sysfs}\t{bus}\t{vendor_id}\t{product_id}\t{version}\t{name}\t{uniq}
#
# The *index* should be used as the port number configuration for specific players.
__list_devices() {
  local driver_name=$1
  __list_raw_devices | sort | grep -F $'\t'"$driver_name" | cut -d$'\t' -f 1,3- | nl -d$'\t' -v0 -w1
}

# Lists the raw input devices as they appear in /proc/bus/input/devices (I think this lists
# based on the order in which the input were registered).
#
# Output is: {sysfs}\t{driver_name}\t{bus}\t{vendor_id}\t{product_id}\t{version}\t{name}\t{uniq}
#
# Where driver_name is one of:
# * joystick
# * mouse
__list_raw_devices() {
  local sysfs
  local name
  local driver_name
  local event_name
  local bus
  local vendor_id
  local product_id
  local version
  local uniq
 
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
          driver_name=mouse
        elif [[ "$handlers" == *js* ]]; then
          driver_name=joystick
        fi

        if [[ "$handlers" =~ event[0-9]+ ]]; then
          event_name=${BASH_REMATCH[0]}
        fi
        ;;

      I)
        bus=${value#*Bus=}
        bus=${bus%% *}

        vendor_id=${value#*Vendor=}
        vendor_id=${vendor_id%% *}

        product_id=${value#*Product=}
        product_id=${product_id%% *}

        version=${value#*Version=}
        version=${version%% *}
        ;;

      U)
        uniq=${value#*Uniq=}
        ;;

      N|P)
        continue
        ;;

      *)
        if [ -n "$name" ] && [ "${#input_overrides[@]}" -ne 0 ]; then
          driver_name=${input_overrides["$name/driver_name"]}
        fi

        # Conditions required for an input to be considered:
        # * It's a mouse or joystick
        # * It has a corresponding /dev/input/eventX path
        # * The eventX path is readable
        if [ -n "$driver_name" ] && [ -n "$event_name" ] && [ -r "/dev/input/$event_name" ]; then
          echo "$sysfs"$'\t'"$driver_name"$'\t'"$bus"$'\t'"$vendor_id"$'\t'"$product_id"$'\t'"$version"$'\t'"$name"$'\t'"$uniq"
        fi

        # Reset attributes
        sysfs=
        name=
        driver_name=
        event_name=
        bus=
        vendor_id=
        product_id=
        version=
        uniq=
        ;;
    esac
  done < <(cat /proc/bus/input/devices | sed s'/^\([A-Z]\): /\1\t/g')
}

# Restores the emulator configuration back to how it was originally set up
# prior to the overrides introduced by autoport
restore() {
  init "${@}"

  # Determine what type of port configuration system we're dealing with
  local system_type=$(__get_system_type)
  if [ -z "$system_type" ]; then
    return
  fi

  # Restore any permanently modified configurations for the given system type
  __restore_${system_type}
}

__restore_joystick_config() {
  local config_file=$1
  local config_backup_file="$config_file.autoport"

  if [ -f "$config_backup_file" ]; then
    mv -v "$config_backup_file" "$config_file"
  fi
}

[ "$#" -gt 0 ] || usage

# Primary entrypoints:
# * setup
# * restore
"${@}"
