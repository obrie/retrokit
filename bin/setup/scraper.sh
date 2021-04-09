#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

# Scraper
# 
# Instructions: https://retropie.org.uk/docs/Scraper/#lars-muldjords-skyscraper
# Configs:
# * /opt/retropie/configs/all/skyscraper/config.ini
setup() {
  "$HOME/RetroPie-Setup/retropie_packages.sh" skyscraper _binary_
  ini_merge "$config_dir/skyscraper/config.ini" "/opt/retropie/configs/all/skyscraper/config.ini" space_around_delimiters=false
}

setup
