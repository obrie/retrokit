#!/bin/bash

set -ex

DIR=$(dirname "$0")
APP_DIR=$(cd "$DIR/.." && pwd)
CONFIG_DIR="$CONFIG_DIR"
SETTINGS_FILE="$CONFIG_DIR/settings.json"

##############
# Set up a fresh install of RetroPie
# 
# Based on v4.7.1
##############

# Make sure emulation station isn't running
killall /opt/retropie/supplementary/emulationstation/emulationstation

##############
# Wifi
##############

# Disable wifi (assuming wired)
crudini --set /boot/config.txt '' 'dtoverlay' 'disable-wifi'

# ...or enable wifi (NOTE: Connect over 2.4ghz, not 5ghz):
# sudo raspi-config

##############
# Upgrades
##############

sudo apt update
sudo apt full-upgrade

##############
# Tools
##############

# Ini editor
sudo pip3 install crudini

# Env editor
mkdir -p ~/tools
wget https://raw.githubusercontent.com/bashup/dotenv/master/dotenv -O ~/tools/dotenv
. dotenv

# JSON reader
sudo apt install jq

# BitTorrent client
sudo apt install transmission-daemon
sudo systemctl stop transmission-daemon
if [ ! -f "/etc/transmission-daemon/settings.json.original" ]; then
  sudo cp /etc/transmission-daemon/settings.json /etc/transmission-daemon/settings.json.original
fi
sudo sh -c "\
  jq '\
    .\"rpc-whitelist-enabled\" = false |\
    .\"rpc-authentication-required\" = false |\
    .\"start-added-torrents\" = false\
  ' /etc/transmission-daemon/settings.json.original > /etc/transmission-daemon/settings.json\
"
sudo systemctl start transmission-daemon

# Internet Archive CLI
sudo wget https://archive.org/download/ia-pex/ia -O /usr/local/bin/ia
sudo chmod +x /usr/local/bin/ia
ia configure -u "jq -r '.internetarchive.username' "$SETTINGS_FILE"" -p ".internetarchive.password"

# Benchmarking
sudo apt install sysbench

# Screen
sudo apt install screen

##############
# Argon Case
##############

# Configure Argon case
curl https://download.argon40.com/argon1.sh | bash

# Fix HDMI w/ Argon case (https://forum.libreelec.tv/thread/22079-rpi4-no-hdmi-sound-using-argon-one-case/):
crudini --set /boot/config.txt '' 'hdmi_force_hotplug' '1'
crudini --set /boot/config.txt '' 'hdmi_group' '1'
crudini --set /boot/config.txt '' 'hdmi_mode' '16'
crudini --set /boot/config.txt '' 'hdmi_ignore_edid' '0xa5000080'

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

##############
# IR
##############

# Add IR support
sed '/retropie/d' -i /etc/rc_maps.cfg
cat '* rc-retropie retropie.toml' > /etc/rc_maps.cfg
cp "$CONFIG_DIR/remote.toml" /etc/rc_keymaps/retropie.toml
crudini --set /boot/config.txt '' 'dtoverlay' 'gpio-ir,gpio_pin=23,rc-map-name=rc-retropie'

# Load
sudo ir-keytable -t -w /etc/rc_keymaps/retropie.toml

# Test
sudo ir-keytable -c -p all -t

##############
# Performance
##############

# Overclock
crudini --set /boot/config.txt 'pi4' 'over_voltage' '2'
crudini --set /boot/config.txt 'pi4' 'arm_freq' '1750'

# Graphics
sudo apt install mesa-utils

##############
# Networking
##############

# SSH
sudo systemctl enable ssh
sudo systemctl start ssh

##############
# User Interface
##############

# Font Size
.env -f /etc/default/console-setup set FONTSIZE='"16x32"'

# Overscan
crudini --set /boot/config.txt '' 'disable_overscan' '1'

##############
# Audio
##############

# Turn off menu sounds
sed -r -i 's/(<string name="EnableSounds" value=")([^"]*)/\1false/' es_settings.cfg

##############
# Locale
##############

