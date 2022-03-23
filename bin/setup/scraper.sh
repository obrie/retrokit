#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='scraper'
setup_module_desc='Skyscraper setup and configuration'

skyscraper_dir=/opt/retropie/configs/all/skyscraper

# Scraper
# 
# Instructions: https://retropie.org.uk/docs/Scraper/#lars-muldjords-skyscraper
# Configs:
# * /opt/retropie/configs/all/skyscraper/config.ini
build() {
  install_retropie_package 'supplementary' 'skyscraper'

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
  uninstall_retropie_package skyscraper || true
}

setup "${@}"
