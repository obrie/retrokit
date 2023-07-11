##############
# Configuration management helpers
##############

export ENABLE_RPDIST_BACKUPS=${ENABLE_RPDIST_BACKUPS:-false}

# Substitutes environment variables with a file and returns the path to the
# interpolated file
conf_prepare() {
  local source=$1
  local as_sudo='false'
  local envsubst='false'
  if [ $# -gt 1 ]; then local "${@:2}"; fi

  local cmd=
  if [ "$as_sudo" == 'true' ]; then
    cmd='sudo'
  fi

  if [ "$envsubst" == 'true' ]; then
    local target=$(mktemp -p "$tmp_ephemeral_dir")
    $cmd envsubst < "$source" > "$target"
    $cmd chmod --reference="$source" "$target"
    echo "$target"
  else
    echo "$source"
  fi
}

# Enables retrokit to use .rp-dist as the primary backup file during file
# restore
enable_rpdist_backups() {
  ENABLE_RPDIST_BACKUPS=true
}

# Creates a backup of the given file.  If the file doesn't existing, then a
# ".missing" file is created to indicate such.
backup_file() {
  local file=$1
  local backup_file="$file.rk-src"
  local as_sudo='false'
  if [ $# -gt 1 ]; then local "${@:2}"; fi

  local cmd=
  if [ "$as_sudo" == 'true' ]; then
    cmd='sudo'
  fi

  if [ ! -f "$backup_file" ] && [ ! -f "$backup_file.missing" ]; then
    if [ -f "$file" ]; then
      # Copy to the rk-src file
      $cmd cp -Ppv "$file" "$backup_file"
    else
      # Use a different file to indicate that we're backing up a non-existent file
      # (this provides a hint that we should delete when restoring)
      echo "Backing up: $file to $backup_file.missing"
      $cmd mkdir -p "$(dirname "$backup_file")"
      $cmd touch "$backup_file.missing"
    fi
  else
    echo "Backup for $file already exists"
  fi
}

# Does a backup file exist?
has_backup_file() {
  local file=$1
  local backup_file="$file.rk-src"

  [ -f "$backup_file" ] || [ -f "$backup_file.missing" ] || { [ "$ENABLE_RPDIST_BACKUPS" == 'true' ] && [ -f "$file.rp-dist" ]; }
}

# Restores a previously backed-up file
restore_file() {
  local file=$1
  local backup_file="$file.rk-src"
  local as_sudo='false'
  local restore='true'
  local delete_src='false'
  if [ $# -gt 1 ]; then local "${@:2}"; fi

  local cmd=
  if [ "$as_sudo" == 'true' ]; then
    cmd='sudo'
  fi

  # If we just reconfigured our packages, then we want to use rp-dist as our
  # backup file instead of any existing rk-src.  The reason for this is that
  # RetroPie is going to modify *just* the rp-dist file.  Since we always want
  # to use the *original* files as our backup source, rp-dist becomes our source
  # of truth.  This gets copied over to rk-src so that we can make that the new
  # backup.
  if [ "$ENABLE_RPDIST_BACKUPS" == 'true' ] && [ -f "$file.rp-dist" ]; then
    cp -v "$file.rp-dist" "$backup_file"
  fi

  if [ -f "$backup_file" ]; then
    $cmd cp -Ppv "$backup_file" "$file"

    # Delete the backup
    if [ "$delete_src" == 'true' ]; then
      $cmd rm -fv "$backup_file"
    fi
  elif [ -f "$backup_file.missing" ]; then
    echo "Restoring: $file to non-existent"
    $cmd rm -fv "$file"

    # Delete the backup
    if [ "$delete_src" == 'true' ]; then
      $cmd rm -fv "$backup_file.missing"
    fi
  else
    echo "Restoring: $file (leaving as-is)"
  fi
}

# Backups up the given file and ensures the original has been restored
backup_and_restore() {
  local restore='true'
  if [ $# -gt 1 ]; then local "${@:2}"; fi

  backup_file "${@}"
  if [ "$restore" == 'true' ]; then
    restore_file "${@}"
  fi
}

# Merges environment files, backing up the target
env_merge() {
  local source=$1
  local target=$2
  
  local as_sudo='false'
  local overwrite='false'
  local backup='true'
  local restore='true'
  local envsubst='true'
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  if ! any_path_exists "$source"; then
    echo "Skipping $source (does not exist)"
    return
  fi

  local cmd=
  if [ "$as_sudo" == 'true' ]; then
    cmd='sudo'
  fi

  if [ "$backup" == 'true' ]; then
    backup_and_restore "$target" as_sudo="$as_sudo" restore="$restore"
  else
    $cmd mkdir -p "$(dirname "$target")"
  fi

  if [ "$overwrite" == 'true' ]; then
    $cmd rm -fv "$target"
  fi

  echo "Merging env $source to $target"
  while read source_file; do
    while read -r env_line; do
      $cmd dotenv -f "$target" set "$env_line"
    done < <(cat "$(conf_prepare "$source_file" envsubst="$envsubst")" | grep -Ev "^#" | grep .)
  done < <(each_path "$source")
}

# Merges INI files, backing up the target
ini_merge() {
  local source=$1
  local target=$2

  local space_around_delimiters='true'
  local as_sudo='false'
  local overwrite='false'
  local backup='true'
  local restore='true'
  local envsubst='true'
  if [ $# -gt 2 ]; then local "${@:3}"; fi
  
  if ! any_path_exists "$source"; then
    echo "Skipping $source (does not exist)"
    return
  fi

  local cmd=
  if [ "$as_sudo" == 'true' ]; then
    cmd='sudo'
  fi

  if [ "$backup" == 'true' ]; then
    backup_and_restore "$target" as_sudo="$as_sudo" restore="$restore"
  else
    $cmd mkdir -p "$(dirname "$target")"
  fi

  if [ "$overwrite" == 'true' ]; then
    $cmd rm -fv "$target"
  fi

  echo "Merging ini $source to $target"
  while read source_file; do
    $cmd crudini --merge --inplace "$target" < "$(conf_prepare "$source_file" envsubst="$envsubst")"
  done < <(each_path "$source")

  if [ "$space_around_delimiters" == "false" ]; then
    $cmd sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" "$target"
  fi
}

# Looks up a configuration value in an INI file
ini_get() {
  local source=$1

  # Read highest priority -> lowest priority, finding the first file
  # that has the ini configuration
  while read source_file; do
    if crudini --get "$source_file" "${@:2}" 2>/dev/null; then
      # Found a match -- stop
      return
    fi
  done < <(each_path "$source" | tac)
}

# Restores partial contents from an INI file, keeping those configurations in the
# current file that match a particular Perl-style regular expression.
restore_partial_ini() {
  local file=$1
  local regex_match=$2
  local remove_source_matches='false'
  local as_sudo='false'
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  local cmd=
  if [ "$as_sudo" == 'true' ]; then
    cmd='sudo'
  fi

  if has_backup_file "$file"; then
    if [ -f "$file" ]; then
      # Keep track of matched configurations
      local file_to_remerge=$(mktemp -p "$tmp_ephemeral_dir")
      grep -P "$regex_match|^\[" "$file" > "$file_to_remerge"

      restore_file "$file" "${@:3}"

      # Remove regex matches from the restored file
      if [ "$remove_source_matches" == 'true' ]; then
        local filtered_file=$(mktemp -p "$tmp_ephemeral_dir")
        grep -vP "$regex_match" "$file" > "$filtered_file"
        $cmd mv "$filtered_file" "$file"
      fi

      # Merge the inputs back in
      $cmd crudini --merge --inplace "$file" < "$file_to_remerge"
    else
      restore_file "$file" "${@:3}"
    fi
  fi
}

# Merges JSON files, backing up the target
json_merge() {
  local source=$1
  local target=$2

  local as_sudo='false'
  local overwrite='false'
  local backup='true'
  local restore='true'
  local envsubst='true'
  if [ $# -gt 2 ]; then local "${@:3}"; fi
  
  if ! any_path_exists "$source"; then
    echo "Skipping $source (does not exist)"
    return
  fi

  local cmd=
  if [ "$as_sudo" == 'true' ]; then
    cmd='sudo'
  fi

  if [ "$backup" == 'true' ]; then
    backup_and_restore "$target" as_sudo="$as_sudo" restore="$restore"
  else
    $cmd mkdir -p "$(dirname "$target")"
  fi

  if [ "$overwrite" == 'true' ]; then
    $cmd rm -fv "$target"
  fi

  echo "Merging json $source to $target"
  local staging_file=$(mktemp -p "$tmp_ephemeral_dir")
  if [ -s "$target" ]; then
    cp "$target" "$staging_file"
  else
    echo '{}' > "$staging_file"
  fi

  local merged_file=$(mktemp -p "$tmp_ephemeral_dir")

  while read source_file; do
    if [ -s "$source_file" ]; then
      $cmd jq -s '.[0] * .[1]' "$staging_file" "$(conf_prepare "$source_file" envsubst="$envsubst")" > "$merged_file"
      mv "$merged_file" "$staging_file"
    fi
  done < <(each_path "$source")

  $cmd mv "$staging_file" "$target"
}

# Edits in-place one or more keys on the given JSON file
json_edit() {
  local target=$1
  shift
  local jq_commands=''
  local jq_args=()

  # Determine if the user is editing raw values or encoded json
  local arg_type
  if [ "$jq_data_type" == 'json' ]; then
    arg_type=argjson
  else
    arg_type=arg
  fi

  local index=0
  while true; do
    local key=$1
    if [ -n "$key" ]; then
      # Multiple commands need to be delimited
      if [ -n "$jq_commands" ]; then
        jq_commands="$jq_commands |"
      fi

      jq_commands="$jq_commands$key = \$value$index"
      jq_args+=(--$arg_type "value$index" "$2")
      ((index=index+1))
      shift 2
    else
      # No more keys found -- stop
      break
    fi
  done

  # jq doesn't support in-place writes, so first write to a staging file before
  # we overwrite
  local staging_file=$(mktemp -p "$tmp_ephemeral_dir")
  jq "${jq_args[@]}" "$jq_commands" "$target" > "$staging_file"
  mv "$staging_file" "$target"
}

# Restores partial contents from an XML file, keeping those configurations in the
# current file that match a particular Perl-style regular expression.
restore_partial_xml() {
  local file=$1
  local regex_match=$2
  local as_sudo='false'
  local parent_node='/*'
  local remove_source_matches='true'
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  local cmd=
  if [ "$as_sudo" == 'true' ]; then
    cmd='sudo'
  fi

  if has_backup_file "$file"; then
    if [ -f "$file" ]; then
      # Keep track of matched configurations
      local file_to_remerge=$(mktemp -p "$tmp_ephemeral_dir")
      local content_to_remerge=$(grep -P "$regex_match" "$file")

      restore_file "$file" "${@:3}"

      # Remove regex matches from the restored file
      if [ "$remove_source_matches" == 'true' ]; then
        local filtered_file=$(mktemp -p "$tmp_ephemeral_dir")
        grep -vP "$regex_match" "$file" > "$filtered_file"
        $cmd mv "$filtered_file" "$file"
      fi

      cat "$file" |\
        xmlstarlet ed -s '/configuration/appSettings' -t text -n '' -v "$content_to_remerge" |\
        xmlstarlet unescape |\
        xmlstarlet fo > "$file_to_remerge"

      $cmd mv "$file_to_remerge" "$file"
    else
      restore_file "$file" as_sudo=true delete_src=true
    fi
  fi
}

# Copies a file, backing up the target and substituting environment variables
# in the source file
file_cp() {
  local source=$1
  local target=$2

  local as_sudo='false'
  local backup='true'
  local restore='true'
  local envsubst='true'
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  if ! any_path_exists "$source"; then
    echo "Skipping $source (does not exist)"
    return
  fi

  local cmd=
  if [ "$as_sudo" == 'true' ]; then
    cmd='sudo'
  fi

  if [ "$backup" == 'true' ]; then
    backup_file "$target" as_sudo="$as_sudo"
  else
    $cmd mkdir -p "$(dirname "$target")"
  fi

  local prioritized_source=$(first_path "$source")
  echo "Copying file $prioritized_source to $target"

  # Remove any existing file
  $cmd rm -f "$target"

  $cmd cp "$(conf_prepare "$prioritized_source" envsubst="$envsubst")" "$target"
}

# Copies a file, backing up the target
file_ln() {
  local source=$1
  local target=$2

  local as_sudo='false'
  local backup='true'
  local restore='true'
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  if ! any_path_exists "$source"; then
    echo "Skipping $source (does not exist)"
    return
  fi

  if [ "$backup" == 'true' ]; then
    backup_file "$target" as_sudo="$as_sudo"
  fi

  local prioritized_source=$(first_path "$source")
  ln_if_different "$prioritized_source" "$target" as_sudo="$as_sudo"
}

# Symlinks to the given target if, and only if, the existing link is *different
# than the target (to avoid unnecessary filesystem modifications)
ln_if_different() {
  local target=$1
  local link_name=$2

  local as_sudo='false'
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  local cmd=
  if [ "$as_sudo" == 'true' ]; then
    cmd='sudo'
  fi

  # Replace the symlink if it's changed
  if [ "$(readlink "$link_name")" != "$target" ]; then
    echo "Linking file $target as $link_name"
    $cmd rm -f "$link_name"
    $cmd ln -fs "$target" "$link_name"
  else
    echo "Skipping $target (already symlinked as $link_name)"
  fi
}

# Rsyncs a directory to the given target.
dir_rsync() {
  local source=$1
  local target=$2

  local as_sudo='false'
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  local cmd=
  if [ "$as_sudo" == 'true' ]; then
    cmd='sudo'
  fi

  # First sync all the profiles together to a single directory
  local reference_dir=$(mktemp -d -p "$tmp_ephemeral_dir")
  while read source_dir; do
    rsync -qavzR --exclude '__pycache__/' "$source_dir/./" "$reference_dir"
  done < <(each_path "$source")

  # Run a final single rsync to the destination
  $cmd mkdir -pv "$target"
  $cmd rsync -avzR --delete "$reference_dir/./" "$target"
}

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