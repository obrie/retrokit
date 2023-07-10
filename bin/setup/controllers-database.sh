#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='controllers-database'
setup_module_desc='Controller database (with auto conversion for xpad/triggers_to_buttons)'

sdldb_file="$retropie_configs_dir/all/gamecontrollerdb.txt"
sdldb_version="$retropie_configs_dir/all/gamecontrollerdb.version"
sdldb_repo='https://github.com/gabomdq/SDL_GameControllerDB'

autostart_dir=/opt/retropie/configs/all/autostart.d/gamecontrollerdb

# Vendor IDs used in linux to identify xbox controllers.
# 
# Source: https://github.com/paroj/xpad/blob/51af0649c2926e8992b70ca1bb506db949c6d8d9/xpad.c#L482
xpad_vendor_ids=(
  0079
  03eb
  044f
  045e
  046d
  056e
  06a3
  0738
  07ff
  0c12
  0e6f
  0f0d
  1038
  10f5
  11c9
  1209
  12ab
  1430
  146b
  1532
  15e4
  162e
  1689
  1949
  1bad
  20d6
  24c6
  2563
  260d
  2dc8
  2e24
  2f24
  31e3
  3285
)

build() {
  local gamecontrollerdb_version="$(cat "$sdldb_version" 2>/dev/null || true)"
  if [ ! -f "$sdldb_file" ] || has_newer_commit "$sdldb_repo" "$gamecontrollerdb_version"; then
    if download "$sdldb_repo/raw/master/gamecontrollerdb.txt" "$sdldb_file" force=true; then
      # Track the new version
      git ls-remote "$sdldb_repo" HEAD | cut -f1 > "$sdldb_version"
    else
      # Even if downloads fail, still allow the action to succeed if the file was
      # previously downloaded
      [ -f "$sdldb_file" ]
    fi
  else
    echo "gamecontrollerdb already the latest version ($gamecontrollerdb_version)"
  fi
}

configure() {
  backup_and_restore "$sdldb_file"
  __configure_overrides
  __configure_xpad
}

__configure_overrides() {
  each_path '{config_dir}/controllers/gamecontrollerdb.local.txt' cat '{}' | uniq | sudo tee -a "$sdldb_file" >/dev/null
}

__configure_xpad() {
  if ! grep -Eq '^options xpad triggers_to_buttons=1' /etc/modprobe.d/xpad.conf; then
    return
  fi

  echo "# START - triggers_to_buttons overrides" >> "$sdldb_file"

  # Build search for xpad-enabled vendor ids
  local sdl_vendor_ids=()
  for vendor_id in "${xpad_vendor_ids[@]}"; do
    sdl_vendor_ids+=("${vendor_id:2:2}${vendor_id:0:2}")
  done
  local sdl_vendor_ids_regex=$(IFS='|' ; echo "${sdl_vendor_ids[*]}")

  # Convert analog triggers to buttons and append to gamecontrollerdb.txt
  while read sdl_config; do
    IFS=, read -r -a sdl_properties <<< "$sdl_config"
    local id=${sdl_properties[0]}
    echo "Converting $id - ${sdl_properties[1]}"

    # The button index after which to insert the left/right trigger buttons
    local rightshoulder_index=

    # The Axis indexes of the left/right trigger which are removed
    local lefttrigger_index=
    local righttrigger_index=

    # Find the corresponding indexes
    for i in "${!sdl_properties[@]}"; do
      IFS=: read -r sdl_input_name sdl_input_value <<< "${sdl_properties[i]}"
      local sdl_input_index=${sdl_input_value//[!0-9]/}

      if [ "$sdl_input_name" == 'rightshoulder' ]; then
        rightshoulder_index=$sdl_input_index
      elif [ "$sdl_input_name" == 'lefttrigger' ]; then
        lefttrigger_index=$sdl_input_index
      elif [ "$sdl_input_name" == 'righttrigger' ]; then
        righttrigger_index=$sdl_input_index
      fi
    done

    for i in "${!sdl_properties[@]}"; do
      IFS=: read -r sdl_input_name sdl_input_value <<< "${sdl_properties[i]}"
      local sdl_input_type=${sdl_input_value:0:1}
      local sdl_input_index=${sdl_input_value:1}

      if [ "$sdl_input_name" == 'lefttrigger' ]; then
        # Move this to a button after the right shoulder
        sdl_input_type=b
        sdl_input_index=$((rightshoulder_index+1))
      elif [ "$sdl_input_name" == 'righttrigger' ]; then
        # Move this to a button after the left trigger
        sdl_input_type=b
        sdl_input_index=$((rightshoulder_index+2))
      elif [ "$sdl_input_type" == 'a' ]; then
        # Move the axis down
        if [ $sdl_input_index -gt $lefttrigger_index ]; then
          ((sdl_input_index-=1))
        fi
        if [ $sdl_input_index -gt $righttrigger_index ]; then
          ((sdl_input_index-=1))
        fi
      elif [ "$sdl_input_type" == 'b' ]; then
        # Move the button index up to account for the trigger buttons
        if [ $sdl_input_index -gt $rightshoulder_index ]; then
          ((sdl_input_index+=2))
        fi
      fi

      if [ -n "$sdl_input_value" ]; then
        # Rewrite the property
        sdl_properties[$i]="$sdl_input_name:$sdl_input_type$sdl_input_index"
      fi
    done

    # Write the new config
    local new_sdl_config=$(IFS=',' ; echo "${sdl_properties[*]}")
    echo "$new_sdl_config," >> "$sdldb_file"
  done < <(grep -E "^[0-9a-z]{8}($sdl_vendor_ids_regex)" "$sdldb_file" | grep 'lefttrigger:a' | grep 'righttrigger:a' | grep 'leftshoulder:b' | grep 'rightshoulder:b' | grep Linux)

  echo "# END - triggers_to_buttons overrides" >> "$sdldb_file"

  # Modify environment variables
  mkdir -p "$autostart_dir"
  cat > "$autostart_dir/onstart.sh" <<EOF
export SDL_GAMECONTROLLERCONFIG_FILE=$sdldb_file
EOF
  chmod 755 "$autostart_dir/onstart.sh"
}

restore() {
  restore_file "$sdldb_file" delete_src=true
  rm -rfv "$autostart_dir"
}

remove() {
  rm -fv "$sdldb_file" "$sdldb_version"
}

setup "${@}"
