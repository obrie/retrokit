#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

scrape() {
  local source="$1"
  local extra_args=($(system_setting '.scraper.args?'))

  stop_emulationstation

  log "Scaping $system from $source"
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" -s "$source" --flags onlymissing ${extra_args[@]}
}

scrape_sources() {
  while read -r source; do
    scrape "$source"
  done < <(system_setting '.scraper.sources[]')
}

build_gamelist() {
  local extra_args=($(system_setting '.scraper.args?'))

  log "Building gamelist for $system"
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" ${extra_args[@]}
}

install() {
  scrape_sources
  build_gamelist
}

uninstall() {
  echo 'No uninstall for scraping'
}

"$1" "${@:3}"
