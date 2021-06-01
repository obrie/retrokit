#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

install() {
  local source_collections_dir="$config_dir/emulationstation/collections"
  local target_collections_dir="$HOME/.emulationstation/collections"
  mkdir -p "$target_collections_dir"

  while read -r filename; do
    # Identify what collection we're dealing with
    local collection_name=$(basename "$filename" '.tsv')
    local source_collection_path="$source_collections_dir/$filename"
    local target_collection_path="$target_collections_dir/$collection_name.cfg"

    # Remove any existing entries for this system from the collection
    if [ -f "$target_collection_path" ]; then
      sed -i "/\/$system\//d" "$target_collection_path"
    fi

    while IFS="$tab" read -r collection_system machine_title; do
      # Machines in collection files contain just the title in order to work
      # for different regions, so we:
      # 1. Do an initial naive search based on a substring match in the gamelist.xml
      # 2. Do an exact match based on comparing the titles
      while read -r machine_path; do
        local installed_name=${machine_path%%.*}
        local installed_title=${installed_name%% (*}

        # If the titles match, add it
        if [ "$installed_title" = "$machine_title" ]; then
          echo "Adding $1 to $target_collection_path"
          echo "$1" >> "$target_collection_path"
          break
        fi
      done < <(xmlstarlet sel -t -m "*/game[contains(path, \"$machine_title\")]" -v 'path' -n "$HOME/.emulationstation/gamelists/$system/gamelist.xml")
    done < <(grep -E "^$system$tab" "$source_collection_path")
  done < <(ls "$source_collections_dir")
}

uninstall() {
  if [ -d "$HOME/.emulationstation/collections" ]; then
    find "$HOME/.emulationstation/collections" -name '*.cfg' -exec rm -f "{}" \;
  fi
}

"$1" "${@:3}"
