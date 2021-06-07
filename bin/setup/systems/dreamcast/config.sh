#!/bin/bash

system='dreamcast'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

config_path="$retropie_system_config_dir/redream/redream.cfg"

restore_config() {
  if has_backup "$config_path"; then
    if [ -f "$config_path" ]; then
      # Keep track of the profiles since we don't want to lose those
      grep -E '^profile[0-9]+' "$config_path" > "$system_tmp_dir/profiles.cfg"

      restore "$config_path" "${@}"

      # Merge the profiles back in
      crudini --merge --inplace "$config_path" < "$system_tmp_dir/profiles.cfg"
      rm "$system_tmp_dir/profiles.cfg"
    else
      restore "$config_path" "${@}"
    fi
  fi
}

install() {
  restore_config
  ini_merge "$system_config_dir/redream.cfg" "$config_path" restore=false
}

uninstall() {
  restore_config delete_src=true
}

"${@}"
