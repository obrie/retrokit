#!/bin/bash

set -ex

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

    while IFS="$tab" read -r collection_system machine_name; do
      if [ "$collection_system" == "$system" ]; then
        while read -r machine_path; do
          local name_without_flags=$(basename "$machine_path" | grep -oE "^[^\(]+" | sed -e 's/[[:space:]]*$//')

          # If path is found, add it
          if [ "$name_without_flags" = "$machine_name" ]; then
            echo "$1" >> "$target_collection_path"
            break
          fi
        done < <(xmlstarlet sel -t -m "*/game[contains(path, \"$machine_name\")]" -v 'path' -n "$HOME/.emulationstation/gamelists/$system/gamelist.xml")
      fi
    done < "$source_collection_path"
  done < <(ls "$source_collections_dir")
}

uninstall() {
  echo 'No uninstall for collections'
}

"$1" "${@:3}"
