##############
# Environment
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
mkdir tools
wget https://raw.githubusercontent.com/bashup/dotenv/master/dotenv -O tools/dotenv
. dotenv

# Benchmarking
sudo apt-get install sysbench

##############
# Argon Case
##############

# Configure Argon case
curl https://download.argon40.com/argon1.sh | bash
argonone-config

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
crudini --set /boot/config.txt '' 'dtoverlay' 'gpio-ir,gpio_pin=23,rc-map-name=rc-tivo'

cat > /etc/rc_keymaps/tivo.toml <<EOF
[[protocols]]
name = "tivo"
protocol = "nec"
variant = "nec32"
[protocols.scancodes]
0x30859060 = "KEY_A" # A
0x30859061 = "KEY_B" # B
0x30859062 = "KEY_X" # C
0x30859063 = "KEY_Y" # D
0x3085f009 = "KEY_MEDIA"
# 0x3085e010 = "KEY_POWER2" # TV Power
0x3085e011 = "KEY_TV" # Live TV
0x3085c034 = "KEY_VIDEO_NEXT" # Input
0x3085e013 = "KEY_SPACE" # Info
0x3085a05f = "KEY_CYCLEWINDOWS"
0x0085305f = "KEY_CYCLEWINDOWS"
0x3085c036 = "KEY_EPG" # Guide
0x3085e014 = "KEY_UP" # Up
0x3085e016 = "KEY_DOWN" # Down
0x3085e017 = "KEY_LEFT" # Left
0x3085e015 = "KEY_RIGHT" # Right
0x3085e018 = "KEY_SCROLLDOWN" # Thumbs down
0x3085e019 = "KEY_SELECT" # Select
0x3085e01a = "KEY_SCROLLUP" # Thumbs up
0x3085e01c = "KEY_VOLUMEUP" # Volume Up
0x3085e01d = "KEY_VOLUMEDOWN" # Volume Down
0x3085e01b = "KEY_MUTE"#  Mute
0x3085d020 = "KEY_RECORD" # Record
0x3085e01e = "KEY_CHANNELUP" # Channel up
0x0085301f = "KEY_CHANNELDOWN" # Channel down
0x3085e01f = "KEY_CHANNELDOWN" # Channel down
0x3085d021 = "KEY_PLAY" # Play
0x3085d023 = "KEY_PAUSE" # Pause
0x3085d025 = "KEY_SLOW" # Slow
0x3085d022 = "KEY_REWIND" # Rewind
0x3085d024 = "KEY_FASTFORWARD" # Fast Forward
0x3085d026 = "KEY_PREVIOUS" # Previous / Back
0x3085d027 = "KEY_NEXT" # Next
0x3085b044 = "KEY_ZOOM" # Zoom
0x3085b048 = "KEY_STOP"
0x3085b04a = "KEY_DVD"
0x3085d028 = "KEY_NUMERIC_1" # 1
0x3085d029 = "KEY_NUMERIC_2" # 2
0x3085d02a = "KEY_NUMERIC_3" # 3
0x3085d02b = "KEY_NUMERIC_4" # 4
0x3085d02c = "KEY_NUMERIC_5" # 5
0x3085d02d = "KEY_NUMERIC_6" # 6
0x3085d02e = "KEY_NUMERIC_7" # 7
0x3085d02f = "KEY_NUMERIC_8" # 8
0x0085302f = "KEY_NUMERIC_8" # 8
0x3085c030 = "KEY_NUMERIC_9" # 9
0x3085c031 = "KEY_NUMERIC_0" # 0
0x3085c033 = "KEY_ENTER" # Enter
0x3085c032 = "KEY_ESC" # Clear
0x3085f00c = "KEY_HOME" # Tivo
EOF

# Load
sudo ir-keytable -t -w /etc/rc_keymaps/tivo.toml

# Test
sudo ir-keytable -c -p all -t

##############
# Performance
##############

# Overclock
crudini --set /boot/config.txt 'pi4' 'over_voltage' '2'
crudini --set /boot/config.txt 'pi4' 'arm_freq' '1750'

# Disable Bluetooth (https://www.raspberrypi.org/forums/viewtopic.php?f=91&t=215317#p1335189)
crudini --set /boot/config.txt 'all' 'overlay' 'disable-bt'
sudo systemctl disable hciuart.service
sudo systemctl disable bluealsa.service
sudo systemctl disable bluetooth.service

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
sudo ~/RetroPie-Setup/retropie_packages.sh esthemes install_theme pixel-metadata ehettervik
sed -r -i 's/(<string name="ThemeSet" value=")([^"]*)/\1pixel-metadata/' es_settings.cfg

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

sudo sh -c 'echo "America/New_York" > /etc/timezone'
sudo dpkg-reconfigure -f noninteractive tzdata
sudo sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sudo sh -c "echo 'LANG=\"en_US.UTF-8\"' > /etc/default/locale"
sudo dpkg-reconfigure --frontend=noninteractive locales
sudo update-locale LANG=en_US.UTF-8

##############
# Boot
##############

# Splash Screen
.env -f /opt/retropie/configs/all/splashscreen.cfg set DURATION='"36"'

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
# Ports
##############

sudo ~/RetroPie-Setup/retropie_packages.sh eduke32 _binary_

##############
# Emulator: DOS
# 
# Configs:
# * ~/.dosbox/dosbox-SVN.conf
##############

sudo ~/RetroPie-Setup/retropie_packages.sh dosbox _binary_
sudo ~/RetroPie-Setup/retropie_packages.sh lr-dosbox-pure _binary_

##############
# Emulator: Commodore 64
##############

sudo ~/RetroPie-Setup/retropie_packages.sh lr-vice _binary_

# Enable fast startup
crudini --set /opt/retropie/configs/all/retroarch-core-options.cfg '' 'vice_autoloadwarp' '"enabled"'

# Set up configurations
mkdir -p /opt/retropie/configs/all/retroarch/config/VICE\ x64/

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
# Manual
##############

# Configure Inputs (Controllers)