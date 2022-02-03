#!/bin/bash

set -e
[ "$DEBUG" == 'true' ] && set -x

##############
# Directories / Files
##############

setup_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
export app_dir=$(cd "$setup_dir/.." && pwd)
export bin_dir="$app_dir/bin"
export cache_dir="$app_dir/cache"
export config_dir="$app_dir/config"
export data_dir="$app_dir/data"
export tmp_dir="$app_dir/tmp"
export tmp_ephemeral_dir=$(mktemp -d -p "$tmp_dir")

# Clean up the ephemeral directory
trap 'rm -rf -- "$tmp_ephemeral_dir"' EXIT

# Optional env for secrets
if [ -f "$app_dir/.env" ]; then
  source "$app_dir/.env"
fi

# Add dotenv
if [ -f '/usr/local/bin/dotenv' ]; then
  . '/usr/local/bin/dotenv'
fi

##############
# Logging
##############

print_heading() {
  echo -e "\n= = = = = = = = = = = = = = = = = = = = =\n$1\n= = = = = = = = = = = = = = = = = = = = =\n"
}

##############
# Settings
##############

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

# Settings
export settings_file="$(conf_prepare "$app_dir/config/settings.json")"
setting() {
  jq -r "$1 | values" "$settings_file"
}

has_setupmodule() {
  [ $(setting ".setup | any(. == \"$1\")") == 'true' ]
}

##############
# Config Management
##############

backup_file() {
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
      $cmd cp -Ppv "$file" "$backup_file"
    else
      echo "Backing up: $file to $backup_file.missing"
      $cmd mkdir -p "$(dirname "$backup_file")"
      $cmd touch "$backup_file.missing"
    fi
  else
    echo "Backup for $file already exists"
  fi
}

has_backup_file() {
  local file=$1
  local backup_file="$file.rk-src"

  [ -f "$backup_file" ] || [ -f "$backup_file.missing" ]
}

restore_file() {
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
      $cmd cp -Ppv "$backup_file" "$file"

      if [ "$delete_src" == 'true' ]; then
        $cmd rm -fv "$backup_file"
      fi
    elif [ -f "$backup_file.missing" ]; then
      echo "Restoring: $file to non-existent"
      $cmd rm -fv "$file"

      if [ "$delete_src" == 'true' ]; then
        $cmd rm -fv "$backup_file.missing"
      fi
    else
      echo "Restoring: $file (leaving as-is)"
    fi
  fi
}

backup_and_restore() {
  backup_file "${@}"
  restore_file "${@}"
}

env_merge() {
  local source=$1
  local target=$2
  local as_sudo='false'
  local restore='true'
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  if [ ! -f "$source" ]; then
    echo "Skipping $source (does not exist)"
    return
  fi

  backup_and_restore "$target" as_sudo="$as_sudo" restore="$restore"

  echo "Merging env $source to $target"
  while read -r env_line; do
    if [ "$as_sudo" == 'true' ]; then
      sudo bash -c ". /usr/local/bin/dotenv; .env -f \"$target\" set $env_line"
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
    echo "Skipping $source (does not exist)"
    return
  fi

  backup_and_restore "$target" as_sudo="$as_sudo" restore="$restore"

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  echo "Merging ini $source to $target"
  $cmd crudini --merge --inplace "$target" < "$(conf_prepare "$source")"

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
    echo "Skipping $source (does not exist)"
    return
  fi

  backup_and_restore "$target" as_sudo="$as_sudo" restore="$restore"

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  echo "Merging json $source to $target"
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
    echo "Skipping $source (does not exist)"
    return
  fi

  backup_file "$target" as_sudo="$as_sudo"

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  echo "Copying file $source to $target"

  # Remove any existing file
  $cmd rm -fv "$target"

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
    echo "Skipping $source (does not exist)"
    return
  fi

  backup_file "$target" as_sudo="$as_sudo"

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  echo "Linking file $source as $target"

  # Remove any existing file
  $cmd rm -f "$target"
  
  $cmd ln -fs "$source" "$target"
}

