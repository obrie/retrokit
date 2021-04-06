#!/bin/bash

set -ex

# Directories
dir=$(dirname "$0")
app_dir=$(cd "$dir/.." && pwd)
config_dir="$app_dir/config"
tmp_dir="$app_dir/tmp"

# App settings files
settings_file="$config_dir/settings.json"

# System files
boot_config="/boot/config.txt"
es_settings_config="$HOME/.emulationstation/es_settings.cfg"
retroarch_config="/opt/retropie/configs/all/retroarch.cfg"

usage() {
  echo "usage: $0 [command]"
  exit 1
}

backup() {
  for file in "$@"; do
    if [ ! -s "$file" ]; then
      sudo cp "$file" "$file.orig"
    fi
  done
}

prepare() {
  # Make sure emulation station isn't running
  killall /opt/retropie/supplementary/emulationstation/emulationstation || true
}

backup_common_configs() {
  backup "$boot_config" "$es_settings_config" "$retroarch_config"
}

setup_wifi() {
  # Disable wifi (assuming wired)
  crudini --set "$boot_config" '' 'dtoverlay' 'disable-wifi'

  # ...or enable wifi (NOTE: Connect over 2.4ghz, not 5ghz):
  # sudo raspi-config
}

upgrade() {
  sudo apt update
  sudo apt full-upgrade
}

install_config_tools() {
  # Ini editor
  sudo pip3 install crudini

  # Env editor
  if [ ! -s "$tmp_dir/dotenv" ]; then
    curl -fL# https://raw.githubusercontent.com/bashup/dotenv/master/dotenv -o "$tmp_dir/dotenv"
  fi
  . "$tmp_dir/dotenv"

  # JSON reader
  sudo apt install -y jq
}

install_torrent_tools() {
  local transmission_settings_file=/etc/transmission-daemon/settings.json

  # BitTorrent client
  sudo apt install -y transmission-daemon
  sudo systemctl stop transmission-daemon

  # Keep original config
  backup "$transmission_settings_file"

  # Allow access without authentication
  sudo sh -c "\
    jq '\
      .\"rpc-whitelist-enabled\" = false |\
      .\"rpc-authentication-required\" = false |\
      .\"start-added-torrents\" = false\
    ' "$transmission_settings_file" > "$transmission_settings_file"\
  "
  sudo systemctl start transmission-daemon
}

install_http_tools() {
  # Internet Archive CLI
  if [ ! -s "/usr/local/bin/ia" ]; then
    sudo curl -fL# https://archive.org/download/ia-pex/ia -o /usr/local/bin/ia
  fi
  sudo chmod +x /usr/local/bin/ia
  ia configure -u "$(jq -r '.internetarchive.username' "$settings_file")" -p "$(jq -r '.internetarchive.password' "$settings_file")"
}

install_developer_tools() {
  # Benchmarking
  sudo apt install -y sysbench

  # Screen
  sudo apt install -y screen

  # Rom Set tools
  $app_dir/bin/tools/romset.sh install

  # Archival
  sudo apt install -y zip zipmerge

  # TorrentZip
  if [ ! `command -v trrntzip` ]; then
    mkdir /tmp/trrntzip
    git clone https://github.com/hydrogen18/trrntzip.git /tmp/trrntzip
    pushd /tmp/trrntzip
    ./autogen.sh
    ./configure
    make
    sudo make install
    popd
    rm -rf /tmp/trrntzip
  fi

  # CHDMan
  sudo apt install -y mame-tools
}

setup_case() {
  # Configure Argon case
  curl https://download.argon40.com/argon1.sh | bash

  # Fix HDMI w/ Argon case (https://forum.libreelec.tv/thread/22079-rpi4-no-hdmi-sound-using-argon-one-case/):
  crudini --set "$boot_config" '' 'hdmi_force_hotplug' '1'
  crudini --set "$boot_config" '' 'hdmi_group' '1'
  crudini --set "$boot_config" '' 'hdmi_mode' '16'
  crudini --set "$boot_config" '' 'hdmi_ignore_edid' '0xa5000080'

  # Set up power button
  # python <<eof
  # import smbus
  # import RPi.GPIO as GPIO

  # # I2C
  # address = 0x1a    # I2C Address
  # command = 0xaa    # I2C Command
  # powerdata = '3085e010'

  # rev = GPIO.RPI_REVISION
  # if rev == 2 or rev == 3:
  #   bus = smbus.SMBus(1)
  # else:
  #   bus = smbus.SMBus(0)

  # bus.write_i2c_block_data(address, command, powerdata)
  # eof
}

setup_remote() {
  local rc_maps_config="/etc/rc_maps.cfg"
  local rc_keymaps_config="/etc/rc_keymaps/retropie.toml"

  backup "$rc_maps_config"

  # Add IR support
  sed -i '/retropie/d' "$rc_maps_config"
  cat '* rc-retropie retropie.toml' > "$rc_maps_config"
  cp "$config_dir/remote.toml" "$rc_keymaps_config"
  crudini --set "$boot_config" '' 'dtoverlay' 'gpio-ir,gpio_pin=23,rc-map-name=rc-retropie'

  # Load
  sudo ir-keytable -t -w "$rc_keymaps_config"
}

