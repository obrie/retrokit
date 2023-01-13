#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-favorites'
setup_module_desc='Manages favorites in the system gamelist'

gamelist_file="$HOME/.emulationstation/gamelists/$system/gamelist.xml"

configure() {
  if ! __should_set_favorites; then
    return
  fi

  # Add current favorites.
  # 
  # Note this will *not* remove existing favorites.  If you want to
  # completely replace your favorites list, you should run a reinstall
  # of this setup module.
  while IFS=$'\t' read -r rom_name playlist_name; do
    # Always search for the specific ROM
    __add_favorite "$rom_name"

    # Check for a playlist
    if [ -n "$playlist_name" ]; then
      __add_favorite "$playlist_name"
    fi
  done < <(echo "$favorites")
}

restore() {
  if ! __should_set_favorites; then
    return
  fi

  echo "Removing favorite flags from $gamelist_file"
  __remove_favorites
}

# Checks whether we should be managing favorites
__should_set_favorites() {
  if [ ! -f "$gamelist_file" ]; then
    echo 'No gamelist available'
    return 1
  fi

  favorites=$(romkit_cache_list | jq -r 'select(.favorite == true) | [.name, .playlist.name] | @tsv')
  if [ -z "$favorites" ]; then
    echo 'No favorites found.  Assuming favorites are being managed manually.'
    return 1
  fi
}

# Adds the rom with the given name as a favorite
__add_favorite() {
  local name=$1
  echo "Adding $name to favorites"
  xmlstarlet ed --inplace -s "/gameList/game[contains(path, \"/$name.\")][1][not(favorite)]" -t elem -n 'favorite' -v 'true' "$gamelist_file"
}

# Removes all configured favorites
__remove_favorites() {
  xmlstarlet ed --inplace -d '/gameList/game/favorite' "$gamelist_file"
}

setup "${@}"
