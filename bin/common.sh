#!/bin/bash

##############
# Directories
##############

dir=$(dirname "$0")
export app_dir=$(cd "$dir/.." && pwd)
export data_dir="$app_dir/data"
export tmp_dir="$app_dir/tmp"

# Settings
export app_settings_file="$app_dir/config/settings.json"
export tab=$'\t'

# RetroPie Configurations
export retropie_dir="/opt/retropie"
export retroarch_dir="$retropie_configs_dir/all/retroarch"
export retroarch_cores_config="$retropie_dir/configs/all/retroarch-core-options.cfg"
export es_settings_config="$HOME/.emulationstation/es_settings.cfg"
export es_systems_config="$HOME/.emulationstation/es_systems.cfg"

##############
# Logging
##############

log() {
  echo "${@}"
}

##############
# File Management
##############

backup() {
  for file in "$@"; do
    if [ ! -s "$file" ]; then
      log "Backing up: $file to $file.org"
      sudo cp "$file" "$file.orig"
    fi
  done
}

##############
# Settings
##############

app_setting() {
  jq -r "$1 | values" "$app_settings_file"
}

##############
# Downloads
##############

download_file() {
  # Arguments
  local url="$1"
  local output="$2"

  local force="false"
  local refresh="false"
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  if [ ! -s "$output" ] || [ "$force" == "true" ] || [ "$refresh" == "true" ]; then
    echo "Downloading $url"

    if [ "$refresh" == "true" ]; then
      # Attempt to refresh based on modification date
      curl -fL# -o "$output" -z "$output" "$url"
    else
      # Download via curl
      curl -fL# -o "$output" "$url"
    fi

    # If the output is empty, clean up and let the caller know
    if [ ! -s "$output" ]; then
      rm -f "$output"
      return 1
    fi
  else
    echo "Already downloaded $url"
  fi
}