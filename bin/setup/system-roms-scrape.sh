#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-scrape'
setup_module_desc='Scrapes media / images / text via skyscraper, rebuilds the gamelist, and adjusts for multi-disc games'

aggregate_report_file="/opt/retropie/configs/all/skyscraper/reports/report-$system-all.txt"

configure() {
  __load_rom_data
  __scrape_sources
  __add_disc_numbers
  __build_gamelist

  # Reinstall the favorites for this system since the gamelist was just
  # re-created by skyscraper
  after_hook configure system-roms-favorites "$system"
}

# Load data about the roms being installed so that we can potentially use it
# as a source of scraping params
__load_rom_data() {
  declare -Ag rom_data
  while IFS=» read -r name playlist_name rom_name rom_crc; do
    rom_data["$name/rom"]="$rom_name"
    rom_data["$name/crc"]="$rom_crc"

    # If there's a separate playlist name, track it so that we can properly
    # scrape those as well
    if [ -n "$playlist_name" ]; then
      rom_data["$playlist_name/rom"]="$rom_name"
      rom_data["$playlist_name/crc"]="$rom_crc"
    fi
  done < <(romkit_cache_list | jq -r '[.name, .playlist .name, (.rom .name | @uri), .rom .crc] | join("»")')
}

# Scrape from all configured sources
__scrape_sources() {
  while read -r source; do
    __scrape_source "$source"
  done < <(system_setting '.scraper.sources[]')
}

# Scrape from the given source
__scrape_source() {
  local source=$1
  stop_emulationstation

  # Scrape for new roms we've never attempted before
  __scrape -s "$source" --flags onlymissing

  # Check if there are previously scraped roms with missing data / media
  __build_missing_reports
  if [ ! -s "$aggregate_report_file" ]; then
    return
  fi

  # Whether to do a final check at the end for missing games
  local run_final_check=false

  while read -r rom_path; do
    local rom_filename=$(basename "$rom_path")
    local rom_name=${rom_filename%.*}

    # Scrape with custom query (if one has been provided for this specific rom)
    local custom_query=$(system_setting ".scraper .$source .\"$rom_name\"" || true)
    if [ -n "$custom_query" ]; then
      __scrape -s "$source" --query "$custom_query" "$rom_path"
      if ! grep -E "'.+', No returned matches" "$HOME/.skyscraper/skipped-$system-$source.txt"; then
        continue
      fi
    fi

    # Scrape with dat data (CRC)
    if [ "$source" == 'screenscraper' ] && [ -n "${rom_data["$rom_name/crc"]}" ]; then
      local query_name="${rom_data["$rom_name/rom"]}"
      local crc="${rom_data["$rom_name/crc"]}"

      # Not all roms have a "rom name" defined
      if [ -z "$query_name" ]; then
        continue
      fi

      # Scrape with the CRC
      __scrape -s "$source" --query "romnom=$query_name&crc=$crc" "$rom_path"
      if ! grep -E "'.+', No returned matches" "$HOME/.skyscraper/skipped-$system-$source.txt"; then
        continue
      fi
    else
      run_final_check=true
    fi
  done < <(cat "$aggregate_report_file")

  # Check once more if data is missing.  We do this all at once in order to
  # avoid burning through scraping quotas on services like screenscraper where
  # every invocation of SkyScraper uses at least 1 request just to check the
  # user's remaining quota.
  #
  # This is needed for systems where a CRC / custom query isn't available for
  # us to use when there's missing scraped data.
  if [ "$run_final_check" == 'true' ]; then
    __build_missing_reports
    if [ -s "$aggregate_report_file" ]; then
      __scrape -s "$source" --fromfile "$aggregate_report_file"
    fi
  fi
}

# Runs Skyscraper with the given arguments
__scrape() {
  local IFS=$'\n'
  local extra_args=($(system_setting '.scraper.args[]?'))

  echo "Scaping $system (${*})"
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" "${extra_args[@]}" "${@}"
}

