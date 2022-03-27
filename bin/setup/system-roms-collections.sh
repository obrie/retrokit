#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-collections'
setup_module_desc='Creates EmulationStation custom collections'

target_collections_dir="$HOME/.emulationstation/collections"
rom_dirs=($(system_setting 'select(.roms) | .roms.dirs[] | .path'))

declare -A installed_collections

configure() {
  mkdir -pv "$target_collections_dir"

  __create_custom_collections
  __create_romkit_collections
  __cleanup_unused_collections
}

# Creates collections defined by custom, pre-defined emulationstation file
__create_custom_collections() {
  while read -r collection_path; do
    local name=$(basename "$collection_path" '.tsv')
    __create_collection "$name" "$collection_path"
  done < <(each_path '{config_dir}/emulationstation/collections' find '{}' -name '*.tsv')
}

# Creates collections defined by metadata in romkit selections
__create_romkit_collections() {
  while read -r name; do
    __create_collection "custom-$name" <(romkit_cache_list | jq -r "select(.collections | index(\"$name\")) | [\"$system\", .title] | @tsv" | uniq)
  done < <(romkit_cache_list | jq -r '.collections[]' | sort | uniq)
}

# Creates the collection defined by the given file
__create_collection() {
  local collection_name=$1
  local source_collection_path=$2

  # Remove any existing entries for this system from the collection
  local target_collection_path="$target_collections_dir/$collection_name.cfg"
  if [ -f "$target_collection_path" ]; then
    sed -i "/\/$system\//d" "$target_collection_path"
  fi

  # Mark this collection as being managed by retrokit
  installed_collections["$collection_name"]=1
  touch "$target_collection_path.rk-src"

  # Track which titles are in this collection
  declare -A collection_titles
  while IFS=$'\t' read -r rom_title; do
    collection_titles["$rom_title"]=1
  done < <(grep -E "^$system"$'\t' "$source_collection_path" | cut -d$'\t' -f 2)

  # Track which playlists we've installed
  declare -A installed_playlists

  while IFS=» read -r name title parent_title playlist_name install_path; do
    if [ -z "${collection_titles["$title"]}" ] && { [ -z "$parent_title" ] || [ -z "${collection_titles["$parent_title"]}" ]; }; then
      # Not in the collection -- skip
      continue
    fi

    # ROMs in collection files contain just the title in order to work
    # for different regions, so we find the first installed ROM that matches
    # (the ROM could be present in multiple directories and we only want one in
    # the collection)
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
      echo "Adding $rom_path to $target_collection_path"
      echo "$rom_path" >> "$target_collection_path"
    fi
  done < <(romkit_cache_list | jq -r '[.name, .title, .parent .title, .playlist .name, .path] | join("»")' | sort)

  # Sort the collection at the end
  sort -o "$target_collection_path" "$target_collection_path"
}

# Finds file in the system's configured rom directories
__find_in_directories() {
  for rom_dir in "${rom_dirs[@]}"; do
    path=$(find "$rom_dir" -mindepth 1 -maxdepth 1 -name "$1" -print -quit)
    if [ -n "$path" ]; then
      echo "$path"
      return
    fi
  done
}

# Clean collections we didn't install to
__cleanup_unused_collections() {
  if [ ! -d "$target_collections_dir" ]; then
    return
  fi

  while read collection_ref_path; do
    local collection_name=$(basename "$collection_ref_path" .cfg.rk-src)
    if [ "${installed_collections["$collection_name"]}" ]; then
      continue
    fi

    # Remove this system from the given collection
    local collection_path="$target_collections_dir/$collection_name.cfg"
    if [ -f "$collection_path" ]; then
      sed -i "/\/$system\//d" "$target_collection_path"
    fi

    # Delete the collection if it's now empty
    if [ ! -s "$collection_path" ]; then
      rm -fv "$collection_path" "$collection_path.rk-src"
    fi
  done < <(find "$target_collections_dir" -name '*.cfg.rk-src')
}

restore() {
  __cleanup_unused_collections
}

setup "$1" "${@:3}"
