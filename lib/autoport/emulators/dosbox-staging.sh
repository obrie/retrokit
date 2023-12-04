#!/usr/bin/env bash

# Rewrites the joystick binds in the default (or game-specific) mapperfile based on the highest
# priority matches.
__setup_dosbox-staging() {
  local profile=$1
  local driver_name=$2
  [[ "$driver_name" =~ mouse|keyboard ]] && return

  local mapperfile_relative_path=$(__find_setting "$rom_path" '' 'mapperfile' || __find_setting "$retropie_configs_dir/pc/dosbox-staging.conf" '' 'mapperfile')
  mapperfile="$retropie_configs_dir/pc/$mapperfile_relative_path"
  if [ ! -f "$mapperfile" ]; then
    # No mapperfile found, use defaults
    return
  fi

  __match_players "$profile" "$driver_name"
  if [ ${#player_indexes[@]} -eq 0 ]; then
    # No matches found, use defaults
    return
  fi

  # Back up the mapperfile
  local mapperfile_backup="$mapperfile.autoport"
  cp -vn "$mapperfile" "$mapperfile_backup"

  # Map RetroPie autoconfig names to the corresponding dosbox binding
  declare -A autoconfig_key_to_bind
  autoconfig_key_to_bind=(
    [leftanalogleft]='axis 0 0'
    [leftanalogright]='axis 0 1'
    [leftanalogup]='axis 1 0'
    [leftanalogdown]='axis 1 1'
    [lefttrigger]='axis 2 2'
    [rightanalogleft]='axis 3 0'
    [rightanalogright]='axis 3 1'
    [rightanalogup]='axis 4 0'
    [rightanalogdown]='axis 4 1'
    [righttrigger]='axis 5 2'
    [a]='button 0'
    [b]='button 1'
    [x]='button 2'
    [y]='button 3'
    [leftshoulder]='button 4'
    [rightshoulder]='button 5'
    [select]='button 6'
    [start]='button 7'
    [leftthumb]='button 9'
    [rightthumb]='button 10'
    [up]='hat 0 1'
    [right]='hat 0 2'
    [down]='hat 0 4'
    [left]='hat 0 8'
  )

  for player_index in 1 2; do
    local emulator_player_index=$((player_index-1))

    # Get the configuration file for a specific player number
    local device_config_file=$(__device_config_for_player "$retropie_configs_dir/pc/autoconfig/.conf" "$player_index")
    if [ -z "$device_config_file" ]; then
      # No device-specific overrides -- use the defaults
      continue
    fi

    local device_index=${players["$player_index/device_index"]}

    while read autoconfig_key new_bind; do
      # Replace the old bind
      local old_bind=${autoconfig_key_to_bind[$autoconfig_key]}

      sed -i "s/stick_${emulator_player_index} $old_bind/stick_${device_index}-staging $new_bind/g" "$mapperfile"
    done < <(cat "$device_config_file" | tr -d '"')

    # Removing staging names
    sed -i 's/-staging//g' "$mapperfile"
  done
}

__restore_dosbox-staging() {
  local mapperfile_relative_path=$(__find_setting "$rom_path" '' 'mapperfile' || __find_setting "$retropie_configs_dir/pc/dosbox-staging.conf" '' 'mapperfile')
  mapperfile="$retropie_configs_dir/pc/$mapperfile_relative_path"

  __restore_joystick_config "$mapperfile"
}
