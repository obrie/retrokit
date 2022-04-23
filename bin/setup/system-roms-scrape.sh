#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-scrape'
setup_module_desc='Scrapes media / images / text via skyscraper, rebuilds the gamelist, and adjusts for multi-disc games'

aggregate_report_file="/opt/retropie/configs/all/skyscraper/reports/report-$system-all.txt"

configure() {
  __load_rom_data
  __scrape_sources
  __import_titles
  __import_user_overrides
  __build_gamelist

  # Reinstall the favorites for this system since the gamelist was just
  # re-created by skyscraper
  after_hook configure system-roms-favorites "$system"
}

# Load data about the roms being installed so that we can potentially use it
# as a source of scraping params
__load_rom_data() {
  declare -Ag rom_data
  while IFS=» read -r name playlist_name rom_name rom_crc rom_path; do
    rom_data["$name/rom"]="$rom_name"
    rom_data["$name/crc"]="$rom_crc"
    rom_data["$name/path"]="$rom_path"

    # If there's a separate playlist name, track it so that we can properly
    # scrape those as well
    if [ -n "$playlist_name" ]; then
      rom_data["$playlist_name/rom"]="$rom_name"
      rom_data["$playlist_name/crc"]="$rom_crc"
    fi
  done < <(romkit_cache_list | jq -r '[.name, .playlist .name, (.rom .name | @uri), .rom .crc, .path] | join("»")')
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

  # Only re-scrape roms a second time if the user has explicitly asked us to update
  # the scraped data
  if [ "$FORCE_UPDATE" != 'true' ]; then
    return
  fi

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

# Imports titles from DAT files to override what was scraped
__import_titles() {
  local import_dat_titles=$(system_setting '.scraper .import_dat_titles')
  if [ "$import_dat_titles" != 'true' ]; then
    # Don't import titles from romkit (purge anything we've previously imported for this system)
    __scrape --cache purge:m=import
    return
  fi

  local import_dir="$HOME/.skyscraper/import/$system"
  mkdir -p "$import_dir/textual"

  # Define the structure of the import
  echo 'Title: ###TITLE###' > "$import_dir/definitions.dat"

  # Remove existing files
  find "$import_dir/textual" -name '*.txt' -exec rm -fv '{}' +

  # Identify corresponding filename for each skyscraper quickid
  declare -A quickid_names
  while IFS=$'\t' read quickid filepath; do
    local filename=$(basename "$filepath")
    local name=${filename%.*}
    quickid_names[$name]=$quickid
  done < <(xmlstarlet select -t -m '/*/*' -v '@id' -o $'\t' -v '@filepath' -n "/opt/retropie/configs/all/skyscraper/cache/$system/quickid.xml" | xmlstarlet unesc)

  # Identify which titles we've already imported so we don't do it again
  declare -A imported_titles
  while IFS=$'\t' read quickid title; do
    imported_titles[$quickid]=$title
  done < <(xmlstarlet select -t -m '/*/*[@type="title" and @source="import"]' -v '@id' -o $'\t' -v '.' -n "/opt/retropie/configs/all/skyscraper/cache/$system/db.xml" | xmlstarlet unesc)

  # Find new titles to import
  while IFS=$'\t' read -r name disc_title title playlist_name; do
    # Determine which filename we're targeting
    local target_name
    local title_to_import
    if [ -n "$playlist_name" ]; then
      title_to_import=$title
      target_name=$playlist_name
    else
      # Always use the Disc title, ensuring that the disc identifier is not hidden
      # within parentheses
      title_to_import=$(echo "$disc_title" | sed 's/(/- /; s/)//g')
      target_name=$name
    fi

    # Check if we've already written to this file (this can happen for playlists)
    if [ -f "$import_dir/textual/$target_name.txt" ]; then
      continue
    fi

    # Check to see if we're previously imported this game's title
    local quickid=${quickid_names[$target_name]}
    if [ -n "$quickid" ]; then
      local imported_title=${imported_titles[$quickid]}
      if [ "$imported_title" == "$title_to_import" ]; then
        continue
      fi
    fi

    echo "Title: $title_to_import" > "$import_dir/textual/$target_name.txt"
  done < <(romkit_cache_list | jq -r '[.name, .disc, .title, .playlist.name] | @tsv')

  # Import the data
  if [ -n "$(ls -A "$import_dir/textual")" ]; then
    __scrape -s import
  fi

  # Clean up unused files
  rm -rf "$import_dir"
}

__import_user_overrides() {
  # Remove existing overrides we may have previously added
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" --cache purge:m=user

  # Look up any overrides we want to add to the skyscraper database
  local overrides_path=$(first_path '{system_dir}/scrape-overrides.tsv')
  if [ -z "$overrides_path" ]; then
    return
  fi

  while IFS=$'\t' read rom_name resource_type resource_value; do
    local rom_path=${rom_data["$rom_name/path"]}
    if [ -z "$rom_path" ]; then
      # ROM isn't installed -- we can skip it
      continue
    fi

    local rom_filename=$(basename "$rom_path")
    echo "Updating \"$rom_filename\" $resource_type to \"$resource_value\""
    echo "$resource_value" | /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" --cache edit:new=$resource_type --startat "$rom_filename" --endat "$rom_filename"
  done < <(cat "$overrides_path")
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
