#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

scrape() {
  local source="$1"
  local mode="$2"
  local IFS=$'\n'
  local extra_args=($(system_setting '.scraper.args[]?'))

  stop_emulationstation

  echo "Scaping $system from $source"
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

add_disc_numbers() {
  # Remove existing disc numbers
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" --cache purge:m=user

  if [ "$(system_setting '.playlists.enabled')" != 'true' ] && [ $(crudini --get /opt/retropie/configs/all/skyscraper/config.ini 'main' 'brackets') == '"false"' ]; then
    # Playlists are disabled and flags are configured to *not* be included in the
    # display name.  In order to differentiate between different discs within a
    # game, we need to manually specify the title with the disc number.
    while IFS='^' read name disc_title title path; do
      if [[ "$disc_title" == *Disc* ]]; then
        # Find the skyscraper id
        local quickid_config=$(grep "$name" "/opt/retropie/configs/all/skyscraper/cache/$system/quickid.xml" | head -n 1)
        if [ -z "$quickid_config" ]; then
          continue
        fi
        local quickid=$(echo "$quickid_config" | xmlstarlet sel -t -v '*/@id')

        # Find the scraped title
        local scraped_title=$(grep $quickid /opt/retropie/configs/all/skyscraper/cache/$system/db.xml | grep 'type="title"' | grep -v 'source="user"' | head -n 1 | xmlstarlet sel -t -v '.' 2>/dev/null || echo "$title")
        local disc_id=$(echo "$path" | grep -oE 'Disc[^\)]+')

        # Update the title to include the disc number
        local new_title="$scraped_title - $disc_id"
        echo "Updating $name scraped title from \"$scraped_title\" to \"$new_title\""
        echo "$(basename "$path")" > "$tmp_dir/scraper.input"
        echo "$new_title" | /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" --cache edit:new=title --fromfile "$tmp_dir/scraper.input"
        rm -f "$tmp_dir/scraper.input"
      fi
    done < <(romkit_cache_list | jq -r '[.name, .disc, .title, .path] | join("^")')
  fi
}

build_gamelist() {
  local IFS=$'\n'
  local extra_args=($(system_setting '.scraper | .gamelist_args // .args | .[]?'))

  echo "Building gamelist for $system"
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
  add_disc_numbers
  build_gamelist

  # Reinstall the favorites for this system
  if [ -z "$SKIP_DEPS" ] && has_setupmodule 'system-roms-favorites'; then
    "$bin_dir/setup.sh" install system-roms-favorites "$system"
  fi
}

uninstall() {
  echo 'No uninstall for scraping'
}

"$1" "${@:3}"
