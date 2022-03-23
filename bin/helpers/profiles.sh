##############
# Profile config helpers
##############

# Determines whether any path exists from the given template.
# 
# See each_path for more information.
any_path_exists() {
  each_path "${@}" | grep . > /dev/null
}

# Finds the first path that matches the given template.
# 
# See each_path for more information.
first_path() {
  each_path "${@}" | tail -n 1
}

# Finds all paths matching a certain template and executes the provided command
# by susbtituting {} within that template, e.g.
# 
# * each_path '{system_config_dir}/retroarch/'
# * each_path '{system_config_dir}/settings.json'
# * each_path '{system_config_dir}/settings.json' cat '{}'
each_path() {
  local path_template=$1

  # Default to just printing out the matching paths
  local command=${2:-echo '{}'}

  # Determine which directory we're dealing with
  local template_name
  if [[ "$path_template" == *{config_dir}* ]]; then
    template_name='config_dir'
    sub_dir=''
  elif [[ "$path_template" == *{system_config_dir}* ]]; then
    template_name='system_config_dir'
    sub_dir="systems/$system"
  fi

  if [ -n "$template_name" ]; then
    # Find matching paths within each profile
    while read profile; do
      # Make sure we're dealing with a valid profile
      local profile_dir="$profiles_dir/$profile"
      if [ ! -d "$profile_dir" ]; then
        >&2 echo "[WARN] Cannot find profile: $profile"
        continue
      fi

      local profile_subdir="$profile_dir/$sub_dir"
      local rendered_path=${path_template//\{$template_name\}/$profile_subdir}

      # Check that the path exists before printing it for the caller
      if [ -e "$rendered_path" ]; then
        local full_path=$(realpath "$rendered_path")
        process_path "$full_path" "${@:2}"
      fi
    done < <(echo "../config,$PROFILES" | tr ',' $'\n')
  elif [ -f "$path_template" ]; then
    # No template detected, but path exists
    process_path "${@}"
  fi
}

# Runs the provided command, substituting the template "{}" with the path that
# was matched.  If no command is provided, then the path is simply printed.
process_path() {
  if [ $# -gt 1 ]; then
    # Replace the susbstitution template ({}) with the path
    local args=()
    for arg in "${@:2}"; do
      args+=("${arg/\{\}/"$1"}")
    done

    # Run the command
    "${args[@]}"
  else
    echo "$1"
  fi
}
