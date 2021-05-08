#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

scrape() {
  local source="$1"
  local IFS=$'\n'
  local extra_args=($(system_setting '.scraper.args[]?'))

  stop_emulationstation

  log "Scaping $system from $source"
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" -s "$source" --flags onlymissing "${extra_args[@]}"
}

scrape_sources() {
  while read -r source; do
    scrape "$source"
  done < <(system_setting '.scraper.sources[]')
}

build_gamelist() {
  local IFS=$'\n'
  local extra_args=($(system_setting '.scraper.args[]?'))

  log "Building gamelist for $system"
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" "${extra_args[@]}"
}

build_collections() {
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
            echo "$machine_path" >> "$target_collection_path"
            break
          fi
        done < <(xmlstarlet sel -t -m "*/game[contains(path, \"$machine_name\")]" -v 'path' -n "$HOME/.emulationstation/gamelists/$system/gamelist.xml")
      fi
    done < "$source_collection_path"
  done < <(ls "$source_collections_dir")
}

vacuum_cache() {
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" --cache vacuum
}

vacuum_media() {
  # Remove videos / images from emulationstation
  while read -r media_path; do
    local filename=$(basename "$media_path")
    local rom_name=${filename%%.*}

    if ! find "$HOME/RetroPie/roms/$system" -name "$rom_name.*" | grep . >/dev/null; then
      echo "rm -f \"$media_path\""
    fi
  done < <(find "$HOME/.emulationstation/downloaded_media/$system" -type f -name "*.png" -o -name "*.mp4")
}

vacuum() {
  vacuum_cache
  vacuum_media
}

install() {
  scrape_sources
  build_gamelist
  build_collections
}

uninstall() {
  echo 'No uninstall for scraping'
}

"$1" "${@:3}"
