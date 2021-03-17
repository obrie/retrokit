#!/bin/bash

set -ex

DIR=$(dirname "$0")
APP_DIR=$(cd "$DIR/../../.." && pwd)
DOWNLOAD_DIR="$APP_DIR/tmp/c64"
mkdir -p "$DOWNLOAD_DIR"

# Install config
ROMS_DIR="/home/pi/RetroPie/roms/c64"
ALL_DIR="$ROMS_DIR/- All -"
DUPLICATES_DIR="$ROMS_DIR/.duplicates"
mkdir -p "$DUPLICATES_DIR"

# Torrent config
SEED_TIME=0
TORRENT_FILE="$DOWNLOAD_DIR/no-intro.torrent"
TORRENT_FILTER="$TORRENT_FILE.filter"
TORRENT_DIR="/var/lib/transmission-daemon/downloads/***REMOVED***"

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

  # Add Torrent
  transmission-remote -t all --remove
  transmission-remote --start-paused -a "$TORRENT_FILE"
  id=$(transmission-remote --list | grep -oE "^ +[0-9]" | tr -d ' ')

  # Filter Torrent
  cat > "$TORRENT_FILTER" <<EOF
Commodore - 64.zip
Commodore - 64 (PP).zip
EOF
  select_files=$(transmission-remote -t $id --files | grep -F -f "$TORRENT_FILTER" | grep -oE "^ +[0-9]+" | tr -d " " | tr '\n' ',' | sed 's/,*$//g')
  transmission-remote -t $id --no-get all
  transmission-remote -t $id --get $select_files

  # Download Torrent
  transmission-remote -t $id --start
  while ! transmission-remote -t $id --info | grep "Percent Done: 100%" > /dev/null; do
    transmission-remote -t $id --info | grep -A 10 TRANSFER
    echo "Downloading..."
  done
  transmission-remote -t all --remove

  # Extract files
  while read file; do
    unzip -o "$TORRENT_DIR/$file" -d "$ALL_DIR/"
    sudo rm "$TORRENT_DIR/$file"
  done < $TORRENT_FILTER
}

# Blacklist keywords
blacklist_games() {
  find "$ALL_DIR/" -regextype posix-extended -regex '.*(Strip|BIOS).*' -delete
}

# Prefer USA games over Europe games
remove_duplicates() {
  find "$ALL_DIR"  -printf "%f\n" | grep -oE "^[^(]+" | uniq | while read -r game; do
    find "$ALL_DIR" -type f -name "$game \(*" | sort -r | tail -n +2 | xargs -d '\n' -I{} mv "{}" "$DUPLICATES_DIR/"
  done
}

add_defaults() {
  jq -r ".default[]" "$DIR/roms.json" | xargs -I{} ln -fs "$ALL_DIR/{}" "$ROMS_DIR/{}"
}

install() {
  install_torrent
  blacklist_games
  remove_duplicates
  add_defaults
}

if [[ $# -gt 1 ]]; then
  usage
fi

command=${1:-install}
"$command"
