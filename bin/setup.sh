#!/bin/bash

set -e

app_root=$(cd "$( dirname "$0" )/.." && pwd)
settings_file=$app_root/config/settings.json

##############
# Set up a fresh install of RetroPie
# 
# Based on v4.7.1
##############

# Make sure emulation station isn't running
killall emulationstation

##############
# Wifi
##############

# NOTE: Connect over 2.4ghz, not 5ghz
sudo raspi-config

##############
# Upgrades
##############

sudo apt update
sudo apt full-upgrade

##############
# Tools
##############

# Ini editor
sudo apt install crudini

# Env editor
mkdir -p ~/tools
wget https://raw.githubusercontent.com/bashup/dotenv/master/dotenv -O ~/tools/dotenv
. dotenv

# JSON reader
sudo apt install jq

# Benchmarking
sudo apt-get install sysbench

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
cp $app_root/config/remote.toml /etc/rc_keymaps/retropie.toml
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

# Theme
theme_name=$(jq -r '.theme.name' $settings_file)
theme_repo=$(jq -r '.theme.repo' $settings_file)
sudo ~/RetroPie-Setup/retropie_packages.sh esthemes install_theme $theme_name $theme_repo
sed -r -i 's/(<string name="ThemeSet" value=")([^"]*)/\1$theme_name/' es_settings.cfg

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

timezone=$(jq -r '.locale.timezone' $settings_file)
language=$(jq -r '.locale.language' $settings_file)
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
duration=$(jq -r '.splashscreen.duration' $settings_file)
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

crudini --set /opt/retropie/configs/all/skyscraper/config.ini '' 'regionPrios' '"us,eu,ss,uk,wor,jp"'
crudini --set /opt/retropie/configs/all/skyscraper/config.ini 'screenscraper' 'userCreds' '"***REMOVED***:***REMOVED***"'
crudini --set /opt/retropie/configs/all/skyscraper.cfg '' 'download_videos' '"1"'

##############
# Inputs
##############

cat > ~/.emulationstation/es_input.cfg <<eof
<?xml version="1.0"?>
<inputList>
  <inputAction type="onfinish">
    <command>/opt/retropie/supplementary/emulationstation/scripts/inputconfiguration.sh</command>
  </inputAction>
  <inputConfig type="keyboard" deviceName="Keyboard" deviceGUID="-1">
    <input name="pageup" type="key" id="113" value="1"/>
    <input name="up" type="key" id="1073741906" value="1"/>
    <input name="left" type="key" id="1073741904" value="1"/>
    <input name="select" type="key" id="1073742053" value="1"/>
    <input name="right" type="key" id="1073741903" value="1"/>
    <input name="pagedown" type="key" id="119" value="1"/>
    <input name="y" type="key" id="97" value="1"/>
    <input name="x" type="key" id="115" value="1"/>
    <input name="down" type="key" id="1073741905" value="1"/>
    <input name="start" type="key" id="13" value="1"/>
    <input name="b" type="key" id="122" value="1"/>
    <input name="a" type="key" id="120" value="1"/>
  </inputConfig>
  <inputConfig type="joystick" deviceName="Microsoft X-Box 360 pad" deviceGUID="030000005e0400008e02000014010000">
    <input name="pageup" type="button" id="4" value="1"/>
    <input name="up" type="hat" id="0" value="1"/>
    <input name="left" type="hat" id="0" value="8"/>
    <input name="select" type="button" id="8" value="1"/>
    <input name="right" type="hat" id="0" value="2"/>
    <input name="pagedown" type="button" id="5" value="1"/>
    <input name="y" type="button" id="3" value="1"/>
    <input name="x" type="button" id="2" value="1"/>
    <input name="down" type="hat" id="0" value="4"/>
    <input name="start" type="button" id="9" value="1"/>
    <input name="b" type="button" id="1" value="1"/>
    <input name="a" type="button" id="0" value="1"/>
  </inputConfig>
</inputList>
eof

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
# Emulators
##############

for platform in platforms/*; do
  $platform/setup.sh
done

##############
# Manual
##############

# Configure Inputs (Controllers)