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
  install_retropie_package skyscraper

  # Add video convert script
  file_cp '{config_dir}/skyscraper/videoconvert.sh' "$skyscraper_dir/videoconvert.sh" backup=false envsubst=false
}

configure() {
  ini_merge '{config_dir}/skyscraper/config.ini' "$skyscraper_dir/config.ini" space_around_delimiters=false
}

restore() {
  restore_file "$skyscraper_dir/config.ini" delete_src=true
}

remove() {
  rm -fv "$skyscraper_dir/video_convert.sh"

  if [ -d "$retropie_dir/supplementary/skyscraper" ]; then
    uninstall_retropie_package skyscraper
  fi
}

setup "${@}"
