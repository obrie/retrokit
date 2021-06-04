#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

install() {
  local gamelist_file="$HOME/.emulationstation/gamelists/$system/gamelist.xml"
  if [ ! -f "$gamelist_file" ]; then
    echo 'No gamelist available'
    return
  fi

  # Reset by removing all favorite tags first.  This is much faster than
  # deleting one-by-one given the size of the file.
  xmlstarlet ed --inplace -d "/gameList/game/favorite" "$gamelist_file"

  # Then add current favorites
  echo 'Setting favorites...'
  while IFS="$tab" read rom_name; do
    xmlstarlet ed --inplace -s "/gameList/game[name=\"$rom_name\" or contains(image, \"/$rom_name.\")]" -t elem -n 'favorite' -v 'true' "$gamelist_file"
  done < <(romkit_cache_list | jq -r 'select(.favorite == true) | .name')
}

uninstall() {
  if [ ! -f "$HOME/.emulationstation/gamelists/$system/gamelist.xml" ]; then
    echo 'No gamelist available'
    return
  fi

  echo "Removing favorite flags from $HOME/.emulationstation/gamelists/$system/gamelist.xml"
}

"$1" "${@:3}"