# Generates a report to be used by Skyscraper as input into which roms to scrape
__build_missing_reports() {
  mkdir -p '/opt/retropie/configs/all/skyscraper/reports/'

  # Remove existing Skyscraper reports
  find '/opt/retropie/configs/all/skyscraper/reports/' -name "report-$system-*" -exec rm -f '{}' +

  # Generate new reports of missing resources.  We look at only 2 resources as
  # indicators of a prior issue:
  # * Missing title means we likely missed all the textual content
  # * Missing screenshot means we likely missed the media content
  __scrape --cache report:missing=title,screenshot

  # Generate aggregate list of roms
  cat /opt/retropie/configs/all/skyscraper/reports/report-$system-* | sort | uniq > "$aggregate_report_file"
}

# When playlists are disabled and flags are configured to *not* be included in
# the display name, we need to differentiate between different discs within a
# game.  This functions allows us to manually specify the title *with* the disc
# number in the Skyscraper database.
__add_disc_numbers() {
  local skyscraper_brackets_enabled=$(crudini --get /opt/retropie/configs/all/skyscraper/config.ini 'main' 'brackets')
  if [ "$skyscraper_brackets_enabled" == '"true"' ]; then
    # No need to manually add disc numbers
    return
  fi

  # Remove existing overrides we may have previously added
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" --cache purge:m=user

  while IFS=$'\t' read -r name disc_title title path; do
    # Only process titles that have disc numbers (and no playlist)
    if [[ "$disc_title" != *"("* ]]; then
      continue
    fi

    # Find the skyscraper id
    local quickid_config=$(grep "$name" "/opt/retropie/configs/all/skyscraper/cache/$system/quickid.xml" | head -n 1)
    if [ -z "$quickid_config" ]; then
      continue
    fi
    local quickid=$(echo "$quickid_config" | xmlstarlet sel -t -v '*/@id')

    # Find the scraped title
    local scraped_title=$(grep $quickid /opt/retropie/configs/all/skyscraper/cache/$system/db.xml | grep 'type="title"' | grep -v 'source="user"' | head -n 1 | xmlstarlet sel -t -v '.' 2>/dev/null || echo "$title")
    local disc_id=$(echo "$disc_title" | grep -oE '\([^\)]+\)$')
    disc_id=${disc_id//[()]/}

    # Update the title to include the disc number.  We have to:
    # * Provide the name of the file that's being updated in --fromfile
    # * Pipe the title we want to set for that file
    local new_title="$scraped_title - $disc_id"
    local filename=$(basename  "$path")
    echo "Updating \"$name\" scraped title from \"$scraped_title\" to \"$new_title\""
    echo "$new_title" | /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" --cache edit:new=title --startat "$filename" --endat "$filename"
    rm -f "$tmp_ephemeral_dir/scraper.input"
  done < <(romkit_cache_list | jq -r 'select(.playlist == null) | [.name, .disc, .title, .path] | @tsv')
}

# Builds the gamelist.xml that will be used by emulationstation
__build_gamelist() {
  local IFS=$'\n'
  local extra_args=($(system_setting '.scraper | .gamelist_args // .args | .[]?'))

  echo "Building gamelist for $system"
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" "${extra_args[@]}"
}

vacuum() {
  __vacuum_cache
  __vacuum_media
}

# Removes files from the skyscraper database that it determines are no longer
# in use.
__vacuum_cache() {
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" --cache vacuum
}

# Remove videos / images from emulationstation that are no longer used.
# 
# Note this *just* outputs the commands.  You must then run them.
__vacuum_media() {
  # Look up which names are installed
  declare -A installed_names
  while IFS=$'\t' read -r name playlist_name; do
    installed_names["$name"]=1

    if [ -n "$playlist_name" ]; then
      installed_names["$playlist_name"]=1
    fi
  done < <(romkit_cache_list | jq -r '[.name, .playlist .name] | @tsv')

  # Find media with no corresponding installed name
  while read -r media_path; do
    local filename=$(basename "$media_path")
    local rom_name=${filename%.*}

    if [ -z "${installed_names["$rom_name"]}" ]; then
      echo "rm -f $(printf '%q' "$media_path")"
    fi
  done < <(find "$HOME/.emulationstation/downloaded_media/$system" -type f -name '*.png' -o -name '*.mp4')
}

setup "$1" "${@:3}"
