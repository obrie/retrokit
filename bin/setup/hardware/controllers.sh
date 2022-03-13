#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../common.sh"

setup_module_id='hardware/controllers'
setup_module_desc='Controller autoconfiguration'

configscripts_dir='/opt/retropie/supplementary/emulationstation/scripts/configscripts'

build() {
  # Add autoconfig scripts
  while read -r autoconfig_name; do
    sudo cp -v "$bin_dir/controllers/autoconfig/$autoconfig_name.sh" "$configscripts_dir/"
  done < <(setting '.hardware.controllers.autoconfig[]')
}

# Run RetroPie autoconfig for each controller input
configure() {
  # Copy overrides config
  sudo cp "$config_dir/retroarch/autoconfig-overrides.cfg" "$configscripts_dir/autoconfig-overrides.cfg"

  # Always update to the latest game controller database
  local sdldb_path="$tmp_dir/gamecontrollerdb.txt"
  download 'https://github.com/gabomdq/SDL_GameControllerDB/raw/master/gamecontrollerdb.txt' "$sdldb_path" force=true || [ -f "$sdldb_path" ]

  while IFS=, read -r name id swap_buttons; do
    local config_file="$config_dir/controllers/inputs/$name.cfg"

    if [ -f "$config_file" ]; then
      # Explicit ES configuration is provided
      cp "$config_file" "$HOME/.emulationstation/es_temporaryinput.cfg"
    elif [ -n "$id" ] && grep -qE "^$id," "$sdldb_path"; then
      # Auto-generate ES input configuration from id
      __configure_controller_input "$name" "$(grep -E "^$id," "$sdldb_path")" "$swap_buttons"
    elif grep -qE ",$name," "$sdldb_path"; then
      # Auto-generate ES input configuration from name
      __configure_controller_input "$name" "$(grep -E ",$name," "$sdldb_path")" "$swap_buttons"
    else
      echo "No controller mapping found for $name"
      continue
    fi

    echo "Generating configurations for $name"
    /opt/retropie/supplementary/emulationstation/scripts/inputconfiguration.sh || true
  done < <(setting '.hardware.controllers.inputs[] | [.name, .id, .swap_buttons // false | tostring] | join(",")')
}

# Create an EmulationStation controller input configuration
# based on community-provided SDL input mappings
__configure_controller_input() {
  local name=$1
  local sdl_config=$2
  local swap_buttons=$3

  IFS=',' read -r -a sdl_properties <<< "$sdl_config"
  local id=${sdl_properties[0]}
  local hotkey=$(setting '.hardware.controllers.hotkey')

  # File header
  local file="$HOME/.emulationstation/es_temporaryinput.cfg"
  cat > "$file" << _EOF_
<?xml version="1.0"?>
<inputList>
  <inputConfig type="joystick" deviceName="$name" deviceGUID="$id">
_EOF_

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
    fi

    # Add input
    if [ -n "$input_type" ] && [ -n "$input_values" ]; then
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
  # Reset inputs
  sudo "$HOME/RetroPie-Setup/retropie_packages.sh" emulationstation clear_input
}

remove() {
  # Remove autoconfig overrides
  sudo rm -fv "$configscripts_dir/autoconfig-overrides.cfg"

  # Remove autoconfig scripts
  while read -r autoconfig_name; do
    sudo rm -fv "$configscripts_dir/$autoconfig_name.sh"
  done < <(setting '.hardware.controllers.autoconfig[]')
}

setup "${@}"
