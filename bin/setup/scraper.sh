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
  ini_merge "$config_dir/skyscraper/config.ini" '/opt/retropie/configs/all/skyscraper/config.ini' space_around_delimiters=false

  # Add video convert script
  cp -v "$config_dir/skyscraper/videoconvert.sh" '/opt/retropie/configs/all/skyscraper/'
}

uninstall() {
  rm -fv '/opt/retropie/configs/all/skyscraper/video_convert.sh'
  restore '/opt/retropie/configs/all/skyscraper/config.ini' delete_src=true
  uninstall_retropie_package skyscraper || true
}

"${@}"
