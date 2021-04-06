#!/bin/bash

system="$1"
dir=$(dirname "$0")
. "$dir/common.sh"

# Configurations
system_emulators_config="/opt/retropie/configs/$system/emulators.cfg"
system_config_dir="$app_dir/config/systems/$system"
system_settings_file="$system_config_dir/settings.json"

# Directories
system_tmp_dir="$app_dir/tmp/$system"
mkdir -p "$system_tmp_dir"

##############
# Settings
##############

setting() {
  jq -r "$1 | values" "$system_settings_file"
}

##############
# Emulators
##############

setup_emulators() {
  while IFS="$tab" read -r emulator build branch is_default; do
    if [ "${build:-binary}" == "binary" ]; then
      # Binary install
      sudo ~/RetroPie-Setup/retropie_packages.sh "$emulator" _binary_
    else
      # Source install
      if [ -n "$branch" ]; then
        # Set to correct branch
        local setup_file="$HOME/RetroPie-Setup/scriptmodules/libretrocores/$emulator.sh"
        backup "$setup_file"

        sed -i "s/.git master/.git $branch/g" "$setup_file"
      fi

      sudo ~/RetroPie-Setup/retropie_packages.sh "$emulator" _source_
    fi

    # Set default
    if [ "$is_default" == "true" ]; then
      crudini --set "$system_emulators_config" '' 'default' "\"$emulator\""
    fi
  done < <(setting ".emulators | to_entries[] | [.key, .value.build, .value.branch, .value.default] | @tsv")
}

##############
# Configurations
##############

# RetroArch configuration overrides
setup_retroarch_config() {
  if [ -f "$system_config_dir/retroarch.cfg" ]; then
    crudini --merge "$retropie_dir/config/retroarch.cfg" < "$system_config_dir/retroarch.cfg"
  fi
}

# RetroArch Core options overrides
setup_retroarch_core_options() {
  # Merge game-specific overrides
  while read emulator; do
    # Retroarch
    local retroarch_emulator_config_dir="$retroarch_dir/config/$emulator"
    mkdir -p "$retroarch_emulator_config_dir"

    # Core Options overides (https://retropie.org.uk/docs/RetroArch-Core-Options/)
    find "$system_config_dir/retroarch_opts" -iname "*.opt" | while read override_file; do
      local opt_name=$(basename "$override_file")
      local opt_file="$retroarch_emulator_config_dir/$opt_name"
      
      touch "$opt_file"
      crudini --merge --output="$opt_file" "$retroarch_core_options_config" < "$override_file"
    done
  done < <(setting '.emulators[]?')
}

##############
# ROMKit
##############

install_roms() {
  TMPDIR=$system_tmp_dir python3 bin/romkit/cli.py install --config $system_settings_file
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
  crudini --merge "$emulators_retropie_config" < <(
    while read -r rom_name emulator; do
      echo "$(clean_emulator_config_key "arcade_$rom_name") = \"$emulator\""
    done < <(TMPDIR=$system_tmp_dir python3 bin/romkit/cli.py list --config $system_settings_file --log-level ERROR | jq -r '[.name, .emulator] | @tsv')
  )
}

##############
# Cheats / High Scores
##############

setup_cheats() {
  local cheats_dir="$retroarch_config_dir/cheats"
  local cheats_name=$(setting '.cheats')

  # Create system-specific cheats database directory (to avoid conflicts with
  # multiple systems that have the same games and use the same emulator)
  local system_cheats_dir="$cheats_dir/$system"
  mkdir -p "$system_cheats_dir"
  crudini --set "$retropie_configs_dir/$system/retroarch.cfg" '' 'cheat_database_path' "$system_cheats_dir"

  # Link the named Retroarch cheats to the emulator in the system cheats namespace
  while IFS="$tab" read emulator emulator_proper_name; do
    local emulator_cheats_dir="$system_cheats_dir/$emulator_proper_name"

    rm -f "$emulator_cheats_dir"
    ln -fs "$cheats_dir/$cheats_name" "$emulator_cheats_dir"
  done < <(setting '.emulators | try to_entries[] | [.key, .value.proper_name] | @tsv')
}

setup_hiscores() {
  # Nothing by default
}

##############
# Themes
##############

scrape() {
  # Arguments
  local source="$1"

  # Kill emulation station
  killall /opt/retropie/supplementary/emulationstation/emulationstation || true

  # Scrape
  log "Scaping $system from $source"
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system" -s "$source" --flags onlymissing
}

scrape_sources() {
  while read -r source; do
    scrape "$source"
  done < <(setting '.scraper.sources')
}

setup_gamelist() {
  log "Building gamelist for $system"
  /opt/retropie/supplementary/skyscraper/Skyscraper -p "$system"
}

setup_bezels() {
  local name=$(setting '.themes.bezel')
  local bezelproject_bin="$HOME/RetroPie/retropiemenu/bezelproject.sh"
  
  if [ ! -d "/opt/retropie/configs/all/retroarch/overlay/GameBezels/$name" ]; then
    "$bezelproject_bin" install_bezel_packsa "$name" "thebezelproject"
    "$bezelproject_bin" install_bezel_pack "$name" "thebezelproject"
  fi
}

setup_system_theme() {
  local system_theme=$(setting '.themes.system')

  if [ -n "$system_theme" ]; then
    xmlstarlet ed -L -u "systemList/system[name=\"$system\"]/theme" -v "$system_theme" "$es_systems_config"
  fi
}

##############
# Main
##############

usage() {
  echo "usage: $0 <setup|download>"
  exit 1
}

setup() {
  # Emulator configurations
  setup_emulators
  setup_retroarch_options

  # Gameplay
  setup_cheats
  setup_hiscores

  # ROMs
  install_roms
  set_default_emulators

  # Themes
  scrape_sources
  setup_bezels
  setup_system_theme

  # Game data
  setup_gamelist
}

main() {
  if [ -f "$dir/$system.sh" ]; then
    source "$dir/$system.sh"
  fi

  "$2" "$@{2:}"
}

main "$@"
