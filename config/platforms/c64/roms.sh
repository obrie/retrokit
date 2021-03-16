#!/bin/bash

set -ex

DIR=$(dirname "$0")
APP_DIR=$(cd "$DIR/../../.." && pwd)
DOWNLOAD_DIR="$APP_DIR/tmp/c64"
mkdir -p "$DOWNLOAD_DIR"

# Install config
ROMS_DIR="/home/pi/RetroPie/roms/c64"
ALL_DIR="$ROMS_DIR/- All -"

# Torrent config
SEED_TIME=0
TORRENT_FILE="$DOWNLOAD_DIR/no-intro.torrent"
TORRENT_FILTER="$TORRENT_FILE.filter"
TORRENT_DIR="$DOWNLOAD_DIR/***REMOVED***"

usage() {
  echo "usage: $0 [command]"
  exit 1
}

download_torrent() {
  if [ ! -f "$TORRENT_FILE" ]; then
    wget "https://archive.org/download/***REMOVED***/***REMOVED***_archive.torrent" -O "$TORRENT_FILE"
  fi
}

install_torrent() {
  download_torrent

  # Create directories
  mkdir -p "$ALL_DIR"

  # Filter Torrent
  cat > $TORRENT_FILTER <<EOF
Commodore - 64 (Tapes).zip
Commodore - 64.zip
EOF
  select_files=$(aria2c -S "$TORRENT_FILE" | grep -F -f "$TORRENT_FILTER" | cut -d"|" -f 1 | tr -d " " | tr '\n' ',' | sed 's/,*$//g')

  # Download files
  aria2c "$TORRENT_FILE" -d "$DOWNLOAD_DIR" --select-file "$select_files" --seed-time=$SEED_TIME

  # Extract files
  cat $TORRENT_FILTER | xargs -I{} unzip -o "$TORRENT_DIR/{}" -d "$ALL_DIR/"
}

# Blacklist keywords
blacklist_games() {
  find $ROMS_DIR/ -regextype posix-extended -regex '.*(Strip|BIOS).*' -delete
}

add_defaults() {
  jq -r ".default[]" "$DIR/roms.json" | xargs -I{} ln -fs "$ALL_DIR/{}" "$ROMS_DIR/{}"
}

install() {
  install_torrent
  blacklist_games
  add_defaults
}

if [[ $# -gt 1 ]]; then
  usage
fi

command=${1:-all}
"$command"
