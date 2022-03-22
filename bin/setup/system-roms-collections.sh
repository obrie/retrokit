#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-collections'
setup_module_desc='Creates EmulationStation custom collections'

target_collections_dir="$HOME/.emulationstation/collections"

configure() {
  mkdir -pv "$target_collections_dir"

  __create_custom_collections
  __create_romkit_collections
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

  # Track which titles are in this collection
  declare -A collection_titles
  while IFS=$'\t' read -r rom_title; do
    collection_titles["$rom_title"]=1
  done < <(grep -E "^$system"$'\t' "$source_collection_path" | cut -d$'\t' -f 2)

  while IFS=$'\t' read -r name title parent_title; do
    if [ -z "${collection_titles["$title"]}" ] && { [ -z "$parent_title" ] || [ -z "${collection_titles["$parent_title"]}" ]; }; then
      # Not in the collection -- skip
      continue
    fi

    # ROMs in collection files contain just the title in order to work
    # for different regions, so we find the first installed ROM that matches
    # (the ROM could be present in multiple directories and we only want one in
    # the collection)
    local rom_path=$(__find_in_directories "$name.*" | head -n 1)
    if [ -f "$rom_path" ]; then
      echo "Adding $rom_path to $target_collection_path"
      echo "$rom_path" >> "$target_collection_path"
    fi
  done < <(romkit_cache_list | jq -r '[.name, .title, .parent .title] | @tsv' | sort)
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
