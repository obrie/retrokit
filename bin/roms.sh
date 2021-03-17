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

install_from_torrent() {
  DOWNLOAD_DIR="$APP_DIR/tmp/$platform"
  mkdir -p "$DOWNLOAD_DIR"

  # Install config
  ROMS_DIR="/home/pi/RetroPie/roms/$platform"
  ROMS_ALL_DIR="$ROMS_DIR/- All -"
  ROMS_DUPLICATES_DIR="$ROMS_DIR/.duplicates"
  mkdir -p "$ROMS_DUPLICATES_DIR"

  # Torrent config
  SEED_TIME=0
  TORRENT_FILE="$DOWNLOAD_DIR/no-intro.torrent"
  TORRENT_FILTER="$TORRENT_FILE.filter"
  TORRENT_DIR="/var/lib/transmission-daemon/downloads/***REMOVED***"

  usage() {
    echo "usage: $0 [command]"
    exit 1
  }

  download() {
    if [ ! -f "$torrent_file" ]; then
      wget "$torrent_url" -O "$torrent_file"
    fi

    # Download Torrent

    # Extract files
    mkdir -p "$ROMS_ALL_DIR"
    while read file; do
      unzip -o "$TORRENT_DIR/$file" -d "$ROMS_ALL_DIR/"
      sudo rm "$TORRENT_DIR/$file"
    done < $TORRENT_FILTER

    find "$ROMS_ALL_DIR/" -regextype posix-extended -regex '.*(Strip|BIOS).*' -delete
  }

  # Blacklist keywords
  blacklist_games() {
  }

  # Prefer USA games over Europe games
  remove_duplicates() {

  }

  add_defaults() {
    jq -r ".default[]" "$DIR/roms.json" | xargs -I{} ln -fs "$ROMS_ALL_DIR/{}" "$ROMS_DIR/{}"
  }

  install() {
    download
    blacklist_games
    remove_duplicates
    add_defaults
  }

  if [[ $# -gt 1 ]]; then
    usage
  fi

  command=${1:-install}
  "$command"

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