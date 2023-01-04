##############
# Download helpers
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

  if [ "$FORCE_UPDATE" == 'true' ]; then
    force='true'
  fi

  # Sudo access
  local cmd=''
  if [ "$as_sudo" == 'true' ]; then
    cmd='sudo'
  fi

  # Encode spaces for maximum compatibility
  url=${url// /%20}

  local exit_code=0
  local attempt
  for attempt in $(seq 1 $max_attempts); do
    if [ -z "$target" ]; then
      # No target provided -- print url contents to stdout
      __download_exec "$cmd" "$url" '-' auth_token="$auth_token"
      exit_code=$?
    elif [ ! -s "$target" ] || [ "$force" == "true" ]; then
      echo "Downloading $url"

      # Ensure target directory exists
      mkdir -pv "$(dirname "$target")"

      # Download and check that the target isn't empty
      local tmp_target="$(mktemp -p "$tmp_ephemeral_dir")"
      if __download_exec "$cmd" "$url" "$tmp_target" auth_token="$auth_token" && [ -s "$tmp_target" ]; then
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

__download_exec() {
  local cmd_prefix=$1
  local url=$2
  local target=$3
  local auth_token=''
  if [ $# -gt 3 ]; then local "${@:4}"; fi

  if [[ "$url" == *drive.google.com* ]]; then
    gdown --fuzzy "$url" -O "$target"
  else
    # Authorization
    local curl_opts=()
    if [ -n "$auth_token" ]; then
      curl_opts+=(-H "Authorization: token $auth_token")
    fi

    curl -fgL# "${curl_opts[@]}" -o "$target" "$url"
  fi
}

# Check whether there's a newer commit in a git repo given a particular SHA
has_newer_commit() {
  local repo_url=$1
  local current_sha=$2

  if [ -z "$current_sha" ]; then
    return 0
  fi

  if [ "$FORCE_UPDATE" != 'true' ]; then
    # Updates are disabled -- no need to check the remote
    return 1
  fi

  local latest_sha=$(git ls-remote "$repo_url" HEAD | cut -f1)
  [ "$current_sha" != "$latest_sha" ]
}