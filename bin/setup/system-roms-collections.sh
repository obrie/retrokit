#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-collections'
setup_module_desc='Creates EmulationStation custom collections'

source_collections_dir="$config_dir/emulationstation/collections"
target_collections_dir="$HOME/.emulationstation/collections"

configure() {
  mkdir -pv "$target_collections_dir"

  while read -r filename; do
    __create_collection "$filename"
  done < <(ls "$source_collections_dir")
}

# Creates the collection defined by the given file
__create_collection() {
  local filename=$1

  # Identify what collection we're dealing with
  local collection_name=$(basename "$filename" '.tsv')
  local source_collection_path="$source_collections_dir/$filename"
  local target_collection_path="$target_collections_dir/$collection_name.cfg"

  # Remove any existing entries for this system from the collection
  if [ -f "$target_collection_path" ]; then
    sed -i "/\/$system\//d" "$target_collection_path"
  fi

  while IFS=$'\t' read -r collection_system rom_title; do
    # ROMs in collection files contain just the title in order to work
    # for different regions, so we find the first installed ROM that matches
    # the title (the ROM could be present in multiple directories and we
    # only want one in the collection)
    while read -r rom_path; do
      local rom_filename=${rom_path##*/}
      local installed_name=${rom_filename%.*}
      local installed_title=${installed_name%% (*}

      # If the titles match, add it
      if [ "$installed_title" == "$rom_title" ]; then
        echo "Adding $rom_path to $target_collection_path"
        echo "$rom_path" >> "$target_collection_path"
        break
      fi
    done < <(__find_in_directories "$rom_title*")
  done < <(grep -E "^$system"$'\t' "$source_collection_path")
}

# Finds file in the system's configured rom directories
__find_in_directories() {
  system_setting '.roms.dirs[] | .path' | xargs -I{} find "{}" -mindepth 1 -maxdepth 1 -name "$1" 2>/dev/null
}

restore() {
  if [ -d "$target_collections_dir" ]; then
    find "$target_collections_dir" -name '*.cfg' -exec rm -fv "{}" \;
  fi
}

setup "$1" "${@:3}"
