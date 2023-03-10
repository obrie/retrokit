##############
# RetroPie package helpers
##############

install_retropie_package() {
  local package_type=$1
  local name=$2
  local build=${3:-auto}

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
