##############
# Profile config helpers
##############

# Determines whether any path exists from the given template.
# 
# See each_path for more information.
any_path_exists() {
  each_path "$1" | grep . > /dev/null
}

# Finds the first path that matches the given template.
# 
# See each_path for more information.
first_path() {
  local path=$(each_path "$1" | tail -n 1)
  process_path "$path" "${@:2}"
}

# Finds all paths matching a certain template and executes the provided command
# by susbtituting {} within that template, e.g.
# 
# * each_path '{system_config_dir}/retroarch/'
# * each_path '{system_config_dir}/settings.json'
# * each_path '{system_config_dir}/settings.json' cat '{}'
each_path() {
  local path_template=$1

  # Determine which directory we're dealing with
  local template_name
  if [[ "$path_template" == *{config_dir}* ]]; then
    template_name='config_dir'
    default_load_path='../config'
    sub_dir=''
  elif [[ "$path_template" == *{system_config_dir}* ]]; then
    template_name='system_config_dir'
    default_load_path='../config'
    sub_dir="systems/$system"
  elif [[ "$path_template" == *{bin_dir}* ]]; then
    template_name='bin_dir'
    default_load_path='..'
    sub_dir='bin'
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
    done < <(echo "$default_load_path,$PROFILES" | tr ',' $'\n' | grep .)
  elif [ -f "$path_template" ]; then
    # No template detected, but path exists
    process_path "${@}"
  fi
}

# Runs the provided command, substituting the template "{}" with the path that
# was matched.  If no command is provided, then the path is simply printed.
process_path() {
  local rendered_path=$1

  if [ $# -gt 1 ]; then
    # Replace the susbstitution template ({}) with the path
    local args=()
    for (( index=2; index <= "$#"; index++ )); do
      # Subsititute {} in the argument with the rendered path
      local arg=${!index}
      local rendered_arg="${arg/\{\}/"$rendered_path"}"
      args+=("$rendered_arg")

      # Stop after the first substitution is made and add the remaining arguments as-is
      if [ "$rendered_arg" != "$arg" ]; then
        ((index+=1))
        args+=("${@:$index}")
        break
      fi
    done

    # Run the command
    "${args[@]}"
  else
    echo "$rendered_path"
  fi
}
