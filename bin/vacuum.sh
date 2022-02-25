#!/bin/bash

##############
# Vacuum management
# 
# This will output `rm` commands to delete media files (roms, manuals, scraped media)
# that it believes are no longer needed based on the current set of roms installed by
# romkit.
##############

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

usage() {
  echo "usage:"
  echo " $0 <all|roms|manuals|media> <all|system>"
  exit 1
}

main() {
  local action=$1
  local system=$2

  if [ -z "$system" ] || [ "$system" == 'all' ]; then
    while read system; do
      "vacuum_$action" "$system" "${@:3}" | { grep -E "^rm " || true; }
    done < <(setting '.systems[]')
  else
    "vacuum_$action" "$system" "${@:3}" | { grep -E "^rm " || true; }
  fi
}

vacuum_all() {
  vacuum_roms "$@"
  vacuum_manuals "$@"
  vacuum_media "$@"
  vacuum_overlays "$@"
}

vacuum_roms() {
  local system=$1
  $bin_dir/setup.sh vacuum system-roms-download "$system"
}

vacuum_manuals() {
  local system=$1
  $bin_dir/setup.sh vacuum system-roms-manuals "$system"
}

vacuum_media() {
  local system=$1
  $bin_dir/setup.sh vacuum system-roms-scrape "$system"
}

vacuum_overlays() {
  local system=$1
  $bin_dir/setup.sh vacuum system-roms-overlays "$system"
}

if [[ $# -lt 1 ]]; then
  usage
fi

main "$@"
