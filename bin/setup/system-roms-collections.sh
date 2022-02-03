#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

source_collections_dir="$config_dir/emulationstation/collections"
target_collections_dir="$HOME/.emulationstation/collections"

install() {
  mkdir -pv "$target_collections_dir"

  while read -r filename; do
    __install_collection "$filename"
  done < <(ls "$source_collections_dir")
}

# Installs the collection defined by the given file
__install_collection() {
  local filename=$1

  # Identify what collection we're dealing with
  local collection_name=$(basename "$filename" '.tsv')
  local source_collection_path="$source_collections_dir/$filename"
  local target_collection_path="$target_collections_dir/$collection_name.cfg"

  # Remove any existing entries for this system from the collection
  if [ -f "$target_collection_path" ]; then
    sed -i "/\/$system\//d" "$target_collection_path"
  fi

  while IFS=$'\t' read -r collection_system machine_title; do
    # Machines in collection files contain just the title in order to work
    # for different regions, so we:
    # 1. Do an initial naive search based on a substring match in the gamelist.xml
    # 2. Do an exact match based on comparing the titles
    while read -r machine_path; do
      local machine_filename=${machine_path##*/}
      local installed_name=${machine_filename%.*}
      local installed_title=${installed_name%% (*}

      # If the titles match, add it
      if [ "$installed_title" == "$machine_title" ]; then
        echo "Adding $machine_path to $target_collection_path"
        echo "$machine_path" >> "$target_collection_path"
        break
      fi
    done < <(__find_in_directories "$machine_title*")
  done < <(grep -E "^$system"$'\t' "$source_collection_path")
}

# Finds file in the system's configured rom directories
__find_in_directories() {
  system_setting '.roms.dirs[] | .path' | xargs -I{} find "{}" -mindepth 1 -maxdepth 1 -name "$1" 2>/dev/null
}

uninstall() {
  if [ -d "$target_collections_dir" ]; then
    find "$target_collections_dir" -name '*.cfg' -exec rm -fv "{}" \;
  else
    echo 'No collections to uninstall'
  fi
}

"$1" "${@:3}"
