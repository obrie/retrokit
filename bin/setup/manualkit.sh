#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='manualkit'
setup_module_desc='manualkit install and configuration for viewing game manuals'

install_dir='/opt/retropie/supplementary/manualkit'

depends() {
  "$lib_dir/manualkit/setup.sh" depends
}

build() {
  # Copy manualkit to the retropie install path so that nothing depends
  # on retrokit being on the system
  sudo mkdir -p "$install_dir"
  sudo rsync -av --exclude '__pycache__/' --delete "$lib_dir/manualkit/" "$install_dir/"
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
  ini_merge '{config_dir}/manualkit/manualkit.cfg' '/opt/retropie/configs/all/manualkit.cfg' backup=false overwrite=true
}

# Install autostart script
__configure_autostart() {
  ln -fsnv "$install_dir/autostart" /opt/retropie/configs/all/autostart.d/manualkit
}

# Install emulationstation hooks
__configure_emulationstation() {
  __restore_emulationstation

  while read hook_path; do
    local hook=$(basename "$hook_path" .sh)
    local target_dir="$HOME/.emulationstation/scripts/$hook"
    mkdir -pv "$target_dir"
    ln -fsv "$hook_path" "$target_dir/manualkit.sh"
  done < <(ls "$install_dir/emulationstation-scripts/"*.sh)

  xmlstarlet ed --inplace -s "/inputList/inputAction" -t elem -n 'command' -v "$HOME/.emulationstation/scripts/controls-onfinish/manualkit.sh" "$HOME/.emulationstation/es_input.cfg"
}

# Install emulationstation hooks
__configure_runcommand() {
  ln -fsnv "$install_dir/runcommand" /opt/retropie/configs/all/runcommand.d/manualkit
}

restore() {
  rm -fv /opt/retropie/configs/all/manualkit.cfg
  
  __restore_emulationstation
  __restore_autostart
  __restore_runcommand
}

__restore_emulationstation() {
  rm -fv "$HOME/.emulationstation/scripts"/*/manualkit.sh
  xmlstarlet ed --inplace -d "/inputList/inputAction/command[contains(., \"manualkit\")]" "$HOME/.emulationstation/es_input.cfg"
}

__restore_autostart() {
  rm -fv /opt/retropie/configs/all/autostart.d/manualkit/
}

__restore_runcommand() {
  rm -fv /opt/retropie/configs/all/runcommand.d/manualkit/
}

remove() {
  sudo rm -rfv "$install_dir"

  # Only remove python modules uniquely used by manualkit
  sudo pip3 uninstall -y \
    psutil \
    PyMuPDF
}

setup "${@}"
