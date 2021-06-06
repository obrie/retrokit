#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

# Install playlists for multi-disc roms
install() {
  if [ ! -d "$HOME/RetroPie/roms/$system" ]; then
    # No roms installed
    echo 'No ROMs to install playlists for'
    return
  fi

  echo 'Looking for multi-disc ROMs...'
  declare -A installed_files
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
    echo "Adding $rom_filename to $playlist_path"
    echo "$rom_filename" >> "$playlist_path"
    installed_files["$playlist_path"]=1
  done < <(find "$HOME/RetroPie/roms/$system" -type l -name "*(Disc *" | sort)

  # Remove playlists we no longer needed
  while read path; do
    [ ! "${installed_files["$path"]}" ] && rm -v "$path"
  done < <(find "$HOME/RetroPie/roms/$system" -name '*.m3u')
}

uninstall() {
  find "$HOME/RetroPie/roms/$system" -name '*.m3u' -exec rm -fv "{}" \;
}

"$1" "${@:3}"
