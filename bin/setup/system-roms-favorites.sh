#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

gamelist_file="$HOME/.emulationstation/gamelists/$system/gamelist.xml"

remove_favorites() {
  xmlstarlet ed --inplace -d "/gameList/game/favorite" "$gamelist_file"
}

install() {
  if [ ! -f "$gamelist_file" ]; then
    echo 'No gamelist available'
    return
  fi

  # Reset by removing all favorite tags first.  This is much faster than
  # deleting one-by-one given the size of the file.
  echo 'Resetting favorites...'
  remove_favorites

  # Then add current favorites
  echo 'Setting favorites...'
  while IFS="$tab" read rom_name; do
    xmlstarlet ed --inplace -s "/gameList/game[name=\"$rom_name\" or contains(image, \"/$rom_name.\")][1][not(favorite)]" -t elem -n 'favorite' -v 'true' "$gamelist_file"
  done < <(romkit_cache_list | jq -r 'select(.favorite == true) | .name')
}

uninstall() {
  if [ ! -f "$gamelist_file" ]; then
    echo 'No gamelist available'
    return
  fi

  echo "Removing favorite flags from $gamelist_file"
  remove_favorites
}

"$1" "${@:3}"