setup_performance_optimizations() {
  # Overclock
  crudini --set "$boot_config" 'pi4' 'over_voltage' '2'
  crudini --set "$boot_config" 'pi4' 'arm_freq' '1750'

  # Graphics
  sudo apt install -y mesa-utils
}

setup_remote_access() {
  # SSH
  sudo systemctl enable ssh
  sudo systemctl start ssh
}

setup_display() {
  # Font Size
  .env -f /etc/default/console-setup set FONTSIZE='"16x32"'

  # Overscan
  crudini --set "$boot_config" '' 'disable_overscan' '1'

  # Video player
  sed -r -i 's/(<string name="VideoOmxPlayer" value=")([^"]*)/\1true/' "$es_settings_config"

  # Popups
  crudini --set "$retroarch_config" '' 'menu_enable_widgets' '"false"'
}

setup_audio() {
  # Turn off menu sounds
  sed -r -i 's/(<string name="EnableSounds" value=")([^"]*)/\1false/' "$es_settings_config"
}

setup_screensaver() {
  # Disable
  sed -r -i 's/(<string name="ScreenSaverTime" value=")([^"]*)/\10/' "$es_settings_config"
  sed -r -i 's/(<string name="SystemSleepTime" value=")([^"]*)/\10/' "$es_settings_config"
}

setup_locale() {
  local timezone=$(jq -r '.locale.timezone' "$settings_file")
  local language=$(jq -r '.locale.language' "$settings_file")
  
  backup /etc/timezone /etc/locale.gen /etc/default/locale

  sudo sh -c "echo '$timezone' > /etc/timezone"
  sudo dpkg-reconfigure -f noninteractive tzdata
  sudo sed -i -e "s/# $language.UTF-8 UTF-8/$language.UTF-8 UTF-8/" /etc/locale.gen
  sudo sh -c "echo 'LANG=\"$language.UTF-8\"' > /etc/default/locale"
  sudo dpkg-reconfigure --frontend=noninteractive locales
  sudo update-locale LANG=$language.UTF-8
}

setup_keyboard() {
  sudo bash -c ". /home/pi/retrokit/tmp/dotenv && .env -f /etc/default/keyboard set XKBLAYOUT='\"us\"'"
}

setup_splashscreen() {
  backup /opt/retropie/configs/all/splashscreen.cfg /etc/splashscreen.list

  # Splash Screen
  local duration=$(jq -r '.splashscreen.duration' "$settings_file")
  .env -f /opt/retropie/configs/all/splashscreen.cfg set DURATION="\"$duration\""

  # Media
  if [ "$(jq -r '.splashscreen | has("url")' "$settings_file")" == "true" ]; then
    local media_file="$HOME/RetroPie/splashscreens/splash.mp4"

    if [ ! -s "$media_file" ]; then
      curl -fL# "$(jq -r '.splashscreen.url' "$settings_file")" -o "$media_file"
    fi

    echo "$media_file" > /etc/splashscreen.list
  fi
}


# Scraper
# 
# Instructions: https://retropie.org.uk/docs/Scraper/#lars-muldjords-skyscraper
# Configs:
# * /opt/retropie/configs/all/skyscraper.cfg
# * /opt/retropie/configs/all/skyscraper/config.ini
setup_scraper() {
  $HOME/RetroPie-Setup/retropie_packages.sh skyscraper _binary_

  local skyscraper_config=/opt/retropie/configs/all/skyscraper/config.ini
  local skyscraper_retropie_config=/opt/retropie/configs/all/skyscraper.cfg
  backup "$skyscraper_config" "$skyscraper_retropie_config"

  local regions=$(jq -r '.skyscraper.regions' "$settings_file")
  local username=$(jq -r '.skyscraper.username' "$settings_file")
  local password=$(jq -r '.skyscraper.password' "$settings_file")
  
  crudini --set "$skyscraper_config" 'main' 'brackets' '"false"'
  crudini --set "$skyscraper_config" 'main' 'gameListFolder' "\"$HOME/.emulationstation/gamelists\""
  crudini --set "$skyscraper_config" 'main' 'mediaFolder' "\"$HOME/.emulationstation/downloaded_media\""
  crudini --set "$skyscraper_config" 'main' 'regionPrios' "\"$regions\""
  crudini --set "$skyscraper_config" 'main' 'skipped' '"true"'
  crudini --set "$skyscraper_config" 'main' 'symlink' '"true"'
  crudini --set "$skyscraper_config" 'main' 'unattend' '"true"'
  crudini --set "$skyscraper_config" 'main' 'verbosity' '"3"'
  crudini --set "$skyscraper_config" 'main' 'videos' '"true"'
  crudini --set "$skyscraper_config" 'screenscraper' 'userCreds' "\"$username:$password\""
  crudini --set "$skyscraper_retropie_config" '' 'download_videos' '"1"'
}

setup_inputs() {
  local input_config="$HOME/.emulationstation/es_input.cfg"
  backup "$input_config"

  cp "$config_dir/inputs.cfg" "$input_config"
}

