#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

# Install playlists for multi-disc roms
install() {
  if [ ! -d "$HOME/RetroPie/roms/$system" ]; then
    echo 'No ROMs to install playlists for'
    return
  fi

  if ! supports_playlists; then
    echo 'Playlists not supported'
    return
  fi

  # Remove existing playlists
  restore

  echo 'Creating playlists...'
  declare -A installed_files
  while read -r rom_name; do
    local playlist_name=$(get_playlist_name "$rom_name")

    while read rom_path; do
      # Get playlist path
      local playlist_path="$(dirname "$rom_path")/$playlist_name.m3u"

      # Add to the playlist
      echo "Adding $rom_path to $playlist_path"
      echo "$rom_path" >> "$playlist_path"
      installed_files["$playlist_path"]=1

      # Remove from the filesystem (safety guard in place to ensure it's a
      # symlink)
      if ! show_discs && [ -L "$rom_path" ]; then
        backup_file "$rom_path"
        rm -v "$rom_path"
      fi
    done < <(__find_in_directories "$rom_name*")
  done < <(romkit_cache_list | jq -r 'select(.disc != .title) | .name' | sort)
}

uninstall() {
  # Restore previously deleted ROMs
  while read -r backup_path; do
    restore_file "${backup_path//.rk-src/}" delete_src=true
  done < <(__find_in_directories '*.rk-src')

  # Remove existing playlists
  while read -r path; do
    rm -v "$path"
  done < <(__find_in_directories '*.m3u')
}

__find_in_directories() {
  system_setting '.roms.dirs[] | .path' | xargs -I{} find "{}" -mindepth 1 -maxdepth 1 -name "$1" 2>/dev/null
}

"$1" "${@:3}"
