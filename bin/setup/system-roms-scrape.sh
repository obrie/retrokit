#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

aggregate_report_file="/opt/retropie/configs/all/skyscraper/reports/report-$system-all.txt"

# Load data about the roms being installed so that we can potentially use it
# as a source of scraping params
load_rom_data() {
  declare -Ag rom_data
  while IFS=$'\t' read -r name rom_name rom_crc; do
    rom_data["$name/rom"]="$rom_name"
    rom_data["$name/crc"]="$rom_crc"
  done < <(romkit_cache_list | jq -r '[.name, (.rom .name | @uri), .rom .crc] | @tsv')
}

scrape() {
  local source=$1
  local IFS=$'\n'
  local extra_args=($(system_setting '.scraper.args[]?'))

  echo "Scaping $system from $source"
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" -s "$source" --flags onlymissing "${extra_args[@]}" "${@:2}"
}

build_missing_reports() {
  mkdir -p '/opt/retropie/configs/all/skyscraper/reports/'

  # Remove existing Skyscraper reports
  find '/opt/retropie/configs/all/skyscraper/reports/' -name "report-$system-*" -exec rm -f "{}" \;

  # Generate new reports of missing resources.  We look at only 2 resources as
  # indicators of a prior issue:
  # * Missing title means we likely missed all the textual content
  # * Missing screenshot means we likely missed the media content
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" --cache report:missing=title,screenshot "${extra_args[@]}"

  # Generate aggregate list of roms
  cat /opt/retropie/configs/all/skyscraper/reports/report-$system-* | sort | uniq > "$aggregate_report_file"
}

scrape_source() {
  local source=$1
  stop_emulationstation

  # Scrape for new roms we've never attempted before
  scrape "$source" --flags onlymissing

  build_missing_reports

  if [ -s "$aggregate_report_file" ]; then
    # Whether to do a final check at the end for missing games
    local run_final_check=false

    while read -r rom_path; do
      local rom_filename=$(basename "$rom_path")
      local rom_name=${rom_filename%.*}
      local custom_query=$(system_setting ".scraper .$source .\"$rom_name\"" || true)

      # Scrape with custom query
      if [ -n "$custom_query" ]; then
        scrape "$source" --query "$custom_query" "$rom_path"
        if ! grep -E "'.+', No returned matches" "$HOME/.skyscraper/skipped-$system-$source.txt"; then
          continue
        fi
      fi

      # Scrape with dat data
      if [ "$source" == 'screenscraper' ] && [ -n "${rom_data["$rom_name/crc"]}" ]; then
        local query_name="${rom_data["$rom_name/rom"]}"
        local crc="${rom_data["$rom_name/crc"]}"
        if [ -z "$query_name" ]; then
          exit
        fi

        scrape "$source" --query "romnom=$query_name&crc=$crc" "$rom_path"
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
    if [ "$run_final_check" == 'true' ]; then
      build_missing_reports
      if [ -s "$aggregate_report_file" ]; then
        scrape "$source" --fromfile "$aggregate_report_file"
      fi
    fi
  fi
}

scrape_sources() {
  while read -r source; do
    scrape_source "$source"
  done < <(system_setting '.scraper.sources[]')
}

# When playlists are disabled and flags are configured to *not* be included in
# the display name, we need to differentiate between different discs within a
# game.  This functions allows us to manually specify the title with the disc
# number.
add_disc_numbers() {
  # Remove existing disc numbers
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" --cache purge:m=user

  if [ "$(system_setting '.playlists.enabled')" != 'true' ] && [ "$(crudini --get /opt/retropie/configs/all/skyscraper/config.ini 'main' 'brackets')" == '"false"' ]; then
    while IFS=» read -r name disc_title title path; do
      if [[ "$disc_title" == *"(Disc"* ]]; then
        # Find the skyscraper id
        local quickid_config=$(grep "$name" "/opt/retropie/configs/all/skyscraper/cache/$system/quickid.xml" | head -n 1)
        if [ -z "$quickid_config" ]; then
          continue
        fi
        local quickid=$(echo "$quickid_config" | xmlstarlet sel -t -v '*/@id')

        # Find the scraped title
        local scraped_title=$(grep $quickid /opt/retropie/configs/all/skyscraper/cache/$system/db.xml | grep 'type="title"' | grep -v 'source="user"' | head -n 1 | xmlstarlet sel -t -v '.' 2>/dev/null || echo "$title")
        local disc_id=$(echo "$path" | grep -oE '\(Disc[^\)]+')

        # Update the title to include the disc number
        local new_title="$scraped_title - $disc_id"
        echo "Updating $name scraped title from \"$scraped_title\" to \"$new_title\""
        echo "$(basename "$path")" > "$tmp_ephemeral_dir/scraper.input"
        echo "$new_title" | /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" --cache edit:new=title --fromfile "$tmp_ephemeral_dir/scraper.input"
        rm -f "$tmp_ephemeral_dir/scraper.input"
      fi
    done < <(romkit_cache_list | jq -r '[.name, .disc, .title, .path] | join("»")')
  fi
}

# Builds the gamelist.xml that will be used by emulationstation
build_gamelist() {
  local IFS=$'\n'
  local extra_args=($(system_setting '.scraper | .gamelist_args // .args | .[]?'))

  echo "Building gamelist for $system"
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" "${extra_args[@]}"
}

# Removes files from the skyscraper database that it determines are no longer
# in use.
vacuum_cache() {
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" --cache vacuum
}

# Remove videos / images from emulationstation that are no longer used.
# 
# Note this *just* outputs the commands.  You must then run them.
vacuum_media() {
  while read -r media_path; do
    local filename=$(basename "$media_path")
    local rom_name=${filename%.*}

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
  load_rom_data
  scrape_sources
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
