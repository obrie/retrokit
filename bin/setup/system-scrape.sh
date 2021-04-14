#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

scrape() {
  local source="$1"

  stop_emulationstation

  log "Scaping $system from $source"
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" -s "$source" --flags onlymissing
}

scrape_sources() {
  while read -r source; do
    scrape "$source"
  done < <(system_setting '.scraper.sources')
}

build_gamelist() {
  log "Building gamelist for $system"
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system"
}

install() {
  scrape_sources
  build_gamelist
}

uninstall() {
  echo 'No uninstall for scraping'
}

"$1" "${@:3}"
