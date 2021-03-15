#!/bin/bash

##############
# ROM manager
##############

set -ex

scrape() {
  platform=$1

  # Scrape
  /opt/retropie/supplementary/skyscraper/Skyscraper -p $platform -g "/home/pi/.emulationstation/gamelists/$system" -o "/home/pi/.emulationstation/downloaded_media/$platform" -s screenscraper --flags "unattend,skipped,videos"

  # Generate game list
  /opt/retropie/supplementary/skyscraper/Skyscraper -p $platform -g "/home/pi/.emulationstation/gamelists/$system" -o "/home/pi/.emulationstation/downloaded_media/$platform" --flags "unattend,skipped,videos"
}

# Kill emulation station
killall emulationstation

if [ "$1" -eq "all" ]; then
  for platform_dir in platforms/*; do
    platform=$(basename "$platform_dir")
    scrape "$platform"
  done
else
  scrape "$1"
fi