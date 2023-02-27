#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-scrape'
setup_module_desc='Scrapes media / images / text via skyscraper, rebuilds the gamelist, and adjusts for multi-disc games'

aggregate_report_file="$retropie_configs_dir/all/skyscraper/reports/report-$system-all.txt"
gamelist_file="$HOME/.emulationstation/gamelists/$system/gamelist.xml"

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
  __scraper -s "$source" --flags onlymissing

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
      __scraper -s "$source" --query "$custom_query" "$rom_path"
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
      __scraper -s "$source" --query "romnom=$query_name&crc=$crc" "$rom_path"
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
      __scraper -s "$source" --fromfile "$aggregate_report_file"
    fi
  fi
}

# Runs the scraper command without anything from stdin
__scraper() {
  __scraper_exec '' "${@}"
}

# Pipes the first value in the arguments to the scraper command
__scraper_pipe() {
  __scraper_exec "${@}"
}

# Runs Skyscraper with the given arguments
__scraper_exec() {
  local IFS=$'\n'
  local stdin_value=$1
  local extra_args=($(system_setting '.scraper.args[]?'))
  local cmd=("$retropie_dir/supplementary/skyscraper/Skyscraper" -p "$system" "${extra_args[@]}" "${@:2}")

  echo "Running Skyscraper: $system (${*})"
  if [ -z "$stdin_value" ]; then
    "${cmd[@]}"
  else
    echo "$stdin_value" | "${cmd[@]}"
  fi
}

# Generates a report to be used by Skyscraper as input into which roms to scrape
__build_missing_reports() {
  mkdir -p "$retropie_configs_dir/all/skyscraper/reports/"

  # Remove existing Skyscraper reports
  find "$retropie_configs_dir/all/skyscraper/reports/" -name "report-*" -exec rm -f '{}' +

  # Generate new reports of missing resources.  We look at only 2 resources as
  # indicators of a prior issue:
  # * Missing title means we likely missed all the textual content
  # * Missing screenshot means we likely missed the media content
  __scraper --cache report:missing=title,screenshot

  # Generate aggregate list of roms
  cat "$retropie_configs_dir/all/skyscraper/reports/report-"* | sort | uniq > "$aggregate_report_file"

  # Remove files explicitly being ignored (but still show up when using --cache)
  while read ignore_file; do
    local ignore_dir=$(dirname "$ignore_file")

    if [[ "$ignore_file" == *tree ]]; then
      sed -i "\|$ignore_dir|d" "$aggregate_report_file"
    else
      sed -i "\|$ignore_dir/[^/]\+|d" "$aggregate_report_file"
    fi
  done < <(find "$roms_dir/$system" -name '.skyscraperignore' -o -name '.skyscraperignoretree')
}

# Imports titles from DAT files to override what was scraped
__import_titles() {
  local import_dat_titles=$(system_setting '.scraper .import_dat_titles')
  if [ "$import_dat_titles" != 'true' ]; then
    # Don't import titles from romkit (purge anything we've previously imported for this system)
    __scraper --cache purge:m=import
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
  done < <(xmlstarlet select -t -m '/*/*' -v '@id' -o $'\t' -v '@filepath' -n "$retropie_configs_dir/all/skyscraper/cache/$system/quickid.xml" | xmlstarlet unesc)

  # Identify which titles we've already imported so we don't do it again
  declare -A imported_titles
  while IFS=$'\t' read quickid title; do
    imported_titles[$quickid]=$title
  done < <(xmlstarlet select -t -m '/*/*[@type="title" and @source="import"]' -v '@id' -o $'\t' -v '.' -n "$retropie_configs_dir/all/skyscraper/cache/$system/db.xml" | xmlstarlet unesc)

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
    __scraper -s import
  fi

  # Clean up unused files
  rm -rf "$import_dir"
}

__import_user_overrides() {
  # Remove existing overrides we may have previously added
  __scraper --cache purge:m=user

  while IFS=$'\t' read rom_name resource_type resource_value; do
    local rom_path=${rom_data["$rom_name/path"]}
    if [ -z "$rom_path" ]; then
      # ROM isn't installed -- we can skip it
      continue
    fi

    local rom_filename=$(basename "$rom_path")
    echo "Updating \"$rom_filename\" $resource_type to \"$resource_value\""
    __scraper_pipe "$resource_value" --cache edit:new=$resource_type "$rom_path"
  done < <(each_path '{system_config_dir}/scrape-overrides.json' jq -r 'to_entries[] | .key as $name | .value | to_entries[] | [$name, .key, .value] | @tsv' '{}')
}

# Builds the gamelist.xml that will be used by emulationstation
__build_gamelist() {
  local IFS=$'\n'
  local args=()

  # Add base arguments
  if [ "$(system_setting '.scraper | .gamelist_include_base_args')" == 'true' ]; then
    args+=($(system_setting '.scraper | .args? | .[]'))
  fi

  # Add gamelist arguments
  args+=($(system_setting '.scraper | .gamelist_args? | .[]'))

  echo "Building gamelist for $system"
  "$retropie_dir/supplementary/skyscraper/Skyscraper" -p "$system" "${args[@]}" >/dev/null

  # Fix gamelist being generated incorrectly with games marked as folders
  #
  # See: https://github.com/muldjord/skyscraper/blob/19832c4cc13d396a3089d09da773e79d5488217a/src/emulationstation.cpp#L155-L158
  #
  # Without this fix, we'll see errors like this in EmulationStation:
  #   Error finding/creating FileData...
  while read rom_dir; do
    local rom_files=$(find "$rom_dir" -maxdepth 1 -mindepth 1 -type f -o -type l)
    local rom_count=$(echo "$rom_files" | wc -l)

    if [ $rom_count -eq 1 ]; then
      xmlstarlet edit --inplace \
        --rename "//gameList/folder[path=\"$rom_dir\"]" -v 'game' \
        --update "//gameList/game[path=\"$rom_dir\"]/path" -v "$rom_files" \
        "$gamelist_file"
    fi
  done < <(system_setting 'select(.roms) | .roms.dirs[] | .path')
}

vacuum() {
  __vacuum_cache
  __vacuum_media
}

# Removes files from the skyscraper database that it determines are no longer
# in use.
__vacuum_cache() {
  __scraper --cache vacuum
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

  # Look up additional files in the gamelist that may have been installed outside
  # of romkit
  if [ -f "$gamelist_file" ]; then
    while IFS=$'\t' read -r rom_path; do
      local rom_filename=${rom_path##*/}
      local rom_name=${rom_filename%.*}
      installed_names["$rom_name"]=1
    done < <(xmlstarlet select -t -m '/*/*' -v 'path' -n "$gamelist_file" | xmlstarlet unesc)
  fi

  # Find media with no corresponding installed name
  while read -r media_file; do
    local filename=$(basename "$media_file")
    local rom_name=${filename%.*}

    if [ -z "${installed_names["$rom_name"]}" ]; then
      echo "rm -fv $(printf '%q' "$media_file")"
    fi
  done < <(find "$HOME/.emulationstation/downloaded_media/$system" -type f -name '*.png' -o -name '*.mp4')
}

remove() {
  if [ ! -f "$retropie_dir/supplementary/skyscraper/Skyscraper" ]; then
    return
  fi

  __scraper --cache purge:all
}

setup "${@}"
