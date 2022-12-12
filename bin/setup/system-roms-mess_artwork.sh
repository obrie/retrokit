#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-mess_artwork'
setup_module_desc='Download artwork for MAME-based system'

system_artwork_dir="$retropie_system_config_dir/mame/artwork"

build() {
  if ! has_emulator 'lr-mess' || ! any_path_exists '{system_config_dir}/artwork.tsv'; then
    return
  fi

  mkdir -p "$system_artwork_dir"

  declare -A artwork_urls
  for artwork_path in '{config_dir}/mess/artwork.tsv' '{system_config_dir}/artwork.tsv'; do
    while IFS=$'\t' read -r name url; do
      artwork_urls[$name]=$url
    done < <(each_path "$artwork_path" cat '{}')
  done

  while read -r name; do
    local artwork_url=${artwork_urls[$name]}
    if [ -z "$artwork_url" ]; then
      continue
    fi

    download "$artwork_url" "$system_artwork_dir/$name.zip"
  done < <(romkit_cache_list | jq -r '.name')
}

vacuum() {
  if ! has_emulator 'lr-mess' || ! any_path_exists '{system_config_dir}/artwork.tsv'; then
    return
  fi

  declare -A installed_artwork
  while IFS=$'\t' read -r name; do
    installed_artwork["$system_artwork_dir/$name.zip"]=1
  done < <(romkit_cache_list | jq -r '.name')

  # Generate rm commands for unused artwork
  while read -r path; do
    [ "${installed_artwork["$path"]}" ] || echo "rm -fv $(printf '%q' "$path")"
  done < <(find "$system_artwork_dir" -name '*.zip')
}

remove() {
  rm -rfv "$system_artwork_dir/"*
}

setup "${@}"