setup_vnc() {
  curl https://www.linux-projects.org/listing/uv4l_repo/lpkey.asc | sudo apt-key add -
  echo "deb http://www.linux-projects.org/listing/uv4l_repo/raspbian/stretch stretch main" | sudo tee /etc/apt/sources.list.d/uv4l.list
  sudo apt install -y uv4luv4l-server uv4l-webrtc uv4l-raspidisp uv4l-raspidisp-extras
  uv4l --auto-video_nr --driver raspidisp --server-option '--enable-webrtc=yes'
}

# Fixes ini files to follow retropie format
fix_configurations() {
  sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" /opt/retropie/configs/all/skyscraper/config.ini
  sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" "$boot_config"
}

setup_overlays() {
  local bezelproject_bin="$HOME/RetroPie/retropiemenu/bezelproject.sh"
  if [ ! -s "$bezelproject_bin" ]; then
    curl -fL# https://raw.githubusercontent.com/thebezelproject/BezelProject/master/bezelproject.sh -o "$bezelproject_bin"
  fi
  chmod +x "$bezelproject_bin"

  # Patch to allow non-interactive mode
  sed -i -r -z 's/# Welcome.*\|\| exit/if [ -z "$1" ]; then\n\0\nfi/g' "$bezelproject_bin"
  sed -i -z 's/# Main\n\nmain_menu/# Main\n\n"${1:-main_menu}" "${@:2}"/g' "$bezelproject_bin"
}

setup_menus() {
  # Build system order
  local system_default_config=/etc/emulationstation/es_systems.cfg
  local system_override_config=$HOME/.emulationstation/es_systems.cfg
  printf '<?xml version="1.0"?>\n<systemList>\n' > "$system_override_config"

  # Add primary systems used by retrokit
  while read system; do
    xmlstarlet sel -t -c "/systemList/system[name='$system']" "$system_default_config" >> "$system_override_config"
    printf '\n' >> "$system_override_config"
  done < <(jq -r '.systems[]' "$settings_file")

  # Add remaining systems
  system_conditions=$(jq -r '.systems[]' "$settings_file" | sed -e 's/.*/name="\0"/g' | sed ':a; N; $!ba; s/\n/ or /g')
  xmlstarlet sel -t -m "/systemList/system[not($system_conditions)]" -c "." -n "$system_default_config" >> "$system_override_config"
  printf '</systemList>\n' >> "$system_override_config"
}

setup_gamelists() {
  # Disable generation of the game list
  sed -r -i "s/(<string name=\"ParseGamelistOnly\" value=\")([^\"]*)/\1true/" "$es_settings_config"
}

setup_cheats() {
  # Retroarch cheats
  curl -fL# -o "$tmp_dir/cheats.zip" "http://buildbot.libretro.com/assets/frontend/cheats.zip"
  unzip -o "$tmp_dir/cheats.zip" -d "/opt/retropie/configs/all/retroarch/cheats/"
}

setup_systems() {
  for system in $dir/systems/*; do
    $system setup
  done
}

setup_runcommand() {
  ln -fs "/opt/retropie/configs/all/runcommand-onstart.sh" "$app_dir/bin/runcommand/onstart.sh"
  ln -fs "/opt/retropie/configs/all/runcommand-onend.sh" "$app_dir/bin/runcommand/onend.sh"
}

setup_themes() {
  # Install themes
  $(jq -r '.themes.library[] | (.name + " " + .repo)' "$settings_file") | xargs -I{} sudo $HOME/RetroPie-Setup/retropie_packages.sh esthemes install_theme {}

  # Set active theme
  active_theme_name=$(jq -r '.themes.active' "$settings_file")
  sed -r -i "s/(<string name=\"ThemeSet\" value=\")([^\"]*)/\1$active_theme_name/" "$es_settings_config"

  # Install launch images
  launch_theme=$(jq -r '.themes.launch_theme' "$settings_file")
  launch_images_base_url=$(jq -r ".themes.library[] | select(.name == \"$launch_theme\") | .launch_images_base_url" "$settings_file")
  for system in $dir/systems/*; do
    system_name=$(basename -s .sh "$system")
    if [ "$system_name" == "megadrive" ]; then
      system_image_name="genesis"
    else
      system_image_name="$system_name"
    fi
    
    wget -nc "$(printf "$launch_images_base_url" "$system_image_name")" -O "/opt/retropie/configs/$system_name/launching-extended.png" || true
  done
}

function reload() {
  emulationstation
}

function main() {
  prepare
  backup_common_configs
  setup_wifi
  upgrade
  install_config_tools
  install_torrent_tools
  install_http_tools
  install_developer_tools
  setup_case
  setup_remote
  setup_performance_optimizations
  setup_remote_access
  setup_display
  setup_audio
  setup_screensaver
  setup_locale
  setup_splashscreen
  setup_scraper
  setup_inputs
  setup_vnc

  fix_configurations

  setup_overlays
  setup_menus
  setup_systems
  setup_cheats
  setup_gamelists
  setup_runcommand
  setup_themes
  reload
}

if [[ $# -ne 1 ]]; then
  usage
fi

main "$@"
