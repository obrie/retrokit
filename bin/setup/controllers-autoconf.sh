#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='controllers-autoconf'
setup_module_desc='Controller autoconfiguration'

autoconf_file="$retropie_configs_dir/all/autoconf.cfg"
autoconf_backup_file="$autoconf_file.rk-src"
sdldb_file="$tmp_dir/gamecontrollerdb.txt"
sdldb_repo='https://github.com/gabomdq/SDL_GameControllerDB'

build() {
  __build_gamecontrollerdb
}

# Download the latest game controller database
__build_gamecontrollerdb() {
  local gamecontrollerdb_version="$(cat "$tmp_dir/gamecontrollerdb.version" 2>/dev/null || true)"
  if has_newer_commit "$sdldb_repo" "$gamecontrollerdb_version"; then
    if download "$sdldb_repo/raw/master/gamecontrollerdb.txt" "$sdldb_file" force=true; then
      # Track the new version
      git ls-remote "$sdldb_repo" HEAD | cut -f1 > "$tmp_dir/gamecontrollerdb.version"
    else
      # Even if downloads fail, still allow the action to succeed if the file was
      # previously downloaded
      [ -f "$sdldb_file" ]
    fi
  else
    echo "gamecontrollerdb already the latest version ($gamecontrollerdb_version)"
  fi
}

# Run RetroPie autoconfig for each controller input
configure() {
  __configure_autoconf
  __configure_controllers
}

__configure_autoconf() {
  # Copy overrides config
  __restore_autoconf

  # Staging the changes we're going to merge in
  local autoconf_staging_file=$(mktemp -p "$tmp_ephemeral_dir")
  ini_merge '{config_dir}/controllers/autoconf.cfg' "$autoconf_staging_file" backup=false
  cp "$autoconf_staging_file" "$autoconf_backup_file"

  # Track which keys we've overridden and which we've added (so we can later restore with confidence)
  while read autoconf_key; do
    local existing_value=$(crudini --get "$autoconf_file" '' "$autoconf_key" 2>/dev/null)
    if [ -z "$existing_value" ]; then
      crudini --set "$autoconf_backup_file" '' "$autoconf_key" ''
    fi
  done < <(crudini --get "$autoconf_backup_file" '')

  # Merge in the changes
  ini_merge "$autoconf_staging_file" "$autoconf_file" backup=false
}

__configure_controllers() {
  # Combine gamecontrollerdb.txt files
  local sdldb_combined_file=$(mktemp -p "$tmp_ephemeral_dir")
  cp "$sdldb_file" "$sdldb_combined_file"
  each_path "{config_dir}/controllers/gamecontrollerdb.local.txt" cat '{}' | tee -a "$sdldb_combined_file" >/dev/null

  while IFS=, read -r name id swap_buttons; do
    local config_file=$(first_path "{config_dir}/controllers/inputs/$name.cfg")

    if [ -f "$config_file" ]; then
      # Explicit ES configuration is provided
      cp "$config_file" "$home/.emulationstation/es_temporaryinput.cfg"
    elif [ -n "$id" ] && grep -qE "^$id," "$sdldb_combined_file"; then
      # Auto-generate ES input configuration from id
      __configure_controller_input "$name" "$(grep -E "^$id," "$sdldb_combined_file" | tail -n 1)" "$swap_buttons"
    elif grep -qE ",$name," "$sdldb_combined_file"; then
      # Auto-generate ES input configuration from name
      __configure_controller_input "$name" "$(grep -E ",$name," "$sdldb_combined_file" | tail -n 1)" "$swap_buttons"
    else
      echo "No controller mapping found for $name"
      continue
    fi

    echo "Generating configurations for $name"
    "$retropie_dir/supplementary/emulationstation/scripts/inputconfiguration.sh" || true
  done < <(setting '.hardware.controllers.inputs[] | [.name, .id, .swap_buttons // false | tostring] | join(",")')
}

