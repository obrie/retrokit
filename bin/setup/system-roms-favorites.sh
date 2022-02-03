#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

gamelist_file="$HOME/.emulationstation/gamelists/$system/gamelist.xml"

alias install=configure
alias uninstall=restore

configure() {
  if ! __should_set_favorites; then
    return
  fi

  # Reset by removing all favorite tags first.  This is much faster than
  # deleting one-by-one given the size of the file.
  echo 'Resetting favorites...'
  __remove_favorites

  # Then add current favorites
  echo 'Setting favorites...'
  while read -r rom_name; do
    # Always search for the specific ROM (in case it's a playlists with show_discs enabled)
    __add_favorite "$rom_name"

    # Check for a playlist
    if has_playlist_config "$rom_name"; then
      __add_favorite "$(get_playlist_name "$rom_name")"
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

  favorites=$(romkit_cache_list | jq -r 'select(.favorite == true) | .name')
  if [ -z "$favorites" ]; then
    echo 'No favorites found.  Assuming favorites are being managed manually.'
    return 1
  fi
}

# Adds the roms with the given name as a favorite
__add_favorite() {
  local name=$1
  xmlstarlet ed --inplace -s "/gameList/game[contains(path, \"/$name.\")][1][not(favorite)]" -t elem -n 'favorite' -v 'true' "$gamelist_file"
}

# Removes all configured favorites
__remove_favorites() {
  xmlstarlet ed --inplace -d "/gameList/game/favorite" "$gamelist_file"
}

"$1" "${@:3}"
