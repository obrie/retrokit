#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-collections'
setup_module_desc='Creates EmulationStation custom collections'

es_collections_dir="$HOME/.emulationstation/collections"
readarray -t rom_dirs < <(system_setting 'select(.roms) | .roms.dirs[] | .path')

configure() {
  restore

  mkdir -pv "$es_collections_dir"

  # Track which collections / playlists we've installed
  declare -A installed_collections
  declare -A installed_playlists

  while IFS=» read -r name playlist_name install_path collections_dsv; do
    local collections
    IFS=» read -r -a collections <<< "$collections_dsv"

    local rom_path
    if [ -z "$playlist_name" ]; then
      local rom_filename=$(basename "$install_path")
      rom_path=$(__find_in_directories "$rom_filename")
    else
      if [ "${installed_playlists["$playlist_name"]}" ]; then
        # Already installed playlist -- skip
        continue
      fi

      rom_path=$(__find_in_directories "$playlist_name.m3u")
      installed_playlists["$playlist_name"]=1
    fi

    if [ -f "$rom_path" ]; then
      for collection_name in "${collections[@]}"; do
        local collection_path="$es_collections_dir/$collection_name.cfg"
        echo "Adding $rom_path to $collection_path"
        echo "$rom_path" >> "$collection_path"

        installed_collections[$collection_name]=1
      done
    fi
  done < <(romkit_cache_list | jq -r '[.name, .playlist .name, .path, (.collections | join ("»"))] | join("»")' | sort)

  # Sort the modified collections
  for collection_name in "${!installed_collections[@]}"; do
    local collection_path="$es_collections_dir/$collection_name.cfg"
    sort -o "$collection_path" "$collection_path"
  done
}

# Finds file in the system's configured rom directories
__find_in_directories() {
  local rom_dir
  for rom_dir in "${rom_dirs[@]}"; do
    path=$(find "$rom_dir" -mindepth 1 -maxdepth 1 -name "$1" -print -quit)
    if [ -n "$path" ]; then
      echo "$path"
      return
    fi
  done
}

restore() {
  if [ ! -d "$es_collections_dir" ]; then
    return
  fi

  while read collection_path; do
    # Remove this system from the given collection
    sed -i "/\/$system\//d" "$collection_path"

    # Delete the collection if it's now empty
    if [ ! -s "$collection_path" ]; then
      rm -fv "$collection_path"
    fi
  done < <(find "$es_collections_dir" -name '*.cfg')
}

setup "${@}"
