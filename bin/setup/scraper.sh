#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='scraper'
setup_module_desc='Skyscraper setup and configuration'

skyscraper_dir="$retropie_configs_dir/all/skyscraper"

# Scraper
# 
# Instructions: https://retropie.org.uk/docs/Scraper/#lars-muldjords-skyscraper
build() {
  install_retropie_package skyscraper-plus

  # Add video convert script
  file_cp '{config_dir}/skyscraper/videoconvert.sh' "$skyscraper_dir/videoconvert.sh" backup=false envsubst=false
}

configure() {
  # Configuration settings
  ini_merge '{config_dir}/skyscraper/config.ini' "$skyscraper_dir/config.ini" space_around_delimiters=false

  # Platform settings
  for filename in platforms screenscraper; do
    backup_and_restore "$skyscraper_dir/$filename.json"

    # We have to manually merge the `platforms` array from each file, so we:
    # (1) Identify all the files that want to add new platforms
    # (2) Rewrite the target by union'ing each `platforms` array and generating a new json file
    mapfile -t merge_paths < <(each_path "{config_dir}/skyscraper/$filename.json")
    if [ ${#merge_paths[@]} -gt 0 ]; then
      local override_file=$(mktemp -p "$tmp_ephemeral_dir")

      jq -s '.[0].platforms = ([.[].platforms] | flatten) | .[0]' "$skyscraper_dir/$filename.json" "${merge_paths[@]}" > "$override_file"
      cp "$override_file" "$skyscraper_dir/$filename.json"
    fi
  done
}

restore() {
  restore_file "$skyscraper_dir/config.ini" delete_src=true
}

remove() {
  rm -fv "$skyscraper_dir/video_convert.sh"

  if [ -d "$retropie_dir/supplementary/skyscraper-plus" ]; then
    uninstall_retropie_package skyscraper-plus
  fi
}

setup "${@}"
