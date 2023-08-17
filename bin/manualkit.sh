#!/bin/bash

export SKIP_SYSTEM_CHECK=true

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

usage() {
  echo "usage:"
  echo " $0 remote_sync_system_manuals <system|all>"
  echo " $0 remote_sync_manuals_description <date>"
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

# Sync manuals to internetarchive
remote_sync_system_manuals() {
  local system=$1

  local install='true'
  local upload_sources='true'
  local upload_manuals='true'
  if [ $# -gt 1 ]; then local "${@:2}"; fi

  # Make sure this system has manuals defined for it
  if ! each_path "{data_dir}/$system.json" jq -r '.[] | select(.manuals)' '{}' | grep -q manuals; then
    return
  fi

  local archive_id=$(setting '.manuals.archive.id')
  local version=$(setting '.manuals.archive.version')

  # Build the sources reference
  local data_file=$(mktemp -p "$tmp_ephemeral_dir")
  json_merge "{data_dir}/$system.json" "$data_file" backup=false
  jq -r 'to_entries[] | select(.value.manuals) | .key as $group | .value.manuals[] | [.name // $group, (.languages | join(",")), .url] | @tsv' "$data_file" > "$data_file.sources"

  # Build the missing reference
  jq -r 'to_entries[] | select(.value.manuals == null and .value.group == null) | .key' "$data_file" > "$data_file.missing"

  local manuals_count=$(cat "$data_file.sources" | wc -l)
  local missing_count=$(cat "$data_file.missing" | wc -l)
  echo "$system manuals ($manuals_count, missing: $missing_count)"
  if [ "$upload_sources" == 'true' ]; then
    # Upload sources reference
    ia upload "$archive_id" "$data_file.sources" --remote-name="$system/$system-sources.tsv" --no-derive -H x-archive-keep-old-version:0
    ia upload "$archive_id" "$data_file.missing" --remote-name="$system/$system-missing.tsv" --no-derive -H x-archive-keep-old-version:0
  fi

  # Download and process the manuals
  if [ "$install" == 'true' ]; then
    MANUALKIT_ARCHIVE=true "$bin_dir/setup.sh" update system-roms-manuals $system || return
  fi

  # Identify the post-processing base directory
  local base_dir_template=$(setting '.manuals.paths.base')
  local base_dir=$(render_template "$base_dir_template" system="$system")
  local postprocess_file_template=$(setting '.manuals.paths.postprocess')
  local postprocess_dir_template=$(dirname "$postprocess_file_template")
  local postprocess_dir=$(render_template "$postprocess_dir_template" base="$base_dir" system="$system")

  # Ensure the path actually exists and has files in it
  if [ "$upload_manuals" == 'true' ] && [ -d "$postprocess_dir" ] && [ -n "$(ls -A "$postprocess_dir")" ]; then
    # Zip up the files and upload to internetarchive
    local zip_file=$(mktemp -u -p "$tmp_ephemeral_dir")
    zip -j -db -r "$zip_file" "$postprocess_dir"/*.pdf
    ia upload "$archive_id" "$zip_file" --remote-name="$system/$system-$version.zip" --no-derive -H x-archive-keep-old-version:0
    rm "$zip_file"
  fi
}

remote_sync_manuals_description() {
  local updated_at=${1:-$(date +'%Y-%m-%d')}

  local archive_id=$(setting '.manuals.archive.id')

  # Build counts for each system
  local counts=()
  while read system; do
    echo "Checking manual count for $system..."

    local data_file=$(mktemp -p "$tmp_ephemeral_dir")
    json_merge "{data_dir}/$system.json" "$data_file" backup=false >/dev/null

    local found_count=$(jq -r 'to_entries[] | select(.value.manuals) | .value.manuals[] | .url' "$data_file" | wc -l)
    local missing_count=$(jq -r 'to_entries[] | select(.value.manuals == null and .value.group == null) | .key' "$data_file" | wc -l)

    counts+=("\"$system\": {\"found_count\": $found_count, \"missing_count\": $missing_count}")
  done < <(setting '.systems[]' | grep -Ev "mess|gameandwatch")

  # Builds counts for mess systems
  declare -A mess_systems=(
    [gameandwatch]='Game & Watch'
    [tiger]='Tiger Electronics LCD'
  )
  local mess_data_file=$(mktemp -p "$tmp_ephemeral_dir")
  json_merge '{data_dir}/mess.json' "$mess_data_file" backup=false >/dev/null
  for system in "${!mess_systems[@]}"; do
    echo "Checking manual count for $system..."

    local tag=${mess_systems[$system]}

    local jq_filter="[to_entries[] | select(.value.tags | index(\"$tag\")) | .key] as \$keys | to_entries[] | (.value.group // .key) as \$group | select(\$keys | index(\$group))"
    local found_count=$(jq -r "$jq_filter | select(.value.manuals) | .value.manuals[] | .url" "$mess_data_file" | wc -l)
    local missing_count=$(jq -r "$jq_filter | select(.value.manuals == null and .value.group == null) | .key" "$mess_data_file" | wc -l)

    counts+=("\"$system\": {\"found_count\": $found_count, \"missing_count\": $missing_count}")
  done

  # Generate merged metadata file
  local json_metadata_file=$(mktemp -p "$tmp_ephemeral_dir" --suffix=.json)
  cp "$docs_dir/manuals.json" "$json_metadata_file"

  local json_updates_file=$(mktemp -p "$tmp_ephemeral_dir")
  echo "{\"updated_at\": \"$updated_at\", \"systems\":{$(IFS=, ; echo "${counts[*]}")}}" > "$json_updates_file"
  json_merge "$json_updates_file" "$json_metadata_file" >/dev/null

  # Generate html description
  local description=$(jinja2 "$docs_dir/manuals.html.jinja" "$json_metadata_file")

  # Synchronize it to the archive
  ia metadata "$archive_id" --modify="description:$description"
}

if [[ $# -lt 1 ]]; then
  usage
fi

main "$@"
