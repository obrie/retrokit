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

  # Authorization
  local curl_opts=()
  if [ -n "$auth_token" ]; then
    curl_opts+=(-H "Authorization: token $auth_token")
  fi

  # Encode spaces for maximum compatibility
  url=${url// /%20}

  local exit_code=0
  local attempt
  for attempt in $(seq 1 $max_attempts); do
    if [ -z "$target" ]; then
      # No target provided -- print url contents to stdout
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