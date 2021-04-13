#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

system="$1"

# Platform configurations
retropie_system_config_dir="/opt/retropie/configs/$system"
retroarch_config_dir="/opt/retropie/configs/all/retroarch"

# Retrokit configurations
system_config_dir="$app_dir/config/systems/$system"
system_settings_file="$system_config_dir/settings.json"

# Directories
system_tmp_dir="$app_dir/tmp/$system"
mkdir -p "$system_tmp_dir"

##############
# Settings
##############

system_setting() {
  jq -r "$1 | values" "$system_settings_file"
}

##############
# Emulators
##############

install_emulators() {
  while IFS="$tab" read -r emulator build branch is_default; do
    if [ "$build" == "binary" ]; then
      # Always re-install
      sudo ~/RetroPie-Setup/retropie_packages.sh "$emulator" _binary_
    else
      # Source install
      if [ -n "$branch" ]; then
        # Set to correct branch
        local setup_file="$HOME/RetroPie-Setup/scriptmodules/libretrocores/$emulator.sh"
        backup_and_restore "$setup_file"

        sed -i "s/.git master/.git $branch/g" "$setup_file"
      fi

      # Only rebuild from source if either it's a new install or we're building
      # from master
      if [ ! -d "/opt/retropie/libretrocores/$emulator" ] || [ "$branch" == "master" ]; then
        sudo ~/RetroPie-Setup/retropie_packages.sh "$emulator" _source_
      fi
    fi

    # Set default
    if [ "$is_default" == "true" ]; then
      crudini --set "$retropie_system_config_dir/emulators.cfg" '' 'default' "\"$emulator\""
    fi
  done < <(system_setting '.emulators | to_entries[] | [.key, .value.build // "binary", .value.branch // "master", .value.default // false] | @tsv')
}

# Install BIOS files required by emulators
install_bios() {
  local bios_dir=$(system_setting '.bios.dir')
  local base_url=$(system_setting '.bios.url')

  while IFS="$tab" read -r bios_name bios_url_template; do
    local bios_url="${bios_url_template/\{url\}/$base_url}"
    download "$bios_url" "$bios_dir/$bios_name"
  done < <(system_setting 'select(.bios) | .bios.files | to_entries[] | [.key, .value] | @tsv')
}

##############
# Configurations
##############

# RetroArch configuration overrides
install_retroarch_config() {
  if [ -f "$system_config_dir/retroarch.cfg" ]; then
    ini_merge "$system_config_dir/retroarch.cfg" "$retropie_system_config_dir/retroarch.cfg"
  fi
}

# RetroArch Core options overrides
install_retroarch_core_options() {
  # System overrides
  if [ -f "$system_config_dir/retroarch-core-options.cfg" ]; then
    ini_merge "$system_config_dir/retroarch-core-options.cfg" '/opt/retropie/configs/all/retroarch-core-options.cfg' restore=false
  fi

  # Game-specific overrides
  if [ -d "$system_config_dir/retroarch_opts" ]; then
    while read emulator; do
      # Retroarch
      local retroarch_emulator_config_dir="$retroarch_config_dir/config/$emulator"
      mkdir -p "$retroarch_emulator_config_dir"

      # Core Options overides (https://retropie.org.uk/docs/RetroArch-Core-Options/)
      find "$system_config_dir/retroarch_opts" -iname "*.opt" | while read override_file; do
        local opt_name=$(basename "$override_file")
        local opt_file="$retroarch_emulator_config_dir/$opt_name"
        
        touch "$opt_file"
        crudini --merge --output="$opt_file" '/opt/retropie/configs/all/retroarch-core-options.cfg' < "$override_file"
      done
    done < <(system_setting '.emulators | to_entries[] | [.key] | @tsv')
  fi
}

##############
# ROMKit
##############

romkit_cli() {
  TMPDIR="$system_tmp_dir" python3 bin/romkit/cli.py ${@} --config "$system_settings_file"
}

install_roms() {
  $(romkit_cli) install
}

# Clean the configuration key used for defining ROM-specific emulator options
# 
# Implementation pulled from retropie
clean_emulator_config_key() {
  local name="$1"
  name="${name//\//_}"
  name="${name//[^a-zA-Z0-9_\-]/}"
  echo "$name"
}

