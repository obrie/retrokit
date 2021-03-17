#!/bin/bash

##############
# ROM manager
##############

set -ex

DIR=$(dirname "$0")
APP_DIR=$(cd "$DIR/.." && pwd)

usage() {
  echo "usage: $0"
  exit 1
}

scrape_platform() {
  platform=$1

  # Scrape
  /opt/retropie/supplementary/skyscraper/Skyscraper -p $platform -g "/home/pi/.emulationstation/gamelists/$system" -o "/home/pi/.emulationstation/downloaded_media/$platform" -s screenscraper --flags "unattend,skipped,videos"

  # Generate game list
  /opt/retropie/supplementary/skyscraper/Skyscraper -p $platform -g "/home/pi/.emulationstation/gamelists/$system" -o "/home/pi/.emulationstation/downloaded_media/$platform" --flags "unattend,skipped,videos"
}

scrape() {
  platform=$1

  # Kill emulation station
  killall emulationstation

  if [ "$platform" -eq "all" ]; then
    for platform_dir in platforms/*; do
      platform=$(basename "$platform_dir")
      scrape_platform "$platform"
    done
  else
    scrape_platform "$platform"
  fi
}

if [[ $# -lt 1 ]]; then
  usage
fi

command="$1"
popd
"$command" "$@"
