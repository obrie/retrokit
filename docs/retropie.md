# Arcade Machine

## Hardware

First generation machine:

* Raspberry Pi 4 4GB (https://www.canakit.com/raspberry-pi-4-4gb.html, $55)
  4GB is more than enough for what RetroPie requires

* 2.4ghz keyboard (https://www.amazon.com/gp/product/B0756XFFJZ, $21)
  2.4ghz is faster / easier than Bluetooth and this product is slim enough
  to store anywhere

* HDMI Cable (https://www.amazon.com/gp/product/B014I8SSD0, $8)
  With the Argon case, you can use regular HDMI cables

* Argon ONE V2 Raspberry Pi 4 Case (https://www.amazon.com/gp/product/B07WP8WC3V, $25)
  Provides a good case for overclocking, IR for a tv remote, and full-size
  HDMI inputs

* 8bitdo arcade stick (https://www.amazon.com/gp/product/B08GJC5WSS, $99 each)
  The only wireless arcade stick and supports 2.4ghz

* 32GB-128GB Samsung EVO+ Micro SD Card (https://www.amazon.com/gp/product/B06XFHQGB9, $20)
  Samsung EVO+ is the most common, well-rounded SD card.  Recommend buying
  direct from Samsung to avoid fake cards.

* CanaKit 3.5A USB-C Raspberry Pi 4 Power Supply (US Plug) with Noise Filter (https://www.amazon.com/gp/product/B07TYQRXTK, https://www.amazon.com/dp/B07FCMKK5X, $10)
  Provides a large amount of power to Raspberry Pi

Second generation machine:

* Intel NUC + Debian

Sources:

* https://www.tomshardware.com/best-picks/raspberry-pi-microsd-cards
* https://www.androidcentral.com/best-sd-cards-raspberry-pi-4

## Frontends

Retropie vs. Lakka vs. Recalbox vs. Batocera

* Retropie better overall experience
* Recalbox -- too simple, not enough compatible
* Lakka -- too advanced
* Batocera -- too simple

Retropie is the preferred frontend.

## Controllers

Keyboard:

* A: A
* B: B
* X: X
* Y: Y
* Start: Enter
* Select: Space
* LS: Left Ctl
* RS: Right Ctl
* LT: Left Alt
* RT: Right Alt
* Hotkey: H

8bitdo joystick:

Hotkeys: https://retropie.org.uk/docs/Controller-Configuration/

### Reset

1. Retropie Setup
2. -> Manage Packages
3. -> core
4. -> emulationstation
5. -> Configurations / Options
6. -> Clear/Reset Emulation Station input configuration
7. -> Yes
8. Reboot

### Files

Files:

* ~/.emulationstation/es_input.cfg.cfg
* ~/.emulationstation/es_settings.cfg
* /opt/retropie/configs/all/retroarch.cfg
* /opt/retropie/configs/all/retroarch-core-options.cfg
* /opt/retropie/configs/all/runcommand.cfg
* /opt/retropie/configs/all/retroarch-joypads/Microsoft\ X-Box\ 360\ pad.cfg
* /opt/retropie/configs/all/retroarch/autoconfig/Microsoft\ X-Box\ 360\ pad.cfg

## Storage

[USB Drive vs. MicroSD](https://retropie.org.uk/docs/Running-ROMs-from-a-USB-drive/):

* The various pros don't really apply for this setup
* Everything is scripted, so transferring ROMs is easy
* Using MicroSD frees up a USB port and bus speed
* Cost is somewhat similar
* Compatiblity is not an issue
* Data will be backed up and stored elsewhere 

## Configuration

### Wifi

Configure wifi

### Inputs

Configure controller

### Underscan

Disable underscan

### Locale / Timezone

* De-select en_GB
* Select en_US UTF-8 UTF-8 and set as default

, Timezone to ...

## ROMS

Prefer MAME 2003 Plus or Fast Burn Neo for Arcade, then MAME if neither of those work

### Non-merged sets

ROMs:

* https://***REMOVED***
* https://***REMOVED***
* https://***REMOVED***
* https://***REMOVED***
* https://***REMOVED***

Reference: https://retropie.org.uk/docs/Validating%2C-Rebuilding%2C-and-Filtering-ROM-Collections/

Setup:

1. Download ClrMamePro: http://mamedev.emulab.it/clrmamepro/#downloads
2. Install Wine
3. Install wine mono from https://dl.winehq.org/wine/wine-mono/6.0.0/
4. Configure wine (winecfg)
5. Install app (wine cmp4041_64.exe)
6. Follow instructions here: https://www.youtube.com/watch?v=_lssz2pAba8

Run clrmamepro:

```
cd ~/.wine/drive_c/Program\ Files/clrmamepro
wine cmpro64.exe
```

TorrentZip ROMs:

```
wget https://www.romvault.com/trrntzip/download/TrrntZip.NET106.zip
ls *.zip | parallel -j 5 wine ~/Downloads/TrrntZip.NET.exe  {}
```



## Backup

Possibly set up power:

```
import smbus
import RPi.GPIO as GPIO

# I2C
address = 0x1a    # I2C Address
command = 0xaa    # I2C Command
powerdata = '3085e010'

rev = GPIO.RPI_REVISION
if rev == 2 or rev == 3:
  bus = smbus.SMBus(1)
else:
  bus = smbus.SMBus(0)

bus.write_i2c_block_data(address, command, powerdata)
```

## TODO

* [x] Determine if we should upgrade MicroSD card
* [] Set up Arcade games
* [] Vice vs. lr-vice (set up controls properly)
* [] Get SNES controllers
* [] Update documentation
* [] Test lr-dosbox-pure with Carmageddon
* [] Scriptable process
