#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-gamestate'
setup_module_desc='Manage game state'

rom_dirs=($(system_setting 'select(.roms) | .roms.dirs[] | .path'))

# Attempts to find game state that we aren't needed anymore
vacuum() {
  load_emulator_data

  # Look up the list of currently installed ROMs
  local rom_names=$(romkit_cache_list | jq -r '[.playlist .name // .name, .emulator] | @tsv')

  # Generate a list of possible game state paths
  # 
  # Note that we can only do this for path expressions that include {rom}
  # in the path.  This type of path indicates that the path is directly
  # related to the name of the ROM.  In some systems, the game state is
  # based on some other identifier from the ROM that we can't easily predict.
  while IFS=$'\t' read emulator path_expression; do
    declare -A gamestate_files
    if [[ "$path_expression" == *'{rom}'* ]]; then
      while IFS=$'\t' read rom_name rom_emulator; do
        # Prerequisite: Ensure the ROM's emulator matches the emulator that
        # the path expression applies to
        rom_emulator=${rom_emulator:-default}
        rom_emulator=${emulators["$rom_emulator/emulator"]}

        if [ "$emulator" == 'retroarch' ]; then
          if [ -z "${emulators["$rom_emulator/core_name"]}" ]; then
            # Not a retroarch emulator -- skip
            continue
          fi
        elif [ "$emulator" != "$rom_emulator" ]; then
          # Not the same emulator -- skip
          continue
        fi

        local path=${path_expression//'{rom}'/$rom_name}
        if [[ "$path" == *'*'* ]]; then
          # Expands the glob pattern to find the specific files on disk
          while read -r expanded_path; do
            gamestate_files["$expanded_path"]=1
          done < <(__glob_path "$path")
        else
          # Reference a single rom-specific path
          gamestate_files["$path"]=1
        fi
      done < <(echo "$rom_names")
    else
      # Use the path as-is as it's likely static
      gamestate_files["$path_expression"]=1
    fi
  done < <(__list_path_expressions)

  # Generate rm commands for unused game state
  while IFS=$'\t' read emulator path_expression; do
    path_expression=${path_expression//'{rom}'/*}

    while read -r path; do
      if [ -z "${gamestate_files["$path"]}" ] && [ ! -f "$path.rk-src" ]; then
        echo "rm -rfv $(printf '%q' "$path")"
      fi
    done < <(__glob_path "$path_expression")
  done < <(__list_path_expressions | grep -F '{rom}')
}

# Removes all known game state
remove() {
  while read path; do
    if [ ! -f "$path.rk-src" ]; then
      echo "rm -rfv $(printf '%q' "$path")"
    fi
  done < <(__glob_all_paths)
}

# Lists files using the given glob
__glob_path() {
  local path=$1
  path=${path//'*'/'"*"'}
  path="\"$path\""
  eval ls -Ad $path 2>/dev/null || true
}

# Lists the resolved gamestate path expressions
__glob_all_paths() {
  while IFS=$'\t' read emulator path_expression; do
    local path=${path_expression//'{rom}'/*}
    __glob_path "$path"
  done < <(__list_path_expressions)
}

# Lists the gamestate path expressions for the system
__list_path_expressions() {
  while IFS=$'\t' read emulator path_template; do
    if [[ "$path_template" == {rom_dir}* ]]; then
      # Game file path is relative to the directory that the rom lives in
      local rom_dir
      for rom_dir in "${rom_dirs[@]}"; do
        echo "$emulator"$'\t'"${path_template/'{rom_dir}'/$rom_dir}"
      done
    else
      # Game file path is absolute
      echo "$emulator"$'\t'"$path_template"
    fi
  done < <(__list_path_templates)
}

# Lists the gamestate templates defined for the system
__list_path_templates() {
  # List libretro paths
  local libretro_names=$(get_core_library_names)
  if [ -n "$libretro_names" ]; then
    system_setting '.retroarch .gamestate[] | ["retroarch", .] | @tsv'
  fi

  # List system-specific paths
  system_setting 'select(.emulators) | .emulators | to_entries[] | select(.value.gamestate) | .key as $emulator | .value.gamestate[] | [$emulator, .] | @tsv'
}

# Disable confirmation since none of the destruction of actions in this script
# actually do anything destructive on their own.
CONFIRM=false

setup "$1" "${@:3}"