##############
# Templates
##############

# Renders a template with the given variables to substitute.
# 
# Variables are expected to be in the form {var1}.
render_template() {
  local template=$1
  echo $(
    export "${@:2}"
    echo "$template" | sed -r 's/\{([^}]+)\}/$\1/g' | envsubst
  )
}

##############
# Downloads
##############

DOWNLOAD_MAX_ATTEMPTS=${DOWNLOAD_MAX_ATTEMPTS:-3}
DOWNLOAD_RETRY_WAIT_TIME=${DOWNLOAD_RETRY_WAIT_TIME:-30}

download() {
  # Arguments
  local url=$1
  local target=$2

  local force='false'
  local as_sudo='false'
  local max_attempts=$DOWNLOAD_MAX_ATTEMPTS
  local retry_wait_time=$DOWNLOAD_RETRY_WAIT_TIME
  local auth_token=''
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  local curl_opts=()
  if [ -n "$auth_token" ]; then
    curl_opts+=(-H "Authorization: token $auth_token")
  fi

  # Encode spaces for maximum compatibility
  url=${url// /%20}

  local exit_code=0
  for attempt in $(seq 1 $max_attempts); do
    if [ -z "$target" ]; then
      # Print to stdout
      curl -fgL# "${curl_opts[@]}" "$url"
      exit_code=$?
    elif [ ! -s "$target" ] || [ "$force" == "true" ]; then
      echo "Downloading $url"

      # Ensure target directory exists
      mkdir -pv "$(dirname "$target")"

      # Download via curl and check that the target isn't empty
      local tmp_target="$(mktemp -p "$tmp_ephemeral_dir")"
      if $cmd curl -fgL# "${curl_opts[@]}" -o "$tmp_target" "$url" && [ -s "$tmp_target" ]; then
        $cmd mv "$tmp_target" "$target"
        exit_code=0
      else
        $cmd rm -f "$target"
        exit_code=1
      fi
    else
      echo "Already downloaded $url"
    fi

    if [ $exit_code -eq 0 ]; then
      break
    elif [ $attempt -ne $max_attempts ]; then
      >&2 echo "Retrying in $retry_wait_time seconds..."
      sleep $retry_wait_time
    fi
  done

  return $exit_code
}

has_newer_commit() {
  local repo_url=$1
  local current_sha=$2

  if [ -z "$current_sha" ]; then
    return 0
  fi

  local latest_sha=$(git ls-remote "$repo_url" HEAD | cut -f1)
  [ "$current_sha" != "$latest_sha" ]
}

##############
# Package install
##############

install_retropie_package() {
  local package_type=$1
  local name=$2
  local build="${3:-binary}"

  local install_dir="/opt/retropie/$package_type/$name"

  # Determine whether we're updating an existing package or installing
  # a new one
  local mode
  local pkg_origin
  if [ -d "$install_dir" ]; then
    pkg_origin=$(crudini --get "/opt/retropie/$package_type/$name/retropie.pkg" '' 'pkg_origin' | tr -d '"')

    # If the package is already installed and the build source has remained the same,
    # then don't do anything.  Updates must be done explicitly by the user.
    if [ "$pkg_origin" == "$build" ]; then
      return 0
    fi
  fi

  if [ "$build" == 'binary' ]; then
    local __curl_opts=''
    if find "$bin_dir/scriptmodules" -name "$name.sh" | grep . >/dev/null; then
      __curl_opts='-L'
    fi

    sudo __curl_opts=$__curl_opts "$HOME/RetroPie-Setup/retropie_packages.sh" "$name" ${mode:-_binary_}
  else
    sudo "$HOME/RetroPie-Setup/retropie_packages.sh" "$name" ${mode:-_source_}
  fi
}

uninstall_retropie_package() {
  local name=$1
  sudo ~/RetroPie-Setup/retropie_packages.sh "$name" remove
}

##############
# Utilities
##############

stop_emulationstation() {
  killall /opt/retropie/supplementary/emulationstation/emulationstation || true
}
