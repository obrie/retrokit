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

  # Add management script / menu
  file_cp '{lib_dir}/sindenkit/sinden.sh' "$install_dir/sinden.sh" as_sudo=true backup=false envsubst=false
  install_retropie_package sindensettings
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
    backup_file "$target_file" as_sudo=true
    __restore_player $player_id

    # Resolves conflicts for Player 2
    if [ "$player_id" == '2' ]; then
      local player1_file=$(__retropie_config_file_for_player 1)
      if diff <(cat "$target_file" | grep Button | sed 's/ //g') <(cat "$player1_file" | grep Button | sed 's/ //g') >/dev/null; then
        __resolve_button_conflicts
      fi
    fi

    # Add common settings
    each_path '{config_dir}/controllers/sinden/Player.config' __configure_player '{}' "$target_file"

    # Add player-specific settings
    each_path "{config_dir}/controllers/sinden/Player$player_id.config" __configure_player '{}' "$target_file"
  done
}

# Resolves conflicts between Player 1 and Player 2 default button controls.
# 
# By default, Sinden software comes with Player 1 and Player 2 having the same
# exact buttons, which doesn't work here.
__resolve_button_conflicts() {
  local player_id=2
  local target_file=$(__retropie_config_file_for_player $player_id)

  echo "Resolving default button conflicts for $target_file"

  local defaults='
    <add key="ButtonFrontLeft" value="14" />
    <add key="ButtonRearLeft" value="15" />
    <add key="ButtonFrontRight" value="16" />
    <add key="ButtonRearRight" value="17" />
    <add key="ButtonUp" value="61" />
    <add key="ButtonDown" value="49" />
    <add key="ButtonLeft" value="47" />
    <add key="ButtonRight" value="50" />
    <add key="ButtonFrontLeftOffscreen" value="14" />
    <add key="ButtonRearLeftOffscreen" value="15" />
    <add key="ButtonFrontRightOffscreen" value="16" />
    <add key="ButtonRearRightOffscreen" value="17" />
    <add key="ButtonUpOffscreen" value="61" />
    <add key="ButtonDownOffscreen" value="49" />
    <add key="ButtonLeftOffscreen" value="47" />
    <add key="ButtonRightOffscreen" value="50" />
'

  local file_with_defaults=$(mktemp -p "$tmp_ephemeral_dir")

  # Apply defaults to avoid conflicts between Player 1 & 2
  grep -vP 'Button(Front|Rear|Up|Down|Left|Right)' "$target_file" |\
    xmlstarlet ed -s '/configuration/appSettings' -t text -n '' -v "$defaults" |\
    xmlstarlet unescape |\
    xmlstarlet fo > "$file_with_defaults"

  sudo mv "$file_with_defaults" "$target_file"
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
    __restore_player "$player_id"
  done
}

__restore_player() {
  local player_id=$1
  local config_file=$(__retropie_config_file_for_player $player_id)
  restore_partial_xml "$config_file" 'Button(Front|Rear|Up|Down|Left|Right)' parent_node='/configuration/appSettings' as_sudo=true
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
  sudo rm -rfv "$install_dir"

  # We only remove mono as other dependencies are used by other parts of the system
  sudo apt-get remove -y mono-complete
  sudo apt-get autoremove --purge -y

  uninstall_retropie_package sindensettings
}

setup "${@}"
