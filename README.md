# retrokit

retrokit provides software automation for the management of retro-gaming systems
with RetroPie / Raspberry Pi 4 using currently known best practices as I understand them.

Specifically, it can set up:

* Cases (e.g. Argon, NESPi, GPi 2), including safe reset/shutdown
* Controllers (including autoconfig for advmame, drastic, hypseus, mupen64plus, ppsspp, redream, and ir)
* Splash screens (using a new async loading process, reducing load time by 2s)
* Overlays / Bezels (with auto-generated lightgun-compatible overlays)
* Cheats (pre-selected for RetroArch, MAME, NDS, etc.)
* In-game manuals (using a collection of ~20,000 manuals catalogued by hand)
* System controller reference guides
* Printable gamelist reference books
* Automatic port selection based on active inputs (libretro cores, drastic, ppsspp, redream, mupen64plus, and hypseus)
* Unified safe reset (quit) hotkeys across all emulators via joystick/keyboard
* ROM Playlist (m3u) auto-generation for multi-disc games
* EmulationStation Collections (including auto-generated ones for input type, players, etc.)
* Sinden lightgun autoconfiguration
* MAME Hi-scores
* MAME artwork
* MESS multi-system support
* Multi-Tap device configurations
* Playstation GunCon patches (PPF)
* Xbox bluetooth support + customizations
* Game state (import/export)
* Scraping (via skyscraper) with automated fallback queries
* Retroarch configuration
* EmulationStation configuration
* Launch images
* Emulator installation
* SSH + AutoSSH for remote management
* IR configuration
* VNC
* Themes
* Display settings
* Wifi
* Overclocking
* Localization
* Custom Retropie modules
* Profile-based overrides
* Various fixes / workarounds for many common issues

It also provides ROM management capabilities, including:

* Advanced filtering
* Clone mappings for redump DATs
* Emulator assignment / compatibility ratings
* Core options overrides
* Retroarch overrides
* Remapping overrides
* Non-merged ROM building (via split / merged / non-merged sources)
* Installation via public rom sets (using individual ROM downloads)
* Installation via public bios sets
* Simple sub-directory management based on filters
* High-performance multi-threaded downloads
* Automatic resolution of name differences between DATs and public rom sets

Additionally, it provides Game Manual management capabilities, including:

* Installation via public manual sets
* In-game viewing and control of manuals via keyboard and joysticks
* OCR'd / Searchable PDFs

This is all supported for the following systems:

* Arcade
* Atari - 2600
* Atari - 5200
* Atari - 7800
* Atari - Jaguar
* Atari - Lynx
* Bandai - WonderSwan
* Bandai - WonderSwan Color
* Coleco - ColecoVision
* Commodore - 64
* Daphne
* Fairchild - ChannelF
* GCE - Vectrex
* Mattel - Intellivision
* NEC - PC Engine / TurboGrafx-16
* Nintendo - DS
* Nintendo - Game & Watch
* Nintendo - Game Boy
* Nintendo - Game Boy Advanced
* Nintendo - Game Boy Color
* Nintendo - Nintendo 64
* Nintendo - Nintendo Entertainment System
* Nintendo - Pokemon Mini
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
* SNK - Neo Geo Pocket Color
* Sony - PlayStation
* Sony - PlayStation Portable
* Tiger Electronics - LCD

There are also system-specific features, including:

* Automatic joystick selection for Commodore 64 via C64 Dreams project
* Automatic integration of eXoDOS configurations for PC games
* Automatic selection of the best emulator per-game for Arcade, Atari Jaguar, and N64
* Automatic filtering of runnable games for 3DO, PSP, Sega Saturn, and more
* Automatic multi-tap support for NES, SNES, MegaDrive, and Playstation
* Automatic per-game port selection based on predetermined input types
* Optimized settings per-game for Arcade, Atari Jaguar, C64, N64, and more
* Conversion of ISO-based ROMs to CHD for Dreamcast, PCEngine, PSX, and SegaCD
* Conversion of ISO-based ROMS to CSO for PSP
* DLC support for PSP (PSN) ROMs

All of this means you can set up your system from scratch to feature-complete
with less than a few hours worth of work.  The automated scripts could take
days to complete depending on the size of your game collection.

This is built for RetroPie / Raspberry Pi 4.  You must customize it to your
own needs.

**NOTE** This repository does not contain ROMs or URLs to websites that provide
ROMs.  To utilize any download functionality in retrokit, you must provide the
configurations yourself.  Please familiarize yourself with the law in your country
before attempting to download ROMs.

## Why does this exist?

When I started creating my own RetroPie system, I wanted to build it in such a way
that I could re-create the exact same setup steps each time.  As it turns out, there's
a lot involved in building out the perfect Raspberry Pi 4 system.

retrokit, romkit, metakit, manualkit, powerkit, launchkit, sindenkit, and all of
the supporting tools represent the work I did to build a configuration management
system for my personal setup.

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

You can have complete control over what parts of retrokit get used via everything
in the `config/` folder, particularly `config/settings.json`.

I strongly recommend using profiles to customize your configuration.  That being
said, feel free to fork this repo and use your fork to update and track
all of your personal preferences.

## Instructions

### Creating a base image

1. Override settings in `profiles/mykit/` to match your personal preferences and hardware requirements
1. Create a `.env` file based on env.template to provide the required configuration settings
1. Flash new image (Note this will also expand the main partition and copy retrokit
   onto the sd card):
   ```
   bin/sd.sh create /path/to/device # e.g. /dev/mmcblk0
   ```
1. Insert sd card into Pi

### Install via base image

1. Start up Pi
1. Quit EmulationStation (F4)
1. Update Raspbian
   ```
   retrokit/bin/update.sh system
   ```
1. Reboot
   ```
   sudo reboot
   ```
1. Update RetroPie-Setup and its packages
   ```
   retrokit/bin/update.sh retropie
   ```
1. Run retrokit
   ```
   retrokit/bin/setup.sh install
   ```
1. Reboot
   ```
   sudo reboot
   ```
1. Have fun!

To access via VNC:

* Open in VNC client: `<ip address of rpi>:5900`

Alternatively, you can run the retrokit setup script via the RetroPie
EmulationStation menu.

### Install via git

1. Clone repo
   ```
   cd $HOME
   git clone https://github.com/obrie/retrokit
   ```
1. Follow steps from base image install

### Install via scriptmodule

1. Download scriptmodule
   ```
   curl https://github.com/obrie/retrokit/raw/main/bin/scriptmodules/supplementary/retrokit.sh --create-dirs -o $HOME/RetroPie-Setup/ext/retrokit/supplementary/retrokit.sh
   curl https://github.com/obrie/retrokit/raw/main/bin/scriptmodules/supplementary/retrokit/icon.png --create-dirs -o $HOME/RetroPie-Setup/ext/retrokit/supplementary/retrokit/icon.png
   ```
2. Install script module via UI or:
   ```
   sudo /home/pi/RetroPie-Setup/retropie_packages.sh retrokit _source_
   ```
3. Follow steps from base image install