# Create an EmulationStation controller input configuration
# based on community-provided SDL input mappings
__configure_controller_input() {
  local name=$1
  local sdl_config=$2
  local swap_buttons=$3

  IFS=, read -r -a sdl_properties <<< "$sdl_config"
  local id=${sdl_properties[0]}
  local hotkey=$(setting '.hardware.controllers.hotkey')

  # File header
  local file="$home/.emulationstation/es_temporaryinput.cfg"
  cat > "$file" << _EOF_
<?xml version="1.0"?>
<inputList>
  <inputConfig type="joystick" deviceName="$name" deviceGUID="$id">
_EOF_

  local sdl_property
  for sdl_property in "${sdl_properties[@]}"; do
    local sdl_parts=(${sdl_property//:/ })
    local sdl_name=${sdl_parts[0]}
    local sdl_raw_value=${sdl_parts[1]}
    local sdl_type=${sdl_raw_value:0:1}
    local sdl_value=${sdl_raw_value:1:${#sdl_raw_value}}

    local input_names=''
    local input_values=''

    # Swap buttons if asked to
    if [ "$swap_buttons" == 'true' ]; then
      case "$sdl_name" in
          a)
              sdl_name=b
              ;;
          b)
              sdl_name=a
              ;;
          x)
              sdl_name=y
              ;;
          y)
              sdl_name=x
              ;;
          *)
              ;;
      esac
    fi

    # Determine the corresponding ES input name
    case "$sdl_name" in
        dpup)
            input_names=(up)
            ;;
        dpdown)
            input_names=(down)
            ;;
        dpleft)
            input_names=(left)
            ;;
        dpright)
            input_names=(right)
            ;;
        a|b|x|y|start|leftshoulder|lefttrigger|rightshoulder|righttrigger)
            input_names=($sdl_name)
            ;;
        back)
            input_names=(select)
            ;;
        leftx)
            input_names=(leftanalogleft leftanalogright)
            input_values=(-1 1)
            ;;
        lefty)
            input_names=(leftanalogup leftanalogdown)
            input_values=(-1 1)
            ;;
        rightx)
            input_names=(rightanalogleft rightanalogright)
            input_values=(-1 1)
            ;;
        righty)
            input_names=(rightanalogup rightanalogdown)
            input_values=(-1 1)
            ;;
        leftstick)
            input_names=(leftthumb)
            ;;
        rightstick)
            input_names=(rightthumb)
            ;;
        *)
            ;;
    esac

    if [ -z "$input_names" ]; then
      # Nothing corresponds -- just skip it
      continue
    fi

    # Determine the corresponding ES type/id/value
    local input_type=''
    local input_id=''
    if [ "$sdl_type" == 'b' ]; then
      # Button
      input_type='button'
      input_id=$sdl_value
      input_values=(1)
    elif [ "$sdl_type" == 'h' ]; then
      # HAT
      local hat_parts=(${sdl_value//./ })
      input_type='hat'
      input_id=${hat_parts[0]}
      input_values=(${hat_parts[1]})
    elif [ "$sdl_type" == 'a' ]; then
      # Analog
      input_type='axis'
      input_id=$sdl_value
      if [ -z "$input_values" ]; then
        input_values=(1)
      fi
    fi

    # Add input
    if [ -n "$input_type" ] && [ -n "$input_values" ]; then
      local i
      for i in "${!input_names[@]}"; do
        local input_name=${input_names[i]}
        local input_value=${input_values[i]}
        echo "    <input name=\"$input_name\" type=\"$input_type\" id=\"$input_id\" value=\"$input_value\" />" >> "$file"

        # Check if input is configured as the hotkey
        if [ "$input_name" == "$hotkey" ]; then
          echo "    <input name=\"hotkeyenable\" type=\"$input_type\" id=\"$input_id\" value=\"$input_value\" />" >> "$file"
        fi
      done
    fi
  done

  # File footer
  cat >> "$file" << _EOF_
  </inputConfig>
</inputList>
_EOF_
}

restore() {
  __restore_inputs
  __restore_autoconf
}

# Reset inputs
__restore_inputs() {
  local has_configured_inputs=$(setting '.hardware.controllers.inputs | length > 0')
  if [ "$has_configured_inputs" == 'true' ]; then
    sudo "$retropie_setup_dir/retropie_packages.sh" emulationstation clear_input
  fi
}

__restore_autoconf() {
  if [ -f "$autoconf_backup_file" ]; then
    # Restore original values for the keys we overrode
    while read -r key; do
      local value=$(crudini --get "$autoconf_backup_file" '' "$key")
      if [ -z "$value" ]; then
        crudini --del "$autoconf_file" '' "$key"
      else
        crudini --set "$autoconf_file" '' "$key" "$value"
      fi
    done < <(crudini --get "$autoconf_backup_file" '')

    # Remove the backup since we're now fully restored
    rm -v "$autoconf_backup_file"
  fi
}

remove() {
  rm -fv "$sdldb_file" "$tmp_dir/gamecontrollerdb.version"
}

setup "${@}"
