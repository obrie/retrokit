##############
# RetroPie package helpers
##############

install_retropie_package() {
  local package_type=$1
  local name=$2
  local build=${3:-binary}

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
      echo "$name already installed by RetroPie ($build)"
      return 0
    fi
  fi

  if [ "$build" == 'binary' ]; then
    # If this is one of retrokit's script modules, follow redirects
    local __curl_opts=''
    if find "$bin_dir/scriptmodules" -name "$name.sh" | grep . >/dev/null; then
      __curl_opts='-L'
    fi

    sudo __curl_opts=$__curl_opts "$HOME/RetroPie-Setup/retropie_packages.sh" "$name" ${mode:-_binary_}
  else
    sudo "$HOME/RetroPie-Setup/retropie_packages.sh" "$name" ${mode:-_source_}
  fi
}

configure_retropie_package() {
  local name=$1
  sudo "$HOME/RetroPie-Setup/retropie_packages.sh" "$name" configure
}

uninstall_retropie_package() {
  local name=$1
  sudo "$HOME/RetroPie-Setup/retropie_packages.sh" "$name" remove
}