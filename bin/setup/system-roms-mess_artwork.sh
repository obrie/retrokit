#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-mess_artwork'
setup_module_desc='Download artwork for MAME-based system'

system_artwork_dir="$retropie_system_config_dir/mame/artwork"

build() {
  if ! has_emulator 'lr-mess'; then
    return
  fi

  mkdir -p "$system_artwork_dir"

  while IFS=$'\t' read -r name artwork_url; do
    download "$artwork_url" "$system_artwork_dir/$name.zip"
  done < <(romkit_cache_list | jq -r 'select(.media .artwork) | [.name, .media .artwork] | @tsv')
}

configure() {
  restore

  # Check to see if we're re-configuring the default artwork
  local background_only=$(system_setting '.mess .artwork .background_only')
  if [ "$background_only" != 'true' ]; then
    return
  fi

  while read -r name; do
    local artwork_path="$system_artwork_dir/$name.zip"
    if [ ! -f "$artwork_path" ]; then
      # No artwork: abort
      continue
    fi

    local layout_path="$system_artwork_dir/$name/$name.lay"

    # Extract the layout file so we can store it in an override location
    mkdir -p "$system_artwork_dir/$name"
    unzip -p "$artwork_path" default.lay > "$layout_path"

    # Build the background view
    local view_xml=$(__build_background_view "$layout_path")
    if [ -n "$view_xml" ]; then
      local view_name=$(echo "$view_xml" | xmlstarlet sel -t -v '/view/@name')
      echo "[$name] Prioritizing artwork view: $view_name"

      # Get existing children (removing any with the same view name)
      local existing_xml=$(xmlstarlet ed -P -d "/*/view[@name='$view_name']" "$layout_path" | xmlstarlet sel -I -t -c '/mamelayout/*')

      # Merge background view with existing children
      local tmp_layout_path="$(mktemp -p "$tmp_ephemeral_dir")"
      cat "$layout_path" |\
        xmlstarlet ed -d '/mamelayout/*' -d '//comment()' |\
        xmlstarlet ed -s '/mamelayout' -t text -n '' -v $'\n'"$view_xml"$'\n' -s '/mamelayout' -t text -n '' -v "$existing_xml" |\
        xmlstarlet unescape > "$tmp_layout_path"
      mv "$tmp_layout_path" "$layout_path"
    else
      echo "[$name] Could not find background artwork view"
      rm -rf "$system_artwork_dir/$name"
    fi
  done < <(romkit_cache_list | jq -r '.name')
}

__build_background_view() {
  local layout_path=$1

  local external_only_views=(
    "Backdrop_Only"
    "Background Only (No Shadow)"
    "Background Only"
    "Backgrounds Only (No Shadow)"
    "Backgrounds Only"
    "Background Only (No Reflection)"
    "External Layout"
  )
  local unit_views=(
    "Unit Only"
  )
  local xml

  # Try to find a view that we know only contains the background (i.e. no unit)
  local view_name
  for view_name in "${external_only_views[@]}"; do
    xml=$(xmlstarlet select -t -c "/*/view[@name=\"$view_name\"]" "$layout_path")
    if [ -n "$xml" ]; then
      echo "$xml"
      return
    fi
  done

  # Try to find the most basic Unit view and remove the Unit data from it
  for view_name in "${unit_views[@]}"; do
    xml=$(xmlstarlet select -t -c "/*/view[@name=\"$view_name\"]" "$layout_path")
    if [ -n "$xml" ]; then
      echo "$xml" | xmlstarlet ed -O \
        -d '/view/*[@element="Unit"]' \
        -u '/*/*/bounds/@x' -v 0 \
        -u '/*/*/bounds/@y' -v 0 \
        -u '/view/@name' -v 'Background Only'
      return
    fi
  done
}

restore() {
  if [ ! -d "$system_artwork_dir" ]; then
    return
  fi

  find "$system_artwork_dir" -mindepth 1 -type d -exec rm -rfv '{}' +
}

vacuum() {
  if ! has_emulator 'lr-mess'; then
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
