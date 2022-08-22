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

  __find_setting "$rom_override_path" "$section" "$key" || \
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
  if echo "$section" | grep -Eq "^[ \t]*$key[ \t]*"; then
    echo "$section" | sed -n "s/^[ \t]*$key[ \t]*=[ \t]*\"*\([^\"\r]*\)\"*.*/\1/p" | tail -n 1
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
  elif [[ "$emulator" =~ ^(redream|drastic|ppsspp|hypseus|mupen64plus) ]]; then
    echo "${BASH_REMATCH[1]}"
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

  __match_players "$profile" "$device_type"

  for player_index in "${player_indexes[@]}"; do
    local device_index=${players["$player_index/device_index"]}
    local device_type=${players["$player_index/device_type"]}

    echo "Player $player_index: index $device_index"
    echo "input_player${player_index}_${retroarch_device_type}_index = \"$device_index\"" >> "$retroarch_config_path"

    if [ -n "$device_type" ]; then
      echo "input_libretro_device_p${player_index} = \"$device_type\"" >> "$retroarch_config_path"
    fi
  done
}

# Redream:
#
# Rewrites the port{index} settings in redream.cfg based on the highest
# priority matches.
__setup_redream() {
  local profile=$1
  local config_path=/opt/retropie/configs/dreamcast/redream/redream.cfg
  local config_backup_path="$config_path.autoport"

  # Restore config backup
  if [ -f "$config_backup_path" ]; then
    mv -v "$config_backup_path" "$config_path"
  fi

  __match_players "$profile" joystick
  if [ ${#player_indexes[@]} -eq 0 ]; then
    # No matches found, use defaults
    return
  fi

  # Create config backup
  cp -v "$config_path" "$config_backup_path"

  for player_index in "${player_indexes[@]}"; do
    local device_index=${players["$player_index/device_index"]}
    local device_type=${players["$player_index/device_type"]:-controller}
    local device_guid=${devices["$device_index/guid"]}

    # Indexes are offset by 4
    # * 0 = auto
    # * 1 = disabled
    # * 2 = keyboard
    # * 3 = unknown
    ((device_index+=4))

    # Players start at offset 0
    ((player_index-=1))

    echo "Player $player_index: index $device_index"

    # Remove existing setting
    sed -i "/^port${player_index}=/d" "$config_path"

    # Add new setting
    echo "port${player_index}=dev:${device_index},desc:${device_guid},type:${device_type}" >> "$config_path"
  done
}

# PPSSPP:
#
# Sets up a *single* joystick based on the highest priority match.
__setup_ppsspp() {
  local profile=$1
  local config_path=/opt/retropie/configs/psp/PSP/SYSTEM/controls.ini
  local device_config_path=$(__prepare_config_overwrite "$profile" joystick "$config_path")
  if [ -z "$device_config_path" ]; then
    return
  fi

  # Remove joystick configurations
  sed -i 's/10-[0-9]*\|,//g' "$config_path"

  # Merge in those from the device
  while read key separator value; do
    # Merge with existing value
    sed -i "/^$key *= *1/ s/\$/,$value/" "$config_path"

    # ...or set on its own
    sed -i "/^$key *= *\$/ s/\$/$value/" "$config_path"
  done < <(cat "$device_config_path" | grep -Ev '^ *#')
}

# Drastic:
#
# Sets up a *single* joystick based on the highest priority match.
__setup_drastic() {
  local profile=$1
  local config_path=/opt/retropie/configs/nds/drastic/config/drastic.cfg
  local device_config_path=$(__prepare_config_overwrite "$profile" joystick "$config_path")
  if [ -z "$device_config_path" ]; then
    return
  fi

  # Remove joystick configurations
  sed -i '/controls_b/d' "$config_path"

  # Merge in those from the device
  cat "$device_config_path" | tee -a "$config_path" >/dev/null
}

# Hypseus-Singe:
#
# Sets up a *single* joystick based on the highest priority match.
__setup_hypseus() {
  local profile=$1
  local config_path=/opt/retropie/configs/daphne/hypinput.ini
  local device_config_path=$(__prepare_config_overwrite "$profile" joystick "$config_path")
  if [ -z "$device_config_path" ]; then
    return
  fi

  # Remove joystick configurations (and default to 0)
  sed -i 's/^\([^ ]\+\) = \([^ ]\+\) \([^ ]\+\).*$/\1 = \2 \3 0/g' "$config_path"

  # Merge in those from the device
  while read key separator button axis; do
    local joystick_value=$button
    if [ -n "$axis" ]; then
      joystick_value="$joystick_value $axis"
    fi

    sed -i "s/^$key = \([^ ]\+\) \([^ ]\+\).*\$/$key = \1 \2 $joystick_value/g" "$config_path"
  done < <(cat "$device_config_path" | grep -Ev '^ *#')
}

# Mupen64plus:
#
# Rewrites the Input-SDL-Control{index} settings in mupen64plus.cfg based on the
# highest priority matches.
__setup_mupen64plus() {
  local profile=$1
  local config_path=/opt/retropie/configs/n64/mupen64plus.cfg
  local config_backup_path="$config_path.autoport"
  local auto_config_path=/opt/retropie/configs/n64/InputAutoCfg.ini

  # Restore config backup
  if [ -f "$config_backup_path" ]; then
    mv -v "$config_backup_path" "$config_path"
  fi

  __match_players "$profile" joystick
  if [ ${#player_indexes[@]} -eq 0 ]; then
    # No matches found, use defaults
    return
  fi

  # Create config backup
  cp -v "$config_path" "$config_backup_path"

  local auto_config_keys=(
    'A Button'
    'AnalogDeadzone'
    'AnalogPeak'
    'B Button'
    'C Button D'
    'C Button L'
    'C Button R'
    'C Button U'
    'DPad D'
    'DPad L'
    'DPad R'
    'DPad U'
    'L Trig'
    'Mempark switch'
    'mouse'
    'plugged'
    'plugin'
    'R Trig'
    'Rumblepak switch'
    'Start'
    'X Axis'
    'Y Axis'
    'Z Trig'
  )

  for player_index in "${player_indexes[@]}"; do
    local device_index=${players["$player_index/device_index"]}
    local device_name=${devices["$device_index/name"]}
    local player_section="Input-SDL-Control$player_index"

    # Remove the existing section for this player
    sed -i "/^\[$player_section\]/, /\[/ { //"'!'"d }; /^\[$player_section\]/d" "$config_path"

    # Start the new section
    cat >> "$config_path" << _EOF_
[$player_section]
version = 2.000000
mode = 0
device = $device_index
name = "$device_name"
_EOF_

    # Add auto-configuration values
    for auto_config_key in "${auto_config_keys[@]}"; do
      local value=$(__find_setting "$auto_config_path" "$device_name" "$auto_config_key")
      echo "$auto_config_key = \"$value\"" >> "$config_path"
    done
  done
}

# Prepares the primary emulator input configuration to be merged with a
# device-specific configuration
#
# For example, if the input config path is /opt/retropie/configs/{system}/inputs.ini,
# then this will:
#
# * Restore a backup if it already exists at /opt/retropie/configs/{system}/inputs.ini.autoport
# * Create a backup to /opt/retropie/configs/{system}/inputs.ini.autoport
# * Print the expected device-specific configuration path
__prepare_config_overwrite() {
  local profile=$1
  local device_type=$2
  local config_path=$3
  local config_backup_path="$config_path.autoport"

  __match_players "$profile" "$device_type"

  local device_index=${players["1/device_index"]}
  local device_name=${devices["$device_index/name"]}
  local device_config_path="${config_path%.*}-$device_name.${config_path##*.}"

  # Always restore the original configuration file if one was found
  if [ -f "$config_backup_path" ]; then
    mv "$config_backup_path" "$config_path"
  fi

  if [ -z "$device_name" ]; then
    >&2 echo "No control overrides found for profile \"$profile\""
    return 1
  fi

  if [ ! -f "$device_config_path" ]; then
    >&2 echo "No control overrides found at path: $device_config_path"
    return 1
  fi

  cp "$config_path" "$config_backup_path"

  echo "$device_config_path"
}

# Matches player ids with device input indexes (i.e. ports)
__match_players() {
  local profile=$1
  local device_type=$2

  # Shared variables
  declare -Ag devices=()
  declare -Ag players=()
  declare -ag player_indexes=()

  # Store device type information
  local devices_count=0
  while read index sysfs bus vendor_id product_id version name; do
    devices["$index/name"]=$name
    devices["$index/sysfs"]=$sysfs
    devices["$index/bus"]=$bus
    devices["$index/vendor_id"]=$vendor_id
    devices["$index/product_id"]=$product_id
    devices["$index/version"]=$version
    devices["$index/guid"]="${bus:2:2}${bus:0:2}0000${vendor_id:2:2}${vendor_id:0:2}0000${product_id:2:2}${product_id:0:2}0000${version:2:2}${version:0:2}0000"
    devices_count=$((index+1))
  done < <(__list_devices "$device_type")

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
    local config_name=$(__setting "$profile" "${device_type}${config_index}")
    if [ -z "$config_name" ]; then
      # No more devices to process
      break
    fi
    local config_vendor_id=$(__setting "$profile" "${device_type}${config_index}_vendor_id")
    local config_product_id=$(__setting "$profile" "${device_type}${config_index}_product_id")
    local config_usb_path=$(__setting "$profile" "${device_type}${config_index}_usb_path")
    local config_related_usb_path=$(__setting "$profile" "${device_type}${config_index}_related_usb_path")
    local config_device_type=$(__setting "$profile" "${device_type}${config_index}_device_type")
    local config_limit=$(__setting "$profile" "${device_type}${config_index}_limit")

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

      # Match related usb path
      if [ -n "$config_related_usb_path" ] && { [[ "$device_sysfs" != *usb* ]] || ! find "/sys$device_sysfs/../../../.." | grep -Eq "$config_related_usb_path"; }; then
        continue
      fi

      # Match name
      local device_name=${devices["$device_index/name"]}
      if [ "$device_name" != "$config_name" ]; then
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

  # Overall player matching limit
  local player_limit=$(__setting "$profile" "${device_type}_limit")

  # Start identifying players!
  local player_index_start=$(__setting "$profile" "${device_type}_start")
  local player_index=${player_index_start:-1}

  # See if the profile specifies the order in which the prioritized devices should
  # be matched against player numbers.  Typically, it's a 1:1 mapping (i.e. player 1
  # is priority 1).  However, in some games we want player 1 to be priority 2 and
  # player 2 to be priority 1.
  declare -a device_order
  IFS=, read -ra device_order <<< $(__setting "$profile" "${device_type}_order")
  if [ ${#device_order[@]} -gt 0 ]; then
    for priority_index in "${device_order[@]}"; do
      if [ -n "$priority_index" ] && [ "$priority_index" != 'nul' ]; then
        local device_index=${prioritized_devices[$priority_index]}

        if [ -n "$device_index" ]; then
          # Found a matching device: update the player
          players["$player_index/device_index"]=$device_index
          player_indexes+=($player_index)
        fi
      fi

      ((player_index+=1))
    done
  else
    # No order was specified -- use a 1:1 mapping between player
    # and priority.
    for priority_index in $(seq 1 $prioritized_devices_count); do
      local device_index=${prioritized_devices[$priority_index]}
      players["$player_index/device_index"]=$device_index

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
# Output is: {index}\t{sysfs}\t{bus}\t{vendor_id}\t{product_id}\t{version}\t{name}
#
# The *index* should be used as the port number configuration for specific players.
__list_devices() {
  local device_type=$1
  __list_raw_devices | sort | grep -F $'\t'"$device_type" | cut -d$'\t' -f 1,3- | nl -d$'\t' -v0 -w1
}

# Lists the raw input devices as they appear in /proc/bus/input/devices (I think this lists
# based on the order in which the input were registered).
#
# Output is: {sysfs}\t{device_type}\t{bus}\t{vendor_id}\t{product_id}\t{version}\t{name}
#
# Where device_type is one of:
# * joystick
# * mouse
__list_raw_devices() {
  local sysfs
  local name
  local device_type
  local bus
  local vendor_id
  local product_id
  local version
 
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
        bus=${value#*Bus=}
        bus=${bus%% *}

        vendor_id=${value#*Vendor=}
        vendor_id=${vendor_id%% *}

        product_id=${value#*Product=}
        product_id=${product_id%% *}

        version=${value#*Version=}
        version=${version%% *}
        ;;

      N|P|U)
        continue
        ;;

      *)

        if [ -n "$device_type" ]; then
          echo "$sysfs"$'\t'"$device_type"$'\t'"$bus"$'\t'"$vendor_id"$'\t'"$product_id"$'\t'"$version"$'\t'"$name"
        fi

        # Reset attributes
        sysfs=
        name=
        device_type=
        bus=
        vendor_id=
        product_id=
        version=
        ;;
    esac
  done < <(cat /proc/bus/input/devices | sed s'/^\([A-Z]\): /\1\t/g')
}

run "${@}"
