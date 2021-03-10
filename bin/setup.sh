##############
# Environment
##############

# Make sure emulation station isn't running
killall emulationstation

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

##############
# Audio
##############

# Turn off menu sounds
sed -r -i 's/(<string name="EnableSounds" value=")([^"]*)/\1false/' es_settings.cfg

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

##############
# Ports
##############

sudo ~/RetroPie-Setup/retropie_packages.sh eduke32 _binary_
