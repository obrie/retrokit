# retrokit

retrokit provides software automation for the management of retro-gaming systems
with RetroPie / Raspberry Pi 4.

In addition to configuration management, retrokit consists of several sub-projects,
including:

* [autoport](manuals/autoport.md) - Automatic joystick (controller/mouse) selection for libretro and standalone emulators
* [devicekit](manuals/devicekit.md) - Python library for building applications based on RetroArch autoconfig controls
* [manualkit](manuals/manualkit.md) - Application for displaying game manuals from EmulationStation or during gameplay
* [metakit](manuals/metakit.md) - Python tool for managing system metadata sourced from many different websites, forums, etc.
* [powerkit](manuals/powerkit.md) - Advanced safe system/emulator shutdown tool controlled through hardware and joysticks
* [romkit](manuals/romkit.md) - Tool for listing, filtering, organizing, converting, and installing games from romsets
* [sindenkit](manuals/sindenkit.md) -Plug 'n play functionality and quality-of-life improvements for Sinden Lightguns

With support of the above sub-projects, retrokit is capable of automating the
installation, configuration, and management of:

* Hardware
  * Cases (e.g. Argon, NESPi, GPi 2), including safe reset/shutdown
  * Xbox bluetooth support + customizations
* Inputs
  * Controllers (including autoconfig for advmame, drastic, hypseus, mupen64plus, ppsspp, redream, and ir)
  * Automatic port selection based on active inputs (libretro cores, drastic, ppsspp, redream, mupen64plus, and hypseus)
  * Unified safe reset (quit) hotkeys across all emulators via joystick/keyboard
  * Sinden lightgun autoconfiguration, crosshair removal across all systems
  * IR configuration
* Media
  * Splash screens (using a new async loading process, reducing load time by 2s)
  * Overlays / Bezels (with auto-generated lightgun-compatible overlays)
  * Scraping (via skyscraper) with automated fallback queries
  * Launch images
  * Themes
* Manuals
  * In-game manuals (using a collection of ~20,000 manuals catalogued by hand)
  * System controller reference guides
  * Printable gamelist reference books
* Game Configurations
  * Cheats (pre-selected for RetroArch, MAME, NDS, etc.)
  * ROM Playlist (m3u) auto-generation for multi-disc games
  * Playstation GunCon patches (PPF)
  * Game state (import/export)
* Frontend
  * EmulationStation configuration
  * EmulationStation Collections (including auto-generated ones for input type, players, etc.)
* Emulators
  * Emulator installation
  * Retroarch configuration
  * Multi-Tap device configurations
  * MAME Hi-scores, plugins, game info, history, and artwork
  * MESS multi-system support
* System Management
  * SSH + AutoSSH for remote management
  * VNC
  * Display settings
  * Wifi
  * Overclocking
  * Localization
* Other
  * Custom Retropie modules
  * Various fixes / workarounds for many common issues

Through [romkit](manuals/romkit.md), retrokit is able to provide ROM management
capabilities, include:

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

Through [manualkit](manuals/manualkit.md), retrokit is able to provide game
manual management capabilities (across ~20,000 manuals that have been sourced
by hand for this project), including:

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
* NEC - PC Engine - TurboGrafx-16
* NEC - PC Engine CD - TurboGrafx CD
* NEC - SuperGrafx
* Nintendo - Game & Watch
* Nintendo - Game Boy
* Nintendo - Game Boy Advanced
* Nintendo - Game Boy Color
* Nintendo - Nintendo 64
* Nintendo - Nintendo DS
* Nintendo - Nintendo Entertainment System
* Nintendo - Pokemon Mini
* Nintendo - Super Nintendo Entertainment System
* Panasonic - 3DO Interactive Multiplayer
* PC - DOS
* Philips - Videopac
* Sega - 32X
* Sega - CD
* Sega - Dreamcast
* Sega - Game Gear
* Sega - Mastersystem - Mark III
* Sega - Mega CD - Sega CD
* Sega - Mega Drive - Genesis
* Sega - Saturn
* Sega - SG-1000
* SNK - Neo Geo CD
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

For all of these integrations, retrokit provides a large library of [profiles](manuals/profiles.md)
which allow you to add more functionality onto the default configuration, including:

* 8BitDo input configurations
* Preset rom filters for 512gb and 1tb hard drives
* Predefined hardware kit configurations for GPi Case 2 handhelds, Argon TV setups, and Nespi TV setups
* Sinden lightgun integrations (HD and SD)

All of this means you can set up your system from scratch to feature-complete
with less than a few hours worth of work.  Systems built with retrokit are:

* **Easy to use**: No need to worry about getting phone calls from your friends
  about how to use the system.
* **Easy to recreate**: Every aspect is automated and codified
* **Easy to extend**: Start with your base image and layer on new functionality

retrokit is built primarily for RetroPie / Raspberry Pi 4.  You must customize it
to your own needs.

