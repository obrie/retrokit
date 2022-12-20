#!/bin/bash

##############
# Cache management
##############

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

usage() {
  echo "usage:"
  echo " $0 delete"
  echo " $0 sync_system_nointro_dats <system|all> <love_pack_pc_zip_file>"
  echo " $0 sync_system_metadata <system|all>"
  exit 1
}

main() {
  local action=$1

  if [[ "$action" == *system* ]]; then
    # Action is system-specific.  Either run against all systems
    # or against a specific system.
    local system=$2

    if [ -z "$system" ] || [ "$system" == 'all' ]; then
      while read system; do
        print_heading "Running $action for $system (${*:3})"
        "$action" "$system" "${@:3}"
      done < <(setting '.systems[]')
    else
      print_heading "Running $action for $system (${*:3})"
      "$action" "$system" "${@:3}"
    fi
  else
    # Action is not system-specific.
    "$action" "${@:2}"
  fi
}

delete() {
  local system=$1

  local delete_path=$tmp_dir
  if [ -n "$system" ] && [ "$system" != 'all' ]; then
    delete_path="$delete_path/$system"
  fi

  # Remove cached data
  rm -rfv "$delete_path"/*
}

sync_system_nointro_dats() {
  [[ $# -ne 2 ]] && usage
  local system=$1
  local nointro_pack_path=$2

  while read -r dat_path; do
    local nointro_name=$(basename "$dat_path" .dat)
    local zip_filename=$(zipinfo -1 "$nointro_pack_path" | grep "$nointro_name" | head -n 1)

    if [ -n "$zip_filename" ]; then
      unzip -j "$nointro_pack_path" "$zip_filename" -d "$tmp_dir/"
      cat "$tmp_dir/$zip_filename" | tr -d '\r' > "$cache_dir/nointro/$nointro_name.dat"
      rm "$tmp_dir/$zip_filename"
    else
      echo "[WARN] No dat file found for $system"
    fi
  done < <(jq -r 'select(.romsets) | .romsets[] | select(.name | test("nointro")) | .resources.dat.source' "$app_dir/config/systems/$system/settings.json")
}

sync_system_metadata() {
  local system=$1
  if [ "$system" == 'ports' ]; then
    return
  fi

  . "$dir/setup/system-common.sh"
  TMPDIR="$tmp_dir" python3 "$bin_dir/tools/scrape-metadata.py" "$system_settings_file" "${@:2}"
}

# Sync manuals to internetarchive
remote_sync_system_manuals() {
  local system=$1

  local sources_only='false'
  local install='true'
  if [ $# -gt 1 ]; then local "${@:2}"; fi

  # Make sure this system has manuals defined for it
  if ! any_path_exists "{config_dir}/systems/$system/manuals.tsv"; then
    return
  fi

  local archive_id=$(setting '.manuals.archive.id')
  local version=$(setting '.manuals.archive.version')

  # Update the sources reference
  ia upload "$archive_id" "$config_dir/systems/$system/manuals.tsv" --remote-name="$system/$system-sources.tsv" --no-derive -H x-archive-keep-old-version:0
  if [ "$sources_only" == 'true' ]; then
    return
  fi

  # Download and process the manuals
  if [ "$install" == 'false' ] || MANUALKIT_ARCHIVE=true "$bin_dir/setup.sh" install system-roms-manuals $system; then
    # Identify the post-processing base directory
    local base_path_template=$(setting '.manuals.paths.base')
    local base_path=$(render_template "$base_path_template" system="$system")
    local postprocess_path_template=$(setting '.manuals.paths.postprocess')
    local postprocess_dir_template=$(dirname "$postprocess_path_template")
    local postprocess_dir=$(render_template "$postprocess_dir_template" base="$base_path" system="$system")

    # Ensure the path actually exists and has files in it
    if [ -d "$postprocess_dir" ] && [ -n "$(ls -A "$postprocess_dir")" ]; then
      # Zip up the files and upload to internetarchive
      local zip_path="$tmp_ephemeral_dir/$system.zip"
      zip -j -db -r "$zip_path" "$postprocess_dir"/*.pdf
      ia upload "$archive_id" "$zip_path" --remote-name="$system/$system-$version.zip" --no-derive -H x-archive-keep-old-version:0
      rm "$zip_path"
    fi
  fi
}

reclone_system_redump_dats() {
  local system=$1

  . "$dir/setup/system-common.sh"

  # Look to see whether a redump dat exists
  local redump_dat_path=$(system_setting '.romsets[] | select(.name == "redump") | .resources.dat.target')
  if [ -z "$redump_dat_path" ]; then
    return
  fi

  # Re-generate clones
  "$bin_dir/tools/reclone.py" "$system_config_dir/clones.json" "$redump_dat_path"
}

if [[ $# -lt 1 ]]; then
  usage
fi

main "$@"
