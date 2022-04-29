#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='manualkit'
setup_module_desc='manualkit install and configuration for viewing game manuals'

install_dir='/opt/retropie/supplementary/manualkit'

depends() {
  "$bin_dir/manualkit/setup.sh" depends
}

build() {
  # Copy manualkit to the retropie install path so that nothing depends
  # on retrokit being on the system
  sudo mkdir -p "$install_dir"
  sudo rsync -av --exclude '__pycache__/' --delete "$bin_dir/manualkit/" "$install_dir/"
}

configure() {
  __configure_manualkit

  local integration=$(setting '.manuals.integration')
  if [ "$integration" == 'emulationstation' ]; then
    __restore_runcommand
    __configure_autostart
    __configure_emulationstation
  elif [ "$integration" == 'runcommand' ]; then
    __restore_autostart
    __restore_emulationstation
    __configure_runcommand
  fi
}

__configure_manualkit() {
  ini_merge '{config_dir}/manualkit/manualkit.conf' '/opt/retropie/configs/all/manualkit.conf' backup=false overwrite=true
}

# Install autostart script
__configure_autostart() {
  mkdir -pv /opt/retropie/configs/all/autostart.d/manualkit/
  for hook in onstart onend; do
    file_cp "{bin_dir}/manualkit/autostart/$hook.sh" "/opt/retropie/configs/all/autostart.d/manualkit/$hook.sh" backup=false envsubst=false
  done
}

# Install emulationstation hooks
__configure_emulationstation() {
  for hook in game-end game-select game-start quit system-select; do
    local target_dir="$HOME/.emulationstation/scripts/$hook"
    mkdir -pv "$target_dir"
    file_cp "{config_dir}/manualkit/emulationstation-scripts/$hook.sh" "$target_dir/manualkit.sh" backup=false envsubst=false
  done
}

# Install emulationstation hooks
__configure_runcommand() {
  mkdir -pv /opt/retropie/configs/all/runcommand.d/manualkit/
  for hook in onstart onend; do
    file_cp "{bin_dir}/manualkit/runcommand/$hook.sh" "/opt/retropie/configs/all/runcommand.d/manualkit/$hook.sh" backup=false envsubst=false
  done
}

restore() {
  rm -rfv "$install_dir" /opt/retropie/configs/all/manualkit.conf
}

__restore_emulationstation() {
  rm -rfv /opt/retropie/configs/all/autostart.d/manualkit/
}

__restore_autostart() {
  rm -rfv "$HOME/.emulationstation/scripts"/*/manualkit.sh
}

__restore_runcommand() {
  rm -rfv /opt/retropie/configs/all/runcommand.d/manualkit/
}

remove() {
  # Only remove python modules uniquely used by manualkit
  sudo pip3 uninstall -y \
    psutil \
    PyMuPDF
}

setup "${@}"
