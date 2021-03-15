#!/bin/bash

set -ex

DIR=$(pwd)
SEED_TIME=0
ROMS_DIR=/home/pi/RetroPie/roms/c64
ALL_DIR=$ROMS_DIR/-\ All\ -

# Create directories
mkdir -p $ALL_DIR

# No-Intro Torrent
NO_INTRO_TORRENT=/tmp/no-intro.torrent
NO_INTRO_DIR=/tmp/***REMOVED***
if [ ! -f "$NO_INTRO_TORRENT" ]; then
  wget -nc https://archive.org/download/***REMOVED***/***REMOVED***_archive.torrent -O $NO_INTRO_TORRENT
fi

# No-Intro Tapes
if [ ! -f "$NO_INTRO_DIR/Commodore\ -\ 64\ \(Tapes\).zip" ]; then
  aria2c $NO_INTRO_TORRENT -d /tmp/ --select-file 23 --seed-time=$SEED_TIME
  unzip -o "$NO_INTRO_DIR/Commodore - 64 (Tapes).zip" -d "$ALL_DIR/"
fi

# No-Intro Cartridges
if [ ! -f "$NO_INTRO_DIR/Commodore\ -\ 64.zip" ]; then
  aria2c $NO_INTRO_TORRENT -d /tmp/ --select-file 25 --seed-time=$SEED_TIME
  unzip -o "$NO_INTRO_DIR/Commodore - 64.zip" -d "$ALL_DIR/"
fi

# Blacklist keywords
find $ROMS_DIR/ -regextype posix-extended -regex '.*(Strip|BIOS).*' -delete

# Add defaults
jq -r ".default[]" $DIR/roms.json | xargs -I{} ln -fs "$ALL_DIR/{}" "$ROMS_DIR/{}"
