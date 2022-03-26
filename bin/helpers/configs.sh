##############
# Configuration management helpers
##############

export ENABLE_RPDIST_BACKUPS=${ENABLE_RPDIST_BACKUPS:-false}

# Substitutes environment variables with a file and returns the path to the
# interpolated file
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

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
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

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
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
  if [ $# -gt 2 ]; then local "${@:3}"; fi

  if ! any_path_exists "$source"; then
    echo "Skipping $source (does not exist)"
    return
  fi

  if [ "$backup" == 'true' ]; then
    backup_and_restore "$target" as_sudo="$as_sudo" restore="$restore"
  else
    $cmd mkdir -p "$(dirname "$target")"
  fi

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  if [ "$overwrite" == 'true' ]; then
    $cmd rm -fv "$target"
  fi

  echo "Merging env $source to $target"
  while read source_path; do
    while read -r env_line; do
      $cmd dotenv -f "$target" set "$env_line"
    done < <(cat "$(conf_prepare "$source_path")" | grep -Ev "^#")
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
  if [ $# -gt 2 ]; then local "${@:3}"; fi
  
  if ! any_path_exists "$source"; then
    echo "Skipping $source (does not exist)"
    return
  fi

  if [ "$backup" == 'true' ]; then
    backup_and_restore "$target" as_sudo="$as_sudo" restore="$restore"
  else
    $cmd mkdir -p "$(dirname "$target")"
  fi

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  if [ "$overwrite" == 'true' ]; then
    $cmd rm -fv "$target"
  fi

  echo "Merging ini $source to $target"
  while read source_path; do
    $cmd crudini --merge --inplace "$target" < "$(conf_prepare "$source_path")"
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
  while read source_path; do
    if crudini --get "$source_path" "${@:2}" 2>/dev/null; then
      # Found a match -- stop
      return
    fi
  done < <(each_path "$source" | tac)
}

# Merges JSON files, backing up the target
json_merge() {
  local source=$1
  local target=$2

  local as_sudo='false'
  local overwrite='false'
  local backup='true'
  local restore='true'
  if [ $# -gt 2 ]; then local "${@:3}"; fi
  
  if ! any_path_exists "$source"; then
    echo "Skipping $source (does not exist)"
    return
  fi

  if [ "$backup" == 'true' ]; then
    backup_and_restore "$target" as_sudo="$as_sudo" restore="$restore"
  else
    $cmd mkdir -p "$(dirname "$target")"
  fi

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  if [ "$overwrite" == 'true' ]; then
    $cmd rm -fv "$target"
  fi

  echo "Merging json $source to $target"
  local staging_path="$(mktemp -p "$tmp_ephemeral_dir")"
  if [ -f "$target" ]; then
    cp "$target" "$staging_path"
  else
    echo '{}' > "$staging_path"
  fi

  local merged_path="$(mktemp -p "$tmp_ephemeral_dir")"

  while read source_path; do
    $cmd jq -s '.[0] * .[1]' "$staging_path" "$(conf_prepare "$source_path")" > "$merged_path"
    mv "$merged_path" "$staging_path"
  done < <(each_path "$source")

  $cmd mv "$staging_path" "$target"
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

  if [ "$backup" == 'true' ]; then
    backup_file "$target" as_sudo="$as_sudo"
  else
    $cmd mkdir -p "$(dirname "$target")"
  fi

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  local prioritized_source=$(first_path "$source")
  echo "Copying file $prioritized_source to $target"

  # Remove any existing file
  $cmd rm -f "$target"

  if [ "$envsubst" == 'true' ]; then
    $cmd cp "$(conf_prepare "$prioritized_source")" "$target"
  else
    $cmd cp "$prioritized_source" "$target"
  fi
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

  if [ "$as_sudo" == 'true' ]; then
    local cmd='sudo'
  fi

  local prioritized_source=$(first_path "$source")
  echo "Linking file $prioritized_source as $target"

  # Remove any existing file
  $cmd rm -f "$target"
  
  $cmd ln -fs "$prioritized_source" "$target"
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