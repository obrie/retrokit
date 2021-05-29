#!/bin/bash

##############
# Cache management
##############

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

usage() {
  echo "usage:"
  echo " $0 delete"
  echo " $0 sync_nointro_dats <love_pack_pc_xml_file>"
  exit 1
}

delete() {
  # Remove all temporary cached data
  rm -rf $tmp_dir/*
}

sync_nointro_dats() {
  local nointro_pack_path=$1

  while read system; do
    while read dat_path; do
      local nointro_name=$(basename "$dat_path" .dat)
      local zip_filename=$(zipinfo -1 "$nointro_pack_path" | grep "$nointro_name" | head -n 1)

      if [ -n "$zip_filename" ]; then
        unzip -j "$nointro_pack_path" "$zip_filename" -d "$tmp_dir/"
        mv "$tmp_dir/$zip_filename" "$cache_dir/nointro/$nointro_name.dat"
      else
        echo "[WARN] No dat file found for $system"
      fi
    done < <(jq -r 'select(.romsets) | .romsets[] | select(.name == "nointro") | .resources.dat.source' "$app_dir/config/systems/$system/settings.json")
  done < <(setting '.systems[]')
}

main() {
  local action="$1"
  shift

  "$action" "$@"
}

if [[ $# -lt 1 ]]; then
  usage
fi

main "$@"
