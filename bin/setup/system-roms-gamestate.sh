#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-gamestate'
setup_module_desc='Manage game state'

rom_dirs=($(system_setting 'select(.roms) | .roms.dirs[] | .path'))

# Attempts to find game state that we aren't needed anymore
vacuum() {
  # Look up the list of currently installed ROMs
  local rom_names=$(romkit_cache_list | jq -r '.playlist .name // .name')

  # Identify paths that can be vacuumed since they're predictable
  local path_expressions=$(__list_path_expressions | grep -F '{rom}')
  if [ -z "$path_expressions" ]; then
    return
  fi

  # Generate a list of possible game state paths
  # 
  # Note that we can only do this for path expressions that include {rom}
  # in the path.  This type of path indicates that the path is directly
  # related to the name of the ROM.  In some systems, the game state is
  # based on some other identified from the ROM that we can't easily predict.
  while read path_expression; do
    declare -A gamestate_files
    while read rom_name; do
      local path=${path_expression//'{rom}'/$rom_name}
      if [[ "$path" == *'*'* ]]; then
        # Expands the glob pattern to find on the specific files on disk
        while read -r expanded_path; do
          gamestate_files["$expanded_path"]=1
        done < <(__glob_path "$path")
      else
        gamestate_files["$path"]=1
      fi
    done < <(echo "$rom_names")
  done < <(echo "$path_expressions")

  # Generate rm commands for unused game state
  while read path_expression; do
    path_expression=${path_expression//'{rom}'/*}

    while read -r path; do
      [ "${gamestate_files["$path"]}" ] || echo "rm -rfv $(printf '%q' "$path")"
    done < <(__glob_path "$path_expression")
  done < <(echo "$path_expressions")
}

# Removes all known game state
remove() {
  while read path; do
    echo "rm -rfv $(printf '%q' "$path")"
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
  while read path_expression; do
    local path=${path_expression//'{rom}'/*}
    __glob_path "$path"
  done < <(__list_path_expressions)
}

# Lists the gamestate path expressions for the system
__list_path_expressions() {
  while read path_template; do
    if [[ "$path_template" == {rom_dir}* ]]; then
      # Game file path is relative to the directory that the rom lives in
      local rom_dir
      for rom_dir in "${rom_dirs[@]}"; do
        echo "${path_template/'{rom_dir}'/$rom_dir}"
      done
    else
      # Game file path is absolute
      echo "$path_template"
    fi
  done < <(__list_path_templates)
}

# Lists the gamestate templates defined for the system
__list_path_templates() {
  # List libretro paths
  local libretro_names=$(get_core_library_names)
  if [ -n "$libretro_names" ]; then
    system_setting '.gamestate .retroarch_files[]'
  fi

  # List system-specific paths
  system_setting '.gamestate | select(.files) | .files[]'
}

# Disable confirmation since none of the destruction of actions in this script
# actually do anything destructive on their own.
CONFIRM=false

setup "$1" "${@:3}"
