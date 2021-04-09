#!/bin/bash

##############
# Directories / Files
##############

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
export app_dir=$(cd "$dir/.." && pwd)
export config_dir="$app_dir/config"
export data_dir="$app_dir/data"
export tmp_dir="$app_dir/tmp"
export tmp_ephemeral_dir=$(mktemp -d -p "$tmp_dir")

# Clean up the ephemeral directory
trap 'rm -rf -- "$tmp_ephemeral_dir"' EXIT

# Settings
export settings_file="$app_dir/config/settings.json"
export tab=$'\t'

# Optional env for secrets
if [ -f "$app_dir/.env" ]; then
  source "$app_dir/.env"
fi

# Add dotenv
if [ -f "$tmp_dir/dotenv" ]; then
  . "$tmp_dir/dotenv"
fi

##############
# Logging
##############

log() {
  echo "${@}"
}

##############
# Settings
##############

setting() {
  jq -r "$1 | values" "$settings_file"
}

##############
# Config Management
##############

backup() {
  local file="$1"
  local backup_file="$file.orig"
  local as_sudo="false"
  if [ $# -gt 1 ]; then local "${@:2}"; fi

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  if [ -f "$file" ] && [ ! -f "$backup_file" ]; then
    log "Backing up: $file to $backup_file"
    $cmd cp "$file" "$backup_file"
  fi
}

restore() {
  local file="$1"
  local backup_file="$file.orig"
  local as_sudo="false"
  if [ $# -gt 1 ]; then local "${@:2}"; fi

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  if [ -f "$backup_file" ]; then
    log "Restoring: $backup_file to $file"
    $cmd cp "$backup_file" "$file"
  fi
}

backup_and_restore() {
  backup "${@}"
  restore "${@}"
}

env_merge() {
  local source="$1"
  local target="$2"
  local as_sudo="false"
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  backup_and_restore "$target" as_sudo=$as_sudo

  while IFS="$tab" read -r env_line; do
    if [ "$as_sudo" == 'true' ]; then
      sudo bash -c ". $tmp_dir/dotenv; .env -f \"$target\" set $env_line"
    else
      .env -f "$target" set $env_line
    fi
  done < <(cat "$(conf_prepare "$source")" | grep -Ev "^#")
}

ini_merge() {
  local source="$1"
  local target="$2"

  local space_around_delimiters="false"
  local as_sudo="false"
  if [ $# -gt 2 ]; then local "${@:3}"; fi
  
  backup_and_restore "$target" as_sudo="$as_sudo"

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  $cmd crudini --inplace --merge "$target" < "$(conf_prepare "$source")"

  if [ "$space_around_delimiters" = "false" ]; then
    $cmd sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" "$target"
  fi
}

json_merge() {
  local source="$1"
  local target="$2"

  local as_sudo="false"
  if [ $# -gt 2 ]; then local "${@:3}"; fi
  
  backup_and_restore "$target" as_sudo="$as_sudo"

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  local tmp_target="$(mktemp -p "$tmp_ephemeral_dir")"
  $cmd jq -s '.[0] * .[1]' "$target" "$(conf_prepare "$source")" > "$tmp_target"
  $cmd cp "$tmp_target" "$target"
}

conf_cp() {
  local source="$1"
  local target="$2"
  local as_sudo="false"
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  backup_and_restore "$target" as_sudo=$as_sudo

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  $cmd cp "$(conf_prepare "$source")" "$target"
}

conf_ln() {
  local source="$1"
  local target="$2"
  local as_sudo="false"
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  backup_and_restore "$target" as_sudo=$as_sudo

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  $cmd ln -fs "$source" "$target"
}

conf_prepare() {
  local source="$1"
  local as_sudo="false"
  if [ $# -gt 1 ]; then local "${@:2}"; fi

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  local target="$(mktemp -p "$tmp_ephemeral_dir")"
  $cmd envsubst < "$source" > "$target"
  echo "$target"
}

##############
# Downloads
##############

download() {
  # Arguments
  local url="$1"
  local target="$2"

  local force="false"
  local as_sudo="false"
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  if [ ! -s "$target" ] || [ "$force" == "true" ]; then
    echo "Downloading $url"

    # Download via curl
    $cmd curl -fL# -o "$target.tmp" "$url"

    # If the target is empty, clean up and let the caller know
    if [ -s "$target.tmp" ]; then
      $cmd mv "$target.tmp" "$target"
    else
      $cmd rm -f "$target"
      return 1
    fi
  else
    echo "Already downloaded $url"
  fi
}

##############
# Utilities
##############

stop_emulationstation() {
  killall /opt/retropie/supplementary/emulationstation/emulationstation || true
}
