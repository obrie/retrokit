#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

# Install playlists for multi-disc roms
install() {
  while read -r rom_path; do
    local rom_filename=$(basename "$rom_path")

    # Generate the playlist path
    local base_path="${rom_path// (Disc [0-9]*)/}"
    local base_filename=$(basename "$base_path")
    local playlist_path="$(dirname "$base_path")/${base_filename%%.*}.m3u"

    # Reset if we're on the first disc
    if [[ "$rom_filename"  == *'(Disc 1)'* ]]; then
      truncate -s0 "$playlist_path"
    fi

    # Add to the playlist
    echo "$rom_filename" >> "$playlist_path"
  done < <(find "$HOME/RetroPie/roms/$system" -type l -name "*(Disc *" | sort)
}

uninstall() {
  echo 'No uninstall for rom playlists'
}

"$1" "${@:3}"
