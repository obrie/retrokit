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
}

uninstall() {
  echo 'No uninstall for scraping'
}

"$1" "${@:3}"
