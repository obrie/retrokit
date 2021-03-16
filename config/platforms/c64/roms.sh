#!/bin/bash

set -ex

DIR=$(dirname "$0")
SEED_TIME=0
ROMS_DIR=/home/pi/RetroPie/roms/c64
ALL_DIR=$ROMS_DIR/-\ All\ -

# No-Intro Torrent
NO_INTRO_TORRENT=/tmp/no-intro.torrent
NO_INTRO_DIR=/tmp/***REMOVED***

usage() {
  echo "usage: $0 [command]"
  exit 1
}

download_torrent() {
  if [ ! -f "$NO_INTRO_TORRENT" ]; then
    wget -nc https://archive.org/download/***REMOVED***/***REMOVED***_archive.torrent -O "$NO_INTRO_TORRENT"
  fi
}

# Blacklist keywords
blacklist_games() {
  find $ROMS_DIR/ -regextype posix-extended -regex '.*(Strip|BIOS).*' -delete
}

install_no_intro_file() {
  file=$1

  download_torrent

  # Create directories
  mkdir -p $ALL_DIR

  if [ ! -f "$NO_INTRO_DIR/$file" ]; then
    torrent_index=$(aria2c -S $NO_INTRO_TORRENT | grep "$file" | cut -d"|" -f 1 | tr -d " ")
    aria2c $NO_INTRO_TORRENT -d /tmp/ --select-file $torrent_index --seed-time=$SEED_TIME
    unzip -o "$NO_INTRO_DIR/$file" -d "$ALL_DIR/"
  fi

  blacklist_games
}

# No-Intro Tapes
install_tapes() {
  install_no_intro_file "Commodore - 64 (Tapes).zip"
}

# No-Intro Cartridges
install_cartridges() {
  install_no_intro_file "Commodore - 64.zip"
}

add_defaults() {
  jq -r ".default[]" $DIR/roms.json | xargs -I{} ln -fs "$ALL_DIR/{}" "$ROMS_DIR/{}"
}

setup() {
  install_tapes
  install_cartridges
  add_defaults
}

if [[ $# -gt 1 ]]; then
  usage
fi

command=${1:-all}
"$command"
