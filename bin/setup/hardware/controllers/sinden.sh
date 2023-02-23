#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../../common.sh"

setup_module_id='hardware/controllers/sinden'
setup_module_desc='Sinden lightgun setup and configuration'

version='1.08'
archive_name="SindenLightgunSoftwareReleaseV$version"
archive_rpi_dir="SindenLightgunLinuxSoftwareV$version/Pi-Arm/Lightgun"

install_dir="$retropie_dir/supplementary/sinden"

depends() {
  sudo apt-get install -y \
    at \
    mono-complete \
    v4l-utils \
    libsdl1.2-dev \
    libsdl-image1.2-dev \
    libjpeg-dev
}

build() {
  local current_sinden_version="$(cat "$install_dir/version" 2>/dev/null || true)"
  if [ "$current_sinden_version" != "$version" ]; then
    sudo rm -rf "$install_dir"

    # Download
    local sinden_tmp_dir=$(mktemp -d -p "$tmp_ephemeral_dir")
    download "https://www.sindenlightgun.com/software/$archive_name.zip" "$sinden_tmp_dir/sinden.zip"
    unzip "$sinden_tmp_dir/sinden.zip" "$archive_name/$archive_rpi_dir/*" -d "$sinden_tmp_dir/"

    # Copy drivers
    sudo mkdir -pv "$install_dir"
    sudo cp -Rv "$sinden_tmp_dir/$archive_name/$archive_rpi_dir/Player"* "$install_dir"
    echo "$version" | sudo tee "$install_dir/version"
  fi

  # Create ports
  dir_rsync '{lib_dir}/sindenkit/shortcuts' "$roms_dir/ports/+Sinden/"

  # Don't scrape ports files
  touch "$roms_dir/ports/+Sinden/.skyscraperignoretree"

  # Add management script
  file_cp '{lib_dir}/sindenkit/sinden.sh' "$install_dir/sinden.sh" as_sudo=true backup=false envsubst=false
}

configure() {
  __configure_autostart
  __configure_players
}

__configure_autostart() {
  # Write the udev rule
  file_cp '{lib_dir}/sindenkit/udev/99-sinden-lightgun.rules' /etc/udev/rules.d/99-sinden-lightgun.rules as_sudo=true backup=false

  # Reload the configuration (reboot still required)
  sudo udevadm control --reload-rules && sudo udevadm trigger
}

__configure_players() {
  local player_id
  for player_id in $(seq 1 2); do
    local target_file=$(__retropie_config_file_for_player $player_id)
    backup_and_restore "$target_file" as_sudo=true

    # Add common settings
    each_path '{config_dir}/controllers/sinden/Player.config' __configure_player '{}' "$target_file"

    # Add player-specific settings
    each_path "{config_dir}/controllers/sinden/Player$player_id.config" __configure_player '{}' "$target_file"
  done
}

__configure_player() {
  local source_file=$1
  local target_file=$2
  if [ ! -f "$source_file" ]; then
    return
  fi

  echo "Merging config $source_file to $target_file"
  while IFS=$'\t' read -r key value; do
    local xpath="/configuration/appSettings/add[@key=\"$key\"]"

    if xmlstarlet select -Q -t -m "$xpath" -c . "$target_file"; then
      # Configuration already exists -- update the existing key
      sudo xmlstarlet edit --inplace --update "$xpath/@value" -v "$value" "$target_file"
    else
      # Configuration doesn't exist -- add a new one
      sudo xmlstarlet edit --subnode '/configuration/appSettings' \
        -t elem -n 'add' -v '' \
        --var config '$prev' \
        -i '$config' -t attr -n key -v "$key" \
        -i '$config' -t attr -n value -v "$value" \
        "$target_file"
    fi
  done < <(xmlstarlet select -t -m '/configuration/appSettings/add' -v '@key' -o $'\t' -v '@value' -n "$source_file")
}

restore() {
  __restore_autostart
  __restore_players
}

__restore_autostart() {
  sudo rm -fv /etc/udev/rules.d/99-sinden-lightgun.rules
  sudo udevadm control --reload
}

__restore_players() {
  local player_id
  for player_id in $(seq 1 2); do
    restore_file "$(__retropie_config_file_for_player $player_id)" as_sudo=true
  done
}

__retropie_config_file_for_player() {
  local player_id=$1

  if [ "$player_id" == '1' ]; then
    echo "$install_dir/Player$player_id/LightgunMono.exe.config"
  else
    echo "$install_dir/Player$player_id/LightgunMono$player_id.exe.config"
  fi
}

remove() {
  rm -rfv  "$roms_dir/ports/+Sinden"
  sudo rm -rfv "$install_dir"

  # We only remove mono as other dependencies are used by other parts of the system
  sudo apt-get remove -y mono-complete
}

setup "${@}"
