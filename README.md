# retrokit

retrokit provides hands-off management of arcade systems using currently known best
practices as I understand them.

Specifically, it can set up:

* Cases (e.g. Argon)
* Bluetooth
* Controllers (including autoconfig for advmame, drastic, ppsspp, redream, and ir)
* IR configuration
* SSH
* VNC
* Wifi configuration
* Overclocking
* Display settings
* Localization
* Splash screens (with parallelized loading process)
* Custom Retropie modules
* Scraping (via skyscraper)
* Themes
* Retroarch configuration
* EmulationStation configuration
* Overlays / Bezels
* Cheats
* HiScores
* Launch images
* Emulator installation
* ROM Playlist (m3u) auto-generation for multi-disc games
* EmulationStation Collections management
* Various fixes / workarounds for many common issues

Additionally, it provides ROM management capabilities, including:

* Advanced filtering
* Emulator assignment
* Core options overrides
* Retroarch overrides
* Remapping overrides
* Non-merged ROM building (via split / merged / non-merged sources)
* Installation via public rom sets (using individual ROM downloads)
* Installation via public bios sets
* Simple sub-directory management based on filters

This is all supported for the following systems:

* Arcade
* Atari - 2600
* Atari - 7800
* Atari - Jaguar
* Atari - Lynx
* Coleco - ColecoVision
* Commodore - 64
* GCE - Vectrex
* Mattel - Intellivision
* NEC - PC Engine / TurboGrafx-16
* Nintendo - DS
* Nintendo - Game Boy
* Nintendo - Game Boy Advanced
* Nintendo - Game Boy Color
* Nintendo - Nintendo 64
* Nintendo - Nintendo Entertainment System
* Nintendo - Super Nintendo Entertainment System
* Panasonic - 3DO
* PC - DOS
* Philips - Videopac
* Sega - 32X
* Sega - CD
* Sega - Dreamcast
* Sega - Game Gear
* Sega - Genesis / MegaDrive
* Sega - Mastersystem
* Sega - Saturn
* Sega - SG-1000
* SNK - Neo Geo Pocket
* Sony - PlayStation
* Sony - PlayStation Portable

There are also system-specific features, including:

* Automatic joystick selection for Commodore 64 via C64 Dreams spreadsheet
* Automatic integration of eXoDOS configurations for PC games
* Automatic selection of the best emulator per-game for Arcade, Atari Jaguar, and N64
* Automatic filtering of runnable games for Sega Saturn
* Optimized settings per-game for Arcade, Atari Jaguar, and N64
* Conversion of ISO-based ROMs to CHD for Dreamcast, PCEngine, PSX, and SegaCD
* Conversion of ISO-based ROMS to CSO for PSP

All of this means you can set up your arcade machine from scratch to feature-complete
with less than a few hours worth of work.  The automated scripts could take
days to complete depending on the size of your game collection.

This is built for RetroPie / Raspberry Pi 4.  You must customize it to your
own needs.

## Demo

For a demo of what the end result looks like, see here.

## How to use

You can use this just for romkit or you can use it for retrokit *and* romkit.

You will need to provide a `.env` file with the appropriate details filled out.
In order to not encourage improper use of the ROM downloader (via romkit), you
must provide the source rom set URLs yourself.

Go through the settings and setup modules and become familiar with what this does.
If you have a proper `.env` file, you can get a fully working system with very
little effort.  However, understand that this is opinionated software.  It uses
the default settings that I prefer and is configured by default for my hardware
setup.

The default hardware setup assumes:

* Raspberry Pi 4
* Argon case
* 8bitdo SN30 Pro controllers
* 8Bitdo Arcade Stick

You can have complete control over what parts of retrokit get used via everything
in the config/ folder, particularly config/settings.json.

## Instructions

1. Flash new image
   ```
   bin/sd.sh create /path/to/device # e.g. /dev/mmcblk0
   ```
1. Expand main partition of sd card
1. Insert sd card into Pi
1. Start up Pi
1. Quit EmulationStation
1. Copy retrokit to your sd card, including .env
   ```
   cd /home/pi
   git clone https://github.com/obrie/retrokit.git
   cp /path/to/.env /home/pi/retrokit/.env
   ```
1. Update Raspbian
   ```
   bin/update.sh system
   ```
1. Reboot
   ```
   shutdown -r 0
   ```
1. Update RetroPie-Setup and its packages
   ```
   bin/update.sh retropie
   ```
1. Run retrokit
   ```
   bin/setup.sh install
   ```

To access via VNC:

* Open in VNC client: `<ip address of rpi>:5900`

## Thanks

There are so many people / resources that I've pulled over time to make
retrokit what it is.  That includes:

* [Roslof's compatibility list](https://docs.google.com/spreadsheets/d/1Rq4shU1RUSdcc7cTVWeORMD-mcO6BwXwQ7TGw8f5_zw/edit#gid=1985896929) for Arcade and Nintendo 64 emulator / configuration
* [Progretto-Snaps](https://www.progettosnaps.net/) for filtering arcade roms via categories, ratings, and languages
* [C64 Dreams](https://www.zombs-lair.com/c64-dreams) for Commodore 64 game configuration settings
* [Abdessamad Derraz](https://github.com/Abdess)
* [The Bezel Project](https://github.com/thebezelproject) for overlays
* [ehettervik](https://github.com/ehettervik) for the pixel theme
* [TMNTturtleguy](https://github.com/TMNTturtleguy) for the ComicBook theme
* [DTEAM](https://retropie.org.uk/forum/topic/27999/calling-pi-4-atari-jaguar-fans/8?_=1621951484030) for Atari Jaguar settings
* eXo for Dosbox game configuration settings
* RetroPie forums
* Reddit forums
* ...and everyone who has put so much work in over the years to help make all of this even possible

## Future work

The only future work I have planned is to automate my Sinden Lightgun setup once I
receive it.

If you want to make changes for your own specific setup, feel free to.  I'll accept
contributions for anything that will make it easier for you to customize this to your
own setup.
