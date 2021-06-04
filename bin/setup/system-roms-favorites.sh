#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

install() {
  local gamelist_file="$HOME/.emulationstation/gamelists/$system/gamelist.xml"
  if [ ! -f "$gamelist_file" ]; then
    echo 'No gamelist available'
    return
  fi

  echo 'Setting favorites...'
  while IFS="$tab" read rom_name is_favorite; do
    if [ "$is_favorite" == 'true' ]; then
      xmlstarlet ed --inplace -s "/gameList/game[not(favorite) and (name=\"$rom_name\" or contains(image, \"/$rom_name.\"))]" -t elem -n 'favorite' -v 'true' "$gamelist_file"
    else
      # Make sure there's no favorite tag
      xmlstarlet ed --inplace -d "/gameList/game[name=\"$rom_name\" or contains(image, \"/$rom_name.\")]/favorite" "$gamelist_file"
    fi
  done < <(romkit_cache_list | jq -r '[.name, .favorite] | @tsv')
}

uninstall() {
  if [ ! -f "$HOME/.emulationstation/gamelists/$system/gamelist.xml" ]; then
    echo 'No gamelist available'
    return
  fi

  echo "Removing favorite flags from $HOME/.emulationstation/gamelists/$system/gamelist.xml"
}

"$1" "${@:3}"
