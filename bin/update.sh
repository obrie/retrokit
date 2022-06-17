#!/bin/bash

##############
# Update the system
##############

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/common.sh"

usage() {
  echo "usage: $0 <command> [command_args]"
  exit 1
}

# Update system
update_system() {
  sudo apt-get update
  sudo apt-get -y dist-upgrade
}

# Update RetroPie-Setup and packages
update_retropie() {
  update_retropie_setup
  update_retropie_packages
}

# Update RetroPie-Setup
update_retropie_setup() {
  pushd "$HOME/RetroPie-Setup"
  git pull --ff-only
  popd
  sudo __nodialog=1 $HOME/RetroPie-Setup/retropie_packages.sh setup post_update
  clear
}

# Update packages.  By default, any default configuration changes made to
# emulators by RetroPie configurations will *not* be picked up.  You must
# explicitly decide to accept those by running `update_emulator_configs`.
update_retropie_packages() {
  if [ $# -eq 0 ]; then
    sudo $HOME/RetroPie-Setup/retropie_packages.sh setup update_packages
  else
    for package in "$@"; do
      sudo $HOME/RetroPie-Setup/retropie_packages.sh "$package" _update_
    done
  fi
}

# Update retrokit and profiles
update_retrokit() {
  update_retrokit_setup
  update_retrokit_profiles
}

# Update the primary retrokit git repo
update_retrokit_setup() {
  pushd "$app_dir" >/dev/null
  git pull --ff-only
  popd >/dev/null
}

# Update all third-party profiles managed in git
update_retrokit_profiles() {
  while read profile_dir; do
    if [ -d "$profile_dir/.git" ]; then
      local profile_name=$(basename "$profile_dir")

      echo "Updating retrokit profile: $profile_name"
      pushd "$profile_dir" >/dev/null
      git pull --ff-only
      popd >/dev/null
    fi
  done < <(find "$profiles_dir" -mindepth 1 -maxdepth 1 -type d)
}

# Update emulator configurations based on latest package updates
update_emulator_configs() {
  local system=$1

  if [ -n "$system" ]; then
    # Specific system updated
    "$bin_dir/setup.sh" reconfigure_packages system-emulators "$system"
  else
    # All systems updated

    # Reconfigure Retroarch on its own as its separate from systems
    if has_setupmodule 'retroarch'; then
      "$bin_dir/setup.sh" reconfigure_packages retroarch
    fi

    # Reconfigure the packages needed for each system.  system-emulators will also
    # handle reconfiguration of system-specific setup modules in retrokit.
    if has_setupmodule 'system-emulators'; then
      "$bin_dir/setup.sh" reconfigure_packages system-emulators
    fi
  fi
}

if [[ $# -eq 0 ]]; then
  usage
fi

"update_$1" "${@:2}"