timezone=$(jq -r '.locale.timezone' "$SETTINGS_FILE")
language=$(jq -r '.locale.language' "$SETTINGS_FILE")
sudo sh -c "echo '$timezone' > /etc/timezone"
sudo dpkg-reconfigure -f noninteractive tzdata
sudo sed -i -e "s/# $language.UTF-8 UTF-8/$language.UTF-8 UTF-8/" /etc/locale.gen
sudo sh -c "echo 'LANG=\"$language.UTF-8\"' > /etc/default/locale"
sudo dpkg-reconfigure --frontend=noninteractive locales
sudo update-locale LANG=$language.UTF-8

##############
# Boot
##############

# Splash Screen
duration=$(jq -r '.splashscreen.duration' "$SETTINGS_FILE")
.env -f /opt/retropie/configs/all/splashscreen.cfg set DURATION="\"$duration\""

##############
# Scraper
# 
# Instructions: https://retropie.org.uk/docs/Scraper/#lars-muldjords-skyscraper
# Configs:
# * /opt/retropie/configs/all/skyscraper.cfg
# * /opt/retropie/configs/all/skyscraper/config.ini
##############

~/RetroPie-Setup/retropie_packages.sh skyscraper _binary_

regions=$(jq -r '.skyscraper.regions' "$SETTINGS_FILE")
username=$(jq -r '.skyscraper.username' "$SETTINGS_FILE")
password=$(jq -r '.skyscraper.password' "$SETTINGS_FILE")
crudini --set /opt/retropie/configs/all/skyscraper/config.ini 'main' 'regionPrios' "\"$regions\""
crudini --set /opt/retropie/configs/all/skyscraper/config.ini 'main' 'brackets' '"false"'
crudini --set /opt/retropie/configs/all/skyscraper/config.ini 'main' 'symlink' '"true"'
crudini --set /opt/retropie/configs/all/skyscraper/config.ini 'main' 'videos' '"true"'
crudini --set /opt/retropie/configs/all/skyscraper/config.ini 'screenscraper' 'userCreds' "\"$username:$password\""
crudini --set /opt/retropie/configs/all/skyscraper.cfg '' 'download_videos' '"1"'

##############
# Inputs
##############

cp $CONFIG_DIR/inputs.cfg ~/.emulationstation/es_input.cfg

##############
# Input Performance
##############

# Enable run-ahead
for system in arcade nes snes; do
  crudini --set /opt/retropie/configs/$system/retroarch.cfg '' 'run_ahead_enabled' '"true"'
  crudini --set /opt/retropie/configs/$system/retroarch.cfg '' 'run_ahead_frames' '"1"'
  crudini --set /opt/retropie/configs/$system/retroarch.cfg '' 'run_ahead_secondary_instance' '"true"'
done

##############
# Fix inputs
##############

sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" /opt/retropie/configs/all/skyscraper/config.ini
sed -i -r "s/(\S*)\s*=\s*(.*)/\1=\2/g" /boot/config.txt

##############
# Overlays (Bezels)
##############

wget -nc https://raw.githubusercontent.com/thebezelproject/BezelProject/master/bezelproject.sh -O /home/pi/RetroPie/retropiemenu/bezelproject.sh
chmod +x /home/pi/RetroPie/retropiemenu/bezelproject.sh
/home/pi/RetroPie/retropiemenu/bezelproject.sh

# 1. Install system pack
# 2. Install theme pack

##############
# Loading Screen
##############

crudini --set /opt/retropie/configs/all/runcommand.cfg '' 'use_art' '"1"'

##############
# Systems
##############

for system in $DIR/systems/*; do
  $system setup
  $system download
  $system scrape
done

##############
# Themes
##############

# Install themes
$(jq -r '.themes.library[] | (.name + " " + .repo)' "$SETTINGS_FILE") | while read theme; do
  sudo ~/RetroPie-Setup/retropie_packages.sh esthemes install_theme $theme
done

# Set active theme
active_theme_name=$(jq -r '.themes.active' "$SETTINGS_FILE")
sed -r -i "s/(<string name=\"ThemeSet\" value=\")([^\"]*)/\1$active_theme_name/" /home/pi/.emulationstation/es_settings.cfg

# Install launch images
launch_images_base_url=$(jq -r ".themes.library[] | select(.name == \"$active_theme_name\") | .launch_images_base_url")
for system in $DIR/system/*; do
  name=$(basename "$system")
  wget -nc "$(printf "$launch_images_base_url" "$name")" -P "/opt/retropie/configs/$name/" || true
done

##############
# Reload
##############

emulationstation

##############
# Manual
##############

# Configure Inputs (Controllers)