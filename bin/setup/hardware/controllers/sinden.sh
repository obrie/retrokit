#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../../common.sh"

setup_module_id='hardware/controllers/sinden'
setup_module_desc='Sinden lightgun setup and configuration'

version='1.07'
archive_name="SindenLightgunSoftwareReleaseV$version"
archive_rpi_dir="SindenLightgunLinuxSoftwareV$version/Pi-Arm/Lightgun"
retropie_module_install_dir='/opt/retropie/supplementary/sinden'

depends() {
  sudo apt install -y \
    mono-complete \
    v4l-utils \
    libsdl1.2-dev \
    libsdl-image1.2-dev \
    libjpeg-dev
}

build() {
  local current_sinden_version="$(cat /opt/retropie/supplementary/sinden/version 2>/dev/null || true)"
  if [ "$current_sinden_version" != "$version" ]; then
    sudo rm -rf "$retropie_module_install_dir"

    # Download
    download "https://www.sindenlightgun.com/software/$archive_name.zip" "$tmp_ephemeral_dir/sinden.zip"
    unzip "$tmp_ephemeral_dir/sinden.zip" "$archive_name/$archive_rpi_dir/*" -d "$tmp_ephemeral_dir/"

    # Copy drivers
    sudo mkdir -pv "$retropie_module_install_dir"
    sudo cp -Rv "$tmp_ephemeral_dir/$archive_name/$archive_rpi_dir/Player"* "$retropie_module_install_dir"
    echo "$version" | sudo tee /opt/retropie/supplementary/sinden/version

    # Clean up
    rm -rf "$tmp_ephemeral_dir/$archive_name"
    rm -f "$tmp_ephemeral_dir/sinden.zip"
  fi

  # Create ports
  mkdir -pv "$HOME/RetroPie/roms/ports/+sinden"
  cp -v "$bin_dir/controllers/sinden/Sinden"*.sh "$HOME/RetroPie/roms/ports/+sinden/"
}

configure() {
  for player_id in $(seq 1 2); do
    local target=$(__retropie_config_path_for_player $player_id)
    backup_and_restore "$target" as_sudo=true

    # Add common settings
    __configure_player "$config_dir/controllers/sinden/Player.config" "$target"

    # Add player-specific settings
    __configure_player "$config_dir/controllers/sinden/Player$player_id.config" "$target"
  done
}

__configure_player() {
  local source=$1
  local target=$2
  if [ ! -f "$source" ]; then
    return
  fi

  echo "Merging config $source to $target"
  while IFS=$'\t' read -r key value; do
    local xpath="/configuration/appSettings/add[@key=\"$key\"]"

    if xmlstarlet select -Q -t -m "$xpath" -c . "$target"; then
      # Configuration already exists -- update the existing key
      sudo xmlstarlet edit --inplace --update "$xpath/@value" -v "$value" "$target"
    else
      # Configuration doesn't exist -- add a new one
      sudo xmlstarlet edit --subnode '/configuration/appSettings' \
        -t elem -n 'add' -v '' \
        --var config '$prev' \
        -i '$config' -t attr -n key -v "$key" \
        -i '$config' -t attr -n value -v "$value" \
        "$target"
    fi
  done < <(xmlstarlet select -t -m '/configuration/appSettings/add' -v '@key' -o $'\t' -v '@value' -n "$source")
}

restore() {
  for player_id in $(seq 1 2); do
    restore_file "$(__retropie_config_path_for_player $player_id)" as_sudo=true
  done
}

__retropie_config_path_for_player() {
  local player_id=$1

  if [ "$player_id" == '1' ]; then
    echo "$retropie_module_install_dir/Player$player_id/LightgunMono.exe.config"
  else
    echo "$retropie_module_install_dir/Player$player_id/LightgunMono$player_id.exe.config"
  fi
}

remove() {
  rm -rfv  "$HOME/RetroPie/roms/ports/+sinden"
  sudo rm -rfv /opt/retropie/supplementary/sinden

  # We only remove mono as other dependencies are used by other parts of the system
  sudo apt remove -y mono-complete
}

setup "${@}"
