#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

scrape() {
  local source="$1"
  local mode="$2"
  local IFS=$'\n'
  local extra_args=($(system_setting '.scraper.args[]?'))

  stop_emulationstation

  log "Scaping $system from $source"
  if [ "$mode" == 'new' ]; then
    # Only scrape roms we have no data for
    /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" -s "$source" --flags onlymissing "${extra_args[@]}"
  else
    # Scrape existing roms that have missing textual / artwork resources.  This is done in case
    # there were errors scraping previously.
    mkdir -p '/opt/retropie/configs/all/skyscraper/reports/'

    # Remove existing Skyscraper reports
    find '/opt/retropie/configs/all/skyscraper/reports/' -name "report-$system-*" -exec rm -f "{}" \;

    # Generate new reports of missing resources.  We look at only 2 resources as
    # indicators of a prior issue:
    # * Missing title means we likely missed all the textual content
    # * Missing screenshot means we likely missed the media content
    /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" --cache report:missing=title,screenshot "${extra_args[@]}"

    # Generate aggregate list of roms
    local aggregate_report_file="/opt/retropie/configs/all/skyscraper/reports/report-$system-all.txt"
    cat /opt/retropie/configs/all/skyscraper/reports/report-$system-* | sort | uniq > "$aggregate_report_file"

    if [ -s "$aggregate_report_file" ]; then
      /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" -s "$source" --fromfile "$aggregate_report_file" "${extra_args[@]}"
    fi

    # Clean up reports
    find '/opt/retropie/configs/all/skyscraper/reports/' -name "report-$system-*" -exec rm -f "{}" \;
  fi
}

scrape_sources() {
  while read -r source; do
    scrape "$source" "${@}"
  done < <(system_setting '.scraper.sources[]')
}

scrape_missing_media() {
  scrape_sources missing_media
}

scrape_new() {
  scrape_sources new
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
  scrape_new
  scrape_missing_media
  build_gamelist
}

uninstall() {
  echo 'No uninstall for scraping'
}

"$1" "${@:3}"
