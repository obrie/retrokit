#!/bin/bash

##############
# Directories / Files
##############

setup_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
export app_dir=$(cd "$setup_dir/.." && pwd)
export bin_dir="$app_dir/bin"
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
  local file=$1
  local backup_file="$file.rk-src"
  local as_sudo='false'
  if [ $# -gt 1 ]; then local "${@:2}"; fi

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  if [ ! -f "$backup_file" ] && [ ! -f "$backup_file.missing" ]; then
    # Use a different file to indicate that we're backing up a non-existent file
    if [ -f "$file" ]; then
      log "Backing up: $file to $backup_file"
      $cmd cp "$file" "$backup_file"
    else
      log "Backing up: $file to $backup_file.missing"
      $cmd mkdir -p "$(dirname "$backup_file")"
      $cmd touch "$backup_file.missing"
    fi
  fi
}

has_backup() {
  local file=$1
  local backup_file="$file.rk-src"

  [ -f "$backup_file" ] || [ -f "$backup_file.missing" ]
}

restore() {
  local file=$1
  local backup_file="$file.rk-src"
  local as_sudo='false'
  local restore='true'
  local delete_src='false'
  if [ $# -gt 1 ]; then local "${@:2}"; fi

  if [ "$restore" != 'false' ]; then
    if [ "$as_sudo" == 'true' ]; then
      local cmd='sudo'
    fi

    if [ -f "$backup_file" ]; then
      log "Restoring: $backup_file to $file"
      $cmd cp "$backup_file" "$file"

      if [ "$delete_src" == 'true' ]; then
        $cmd rm "$backup_file"
      fi
    elif [ -f "$backup_file.missing" ]; then
      log "Restoring: $file to non-existent"
      $cmd rm -f "$file"

      if [ "$delete_src" == 'true' ]; then
        $cmd rm "$backup_file.missing"
      fi
    else
      log "Restoring: $file (leaving as-is)"
    fi
  fi
}

backup_and_restore() {
  backup "${@}"
  restore "${@}"
}

env_merge() {
  local source=$1
  local target=$2
  local as_sudo='false'
  local restore='true'
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  if [ ! -f "$source" ]; then
    return
  fi

  backup_and_restore "$target" as_sudo="$as_sudo" restore="$restore"

  while IFS="$tab" read -r env_line; do
    if [ "$as_sudo" == 'true' ]; then
      sudo bash -c ". $tmp_dir/dotenv; .env -f \"$target\" set $env_line"
    else
      .env -f "$target" set $env_line
    fi
  done < <(cat "$(conf_prepare "$source")" | grep -Ev "^#")
}

ini_merge() {
  local source=$1
  local target=$2

  local space_around_delimiters'true'
  local as_sudo='false'
  local restore='true'
  if [ $# -gt 2 ]; then local "${@:3}"; fi
  
  if [ ! -f "$source" ]; then
    return
  fi

  backup_and_restore "$target" as_sudo="$as_sudo" restore="$restore"

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  $cmd crudini --inplace --merge "$target" < "$(conf_prepare "$source")"

  if [ "$space_around_delimiters" = "false" ]; then
    $cmd sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" "$target"
  fi
}

json_merge() {
  local source=$1
  local target=$2

  local as_sudo='false'
  local restore='true'
  if [ $# -gt 2 ]; then local "${@:3}"; fi
  
  if [ ! -f "$source" ]; then
    return
  fi

  backup_and_restore "$target" as_sudo="$as_sudo" restore="$restore"

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  local tmp_target="$(mktemp -p "$tmp_ephemeral_dir")"
  $cmd jq -s '.[0] * .[1]' "$target" "$(conf_prepare "$source")" > "$tmp_target"
  $cmd cp "$tmp_target" "$target"
}

file_cp() {
  local source=$1
  local target=$2
  local as_sudo='false'
  local restore='true'
  local envsubst='true'
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  if [ ! -f "$source" ]; then
    return
  fi

  backup "$target" as_sudo="$as_sudo"

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  if [ "$envsubst" == 'true' ]; then
    $cmd cp "$(conf_prepare "$source")" "$target"
  else
    $cmd cp "$source" "$target"
  fi
}

file_ln() {
  local source=$1
  local target=$2
  local as_sudo='false'
  local restore='true'
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  if [ ! -f "$source" ]; then
    return
  fi

  backup "$target" as_sudo="$as_sudo"

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  $cmd ln -fs "$source" "$target"
}

conf_prepare() {
  local source=$1
  local as_sudo='false'
  if [ $# -gt 1 ]; then local "${@:2}"; fi

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  local target="$(mktemp -p "$tmp_ephemeral_dir")"
  $cmd envsubst < "$source" > "$target"
  $cmd chmod --reference="$source" "$target"
  echo "$target"
}

##############
# Downloads
##############

download() {
  # Arguments
  local url=$1
  local target=$2

  local force='false'
  local as_sudo='false'
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  if [ ! -s "$target" ] || [ "$force" == "true" ]; then
    echo "Downloading $url"

    # Ensure target directory exists
    mkdir -p "$(dirname "$target")"

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
# Package install
##############

install_retropie_package() {
  local package_type=$1
  local name=$2
  local build="${3:-binary}"
  local branch=$4

  local install_dir="/opt/retropie/$package_type/$name"
  local scriptmodule="$HOME/RetroPie-Setup/scriptmodules/$package_type/$name.sh"

  # Determine whether we're updating an existing package or installing
  # a new one
  local mode
  local pkg_origin
  if [ -d "$install_dir" ]; then
    pkg_origin=$(crudini --get "/opt/retropie/$package_type/$name/retropie.pkg" '' 'pkg_origin' | tr -d '"')

    # We only update if the package is installed and the build source has remained the same
    if [ "$pkg_origin" == "$build" ]; then
      mode='_update_'
    fi
  fi

  if [ "$build" == "binary" ]; then
    sudo "$HOME/RetroPie-Setup/retropie_packages.sh" "$name" ${mode:-_binary_}
  else
    # Source install
    if [ -n "$branch" ]; then
      # Set to correct branch
      backup_and_restore "$scriptmodule"
      sed -i "s/.git master/.git $branch/g" "$scriptmodule"
    fi

    sudo __ignore_module_date=1 "$HOME/RetroPie-Setup/retropie_packages.sh" "$name" ${mode:-_source_}
  fi

  # Always ensure we run the configuration in case files were restored prior
  # to the install.  Note that we only do this when updating since we know that
  # an install will always run an update.
  # 
  # This could end up running `configure` twice if an update actually occurred.
  if [ "$mode" == '_update_' ]; then
    sudo ~/RetroPie-Setup/retropie_packages.sh "$name" configure
  fi
}

##############
# Utilities
##############

stop_emulationstation() {
  killall /opt/retropie/supplementary/emulationstation/emulationstation || true
}
