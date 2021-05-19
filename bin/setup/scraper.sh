#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

# Scraper
# 
# Instructions: https://retropie.org.uk/docs/Scraper/#lars-muldjords-skyscraper
# Configs:
# * /opt/retropie/configs/all/skyscraper/config.ini
install() {
  # Video editor for conversions
  sudo apt install -y ffmpeg

  install_retropie_package 'supplementary' 'skyscraper'
  ini_merge "$config_dir/skyscraper/config.ini" '/opt/retropie/configs/all/skyscraper/config.ini' space_around_delimiters=false

  # Add video convert script
  cp "$config_dir/skyscraper/videoconvert.sh" '/opt/retropie/configs/all/skyscraper/'
}

uninstall() {
  restore '/opt/retropie/configs/all/skyscraper/config.ini'
  sudo apt remove -y ffmpeg
}

"${@}"
