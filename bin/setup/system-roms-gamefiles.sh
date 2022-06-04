#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-gamefiles'
setup_module_desc='Manage game state'

rom_dirs=($(system_setting 'select(.roms) | .roms.dirs[] | .path'))

# Attempts to find gamefiles that we aren't needed anymore
vacuum() {
  # Look up the list of currently installed ROMs
  local rom_names=$(romkit_cache_list | jq -r '.name')

  # Generate a list of possible gamefile paths
  # 
  # Note that we can only do this for path expressions that include {rom}
  # in the path.  This type of path indicates that the path is directly
  # related to the name of the ROM.  In some systems, the gamefiles are
  # based on some other identified from the ROM that we can't easily predict.
  while read path_expression; do
    declare -A gamefiles
    while read rom_name; do
      local rom_gamefile=${path_expression//'{rom}'/$rom_name}
      gamefiles["$rom_gamefile"]=1
    done < <(echo "$rom_names")

    # Generate rm commands for unused gamefiles
    path_expression=${path_expression//'{rom}'/*}
    while read -r path; do
      [ "${gamefiles["$path"]}" ] || echo "rm -rfv $(printf '%q' "$path")"
    done < <(__glob_path "$path_expression")
  done < <(__list_path_expressions | grep -F '{rom}')
}

# Removes all known gamefiles
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

# Lists the resolved gamefile path expressions
__glob_all_paths() {
  while read path_expression; do
    local path=${path_expression//'{rom}'/*}
    __glob_path "$path"
  done < <(__list_path_expressions)
}

# Lists the gamefile path expressions for the system
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

# Lists the gamefile templates defined for the system
__list_path_templates() {
  # List libretro paths
  local libretro_names=$(get_core_library_names)
  if [ -n "$libretro_names" ]; then
    system_setting '.gamefiles .retroarch_state[]'
  fi

  # List system-specific paths
  system_setting '.gamefiles | select(.state) | .state[]'
}

setup "$1" "${@:3}"
