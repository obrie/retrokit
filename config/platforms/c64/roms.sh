#!/bin/bash

set -ex

DIR=$(dirname "$0")
APP_DIR=$(cd "$DIR/../../.." && pwd)
DOWNLOAD_DIR="$APP_DIR/tmp/c64"
mkdir -p "$DOWNLOAD_DIR"

# Install config
ROMS_DIR="/home/pi/RetroPie/roms/c64"
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
  if [ ! -f "$TORRENT_FILE" ]; then
    wget "https://archive.org/download/***REMOVED***/***REMOVED***_archive.torrent" -O "$TORRENT_FILE"
  fi

  # Download Torrent
  cat > "$TORRENT_FILTER" <<EOF
Commodore - 64.zip
Commodore - 64 (PP).zip
EOF
  "$APP_DIR/bin/torrent.sh" "$TORRENT_FILE" "$TORRENT_FILTER"

  # Extract files
  mkdir -p "$ROMS_ALL_DIR"
  while read file; do
    unzip -o "$TORRENT_DIR/$file" -d "$ROMS_ALL_DIR/"
    sudo rm "$TORRENT_DIR/$file"
  done < $TORRENT_FILTER
}

# Blacklist keywords
blacklist_games() {
  find "$ROMS_ALL_DIR/" -regextype posix-extended -regex '.*(Strip|BIOS).*' -delete
}

# Prefer USA games over Europe games
remove_duplicates() {
  find "$ROMS_ALL_DIR"  -printf "%f\n" | grep -oE "^[^(]+" | uniq | while read -r game; do
    find "$ROMS_ALL_DIR" -type f -name "$game \(*" | sort -r | tail -n +2 | xargs -d '\n' -I{} mv "{}" "$ROMS_DUPLICATES_DIR/"
  done
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
