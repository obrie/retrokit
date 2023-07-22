##############
# RetroPie package helpers
##############

install_retropie_package() {
  local name=$1
  local build=${2:-auto}

  # Identify package type (supplementary / emulators / etc.)
  local package_type=$(get_retropie_package_type "$name")
  if [ -z "$package_type" ]; then
    >&2 echo "Could not find scriptmodule: $name"
    return 1
  fi

  local install_dir="$retropie_dir/$package_type/$name"

  # If the package is already installed, don't do anything.  Updates must be done
  # explicitly by the user.
  if [ -d "$install_dir" ]; then
    echo "$name already installed by RetroPie ($build)"
    return 0
  fi

  # If this is one of retrokit's scriptmodules, follow redirects
  local __curl_opts=''
  if find "$ext_dir/scriptmodules" -name "$name.sh" | grep . >/dev/null; then
    __curl_opts='-L'
  fi

  sudo __curl_opts=$__curl_opts "$retropie_setup_dir/retropie_packages.sh" "$name" "_${build}_"
}

# Gets the package type for the given package.  Examples:
# * emulators
# * libretrocores
# * supplementary
get_retropie_package_type() {
  local name=$1

  local package_path=$(find "$retropie_setup_dir/scriptmodules" "$retropie_setup_dir/ext" -name "$name.sh")
  if [ -z "$package_path" ]; then
    return 1
  fi

  local package_dir=$(dirname "$package_path")
  basename "$package_dir"
}

configure_retropie_package() {
  local name=$1
  sudo "$retropie_setup_dir/retropie_packages.sh" "$name" configure
  enable_rpdist_backups
}

uninstall_retropie_package() {
  local name=$1
  sudo "$retropie_setup_dir/retropie_packages.sh" "$name" remove || true
}

list_default_retropie_packages() {
  while read scriptmodule_file; do
    grep 'rp_module_id=' "$scriptmodule_file" | cut -d'"' -f 2
  done < <(grep -lR 'rp_module_section="main"' "$retropie_setup_dir/scriptmodules")
}