**NOTE** This repository does not contain ROMs or URLs to websites that provide
ROMs.  To utilize any download functionality in retrokit, you must provide the
configurations yourself.  Please familiarize yourself with the law in your country
before attempting to download ROMs.

## Manual

To read more about the different components of retrokit, please see the documentation
in the [manual](manual/):

* [Cache](manual/cache.md)
* [Controllers](manual/controllers.md)
* [Controls](manual/controls.md)
* [Documentation](manual/docs.md)
* [Emulators](manual/emulators.md)
* [Extensions](manual/extensions.md)
* [Game State](manual/gamestate.md)
* [Hardware](manual/hardware.md)
* [Profiles](manual/profiles.md)
* [Roadmap](manual/roadmap.md)
* [Settings](manual/settings.md)
* [Systems](manual/systems.md)
* [Usage](manual/usage.md)

Sub-projects:

* [autoport](manual/autoport.md)
* [devicekit](manual/devicekit.md)
* [launchkit](manual/launchkit.md)
* [manualkit](manual/manualkit.md)
* [metakit](manual/metakit.md)
* [powerkit](manual/powerkit.md)
* [sindenkit](manual/sindenkit.md)

## Why does this exist?

When I started creating my own RetroPie system, I wanted to build it in such a way
that I could re-create the exact same setup steps each time.  As it turns out, there's
a lot involved in building out the perfect Raspberry Pi 4 system.

retrokit represents the work I did to build a configuration management system for
all of my personal builds.

## Demo

For a demo of what the end result looks like, see here.

## How to use

You can use retrokit just for its sub-projects (e.g. manualkit / romkit) or you
can use it for software automation / configuration management as well.

You will need to provide a `.env` file with the appropriate details filled out.
In order to not encourage improper use of the ROM downloader (via romkit), you
must provide the source rom set URLs yourself.

Go through the settings and setup modules and become familiar with what this does.
If you have a proper `.env` file, you can get a fully working system with very
little effort.  However, understand that this is opinionated software and you
may very well want to add your own customizations.

You can have complete control over what parts of retrokit get used via [profiles](manual/profiles.md).
I strongly recommend using profiles to customize your configuration.  That being
said, feel free to fork this repo and use your fork to update and track
all of your personal preferences.

## Quickstart

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

## My favorites

I'd be hard-pressed to list every single feature that is built into retrokit as
this project represents the culmination of years of work.  That being said, I at
least want to call out my favorite features in retrokit:

* **Manuals**.
  Where would I be if I couldn't bring up manuals for the games I'm playing?  With
  the [retrokit-manuals](https://archive.org/details/retrokit-manuals) project, I
  have access to thousands of manuals that I've personally validated and processed.
  It makes life so much easier.

* **System / Game references**.
  With so many systems, it's impossible to keep track of what each button does for
  each system.  The [reference sheets](manual/controls.md) are incredibly useful
  for reminding you how to actually use a system.

* **Emulator Safe Shutdown**.
  When mixing libretro and standalone emulators, you end up in a situation where
  exiting an emulator becomes an exercise in remembering exactly how the specific
  emulator you're using works (and we sometimes use multiple emulators for a single
  system!).  With [powerkit](manual/powerkit.md), I can forget about that altogether
  and just focus on playing games.  Phew!

* **Automatic Port Selection**.
  Between joysticks, trackballs, lightguns, and arcade sticks, I have a lot of
  different controllers I use for different games.  Making the input selection
  deterministic based on the game being loaded is a huge pain to deal with manually.
  Fortunately, [autoport](manual/autoport.md) makes that incredibly easy.  I never
  have to worry that the wrong controller is chosen by an emulator.

* **Configuration Management**.
  Yes, we can create backups of our systems.  But, do you know every single step
  you took to get your system to the state it's in from the base RetroPie install?
  Programmatically managing my system makes 2 things incredible easy: (a) if I need
  to change a configuration, I can simply re-run retrokit and everything will be
  udpated based on my new configuration and (b) I can sleep soundly knowing that if
  something catastrophic happened, I can always re-run retrokit from scratch and
  get the exact same system I had originally.

* **Input autoconfig**.
  With so many different systems and emulators installed, automatic input configuration
  is even more important.  With autoconfigs for every emulator, I can add new
  controllers to my system and never have to worry about going into a standalone
  emulator's configuration to get it working.

Honestly, there's a *ton* more functionality in retrokit that I love, but the
above are my favorites.  Honorable mentions:

* Automatic emulator selection for best performance
* Unified controller layouts across mame emulators
* Automatic installation of launch images, overlays, cheats, and mess artwork
* Advanced setup of MAME (plugins, hiscores, history, game info, etc.)
* Automatic management of collections and favorites

## Final words

retrokit has the potential to be incredibly powerful for managing your system.
Be patient, read the documentation, learn the system, but most importantly:
have fun :)

This has been a passion project of mine for years.  It's my hope that, even if
you don't use this project, perhaps there is something valuable you can take from it.
