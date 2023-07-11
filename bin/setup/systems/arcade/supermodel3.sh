#!/bin/bash

system="${2:-arcade}"
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/arcade/supermodel3'
setup_module_desc='SuperModel3 configuration settings'

config_file="$retropie_configs_dir/supermodel3/Supermodel.ini"

configure() {
  if [ ! -f "$config_file.orig" ]; then
    cp -v "$config_file" "$config_file.orig"
  else
    cp -v "$config_file.orig" "$config_file.rk-src"
  fi

  # Convert the original file into a valid ini
  for file in "$config_file" "$config_file.rk-src"; do
    if [ ! -f "$file" ]; then
      continue
    fi

    # Remove:
    # * Leading / trailing spaces in sections
    # * Leading spaces before comments
    # * Trailing comments on configuration lines
    sed -i 's/^ *\[ *\([^] ]*\) *\]/[\1]/g' "$file"
    sed -i 's/^ \+;/;/g' "$file"
    sed -i 's/^\([^;].*=.*\) \+\(;.*\)$/\2\n\1/g' "$file"
    sed -i 's/ \+$//g' "$file"
  done

  __restore_config
  ini_merge '{system_config_dir}/supermodel3/Supermodel.ini' "$config_file" restore=false
}

restore() {
  __restore_config delete_src=true

  if [ -f "$config_file.orig" ]; then
    mv -v "$config_file.orig" "$config_file"
  fi
}

__restore_config() {
  restore_partial_ini "$config_file" '^Input(?!.*AutoTrigger)' remove_source_matches=true "${@}"
}

setup "${@}"