set_default_emulators() {
  log "--- Setting default emulators ---"

  # Merge emulator configurations
  # 
  # This is done in one batch because it's a bit slow otherwise
  crudini --merge '/opt/retropie/configs/all/emulators.cfg' < <(
    while read -r rom_name emulator; do
      echo "$(clean_emulator_config_key "arcade_$rom_name") = \"$emulator\""
    done < <($(romkit_cli) list --log-level ERROR | jq -r '[.name, .emulator] | @tsv')
  )
}

##############
# Cheats / High Scores
##############

install_cheats() {
  local cheats_dir="$retroarch_config_dir/cheats"
  local cheats_name=$(system_setting '.cheats')

  # Create system-specific cheats database directory (to avoid conflicts with
  # multiple systems that have the same games and use the same emulator)
  local system_cheats_dir="$cheats_dir/$system"
  mkdir -p "$system_cheats_dir"

  # TODO: Move to the other files to avoid modifications from multiple places
  backup "$retropie_system_config_dir/retroarch.cfg"
  crudini --set "$retropie_system_config_dir/retroarch.cfg" '' 'cheat_database_path' "$system_cheats_dir"

  # Link the named Retroarch cheats to the emulator in the system cheats namespace
  while IFS="$tab" read emulator emulator_proper_name; do
    local emulator_cheats_dir="$system_cheats_dir/$emulator_proper_name"

    rm -f "$emulator_cheats_dir"
    ln -fs "$cheats_dir/$cheats_name" "$emulator_cheats_dir"
  done < <(system_setting '.emulators | try to_entries[] | [.key, .value.proper_name] | @tsv')
}

install_hiscores() {
  # Nothing by default
  echo 'No hiscore files to install'
}

##############
# Scraping
##############

scrape() {
  local source="$1"

  stop_emulationstation

  log "Scaping $system from $source"
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" -s "$source" --flags onlymissing
}

scrape_sources() {
  while read -r source; do
    scrape "$source"
  done < <(system_setting '.scraper.sources')
}

build_gamelist() {
  log "Building gamelist for $system"
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system"
}

##############
# Themes
##############

install_launch_image() {
  launch_theme=$(setting '.themes.launch_theme')
  launch_images_base_url=$(setting ".themes.library[] | select(.name == \"$launch_theme\") | .launch_images_base_url")

  local system_image_name=$system
  if [ "$system_image_name" == "megadrive" ]; then
    system_image_name="genesis"
  fi
  
  download "$(printf "$launch_images_base_url" "$system_image_name")" "$retropie_system_config_dir/launching-extended.png"
}

install_bezels() {
  local name=$(system_setting '.themes.bezel')
  local bezelproject_bin="$HOME/RetroPie/retropiemenu/bezelproject.sh"
  
  if [ ! -d "$retroarch_config_dir/overlay/GameBezels/$name" ]; then
    "$bezelproject_bin" install_bezel_packsa "$name" "thebezelproject"
    "$bezelproject_bin" install_bezel_pack "$name" "thebezelproject"
  fi
}

setup_system_theme() {
  local system_theme=$(system_setting '.themes.system')

  if [ -n "$system_theme" ]; then
    xmlstarlet ed -L -u "systemList/system[name=\"$system\"]/theme" -v "$system_theme" "$HOME/.emulationstation/es_systems.cfg"
  fi
}

##############
# Main
##############

usage() {
  echo "usage: $0 <setup|download>"
  exit 1
}

install() {
  # Emulator configurations
  install_emulators
  install_bios
  install_retroarch_config
  install_retroarch_options

  # Gameplay
  install_cheats
  install_hiscores

  # Themes
  install_bezels
  install_launch_image
  setup_system_theme

  # ROMs
  install_roms
  set_default_emulators

  # Scraping
  scrape_sources
  build_gamelist
}

uninstall() {
  restore '/opt/retropie/configs/all/retroarch-core-options.cfg'
}

# Add system-specific overrides
if [ -f "$dir/$system.sh" ]; then
  source "$dir/$system.sh"
fi

"${@:2}"
