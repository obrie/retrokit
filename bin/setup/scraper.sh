#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

# Scraper
# 
# Instructions: https://retropie.org.uk/docs/Scraper/#lars-muldjords-skyscraper
# Configs:
# * /opt/retropie/configs/all/skyscraper/config.ini
install() {
  install_retropie_package 'supplementary' 'skyscraper'

  # Add video convert script
  cp -v "$config_dir/skyscraper/videoconvert.sh" '/opt/retropie/configs/all/skyscraper/'

  configure
}

configure() {
  ini_merge "$config_dir/skyscraper/config.ini" '/opt/retropie/configs/all/skyscraper/config.ini' space_around_delimiters=false
}

restore() {
  restore_file '/opt/retropie/configs/all/skyscraper/config.ini' delete_src=true
}

uninstall() {
  restore
  rm -fv '/opt/retropie/configs/all/skyscraper/video_convert.sh'
  uninstall_retropie_package skyscraper || true
}

"${@}"
