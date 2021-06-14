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
* Splash screens (async loading process, reduces load time by 2s)
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
* Lightgun collections
* Lightgun-compatible overlay auto-generation
* Sinden lightgun controller configuration
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

**NOTE** This repository does not contain ROMs or URLs to websites that provide
ROMs.  To utilize any download functionality in retrokit, you must provide the
configurations yourself.  Please familiarize yourself with the law in your country
before attempting to download ROMs.

## Why does this exist?

When I started creating my own RetroPie system, I wanted to build it in such a way
that I could re-create the exact same setup steps each time.  As it turns out, there's
a lot involved in building out the perfect Raspberry Pi 4 system.

retrokit (and romkit) represent the work I did to build a configuration management
system for my arcade.

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

Note that, by default, `ROMKIT_DEMO` is enabled, meaning that only a single game
will be installed for each system / emulator.  To disable this and install all
games based on the filters defined for each system, set this to `ROMKIT_DEMO=false`
in your `.env` file.

The default hardware setup assumes:

* Raspberry Pi 4
* Argon case
* 8bitdo SN30 Pro controllers
* 8Bitdo Arcade Stick
* 128GB or more storage capacity

You can have complete control over what parts of retrokit get used via everything
in the config/ folder, particularly config/settings.json.

I strongly recommend forking this repo and using your fork to update and track
all of your personal preferences.

## Instructions

1. Update config/ in retrokit to match your personal preferences and hardware requirements
1. Create a `.env` file based on env.template to provide the required configuration settings
1. Flash new image (Note this will also expand the main partition and copy retrokit
   onto the sd card):
   ```
   bin/sd.sh create /path/to/device # e.g. /dev/mmcblk0
   ```
1. Insert sd card into Pi
1. Start up Pi
1. Quit EmulationStation (F4)
1. Update Raspbian
   ```
   retrokit/bin/update.sh system
   ```
1. Reboot
   ```
   sudo shutdown -r 0
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
   sudo shutdown -r 0
   ```
1. Have fun!

To access via VNC:

* Open in VNC client: `<ip address of rpi>:5900`

## Usage

setup:

```
bin/setup.sh <action> <module> <args>

# Install all setup modules
bin/setup.sh install

# Install specific setup module
bin/setup.sh install splashscreen

# Install all system-specific setup modules for all systems
bin/setup.sh install system

# Install all system-specific setup modules for single system
bin/setup.sh install system n64

# Install all rom-specific setup modules for single system
bin/setup.sh install system-roms n64

# Install specific rom setup module for all systems
bin/setup.sh install system-roms-download

# Uninstall all setup modules
bin/setup.sh uninstall system

# Uninstall specific setup module
bin/setup.sh uninstall splashscreen

# Run specific function in a setup module
bin/setup.sh install_config system-retroarch n64(

# Add (very) verbose output
DEBUG=true bin/setup.sh install splashscreen
```

romkit:

```
bin/romkit.sh <action> <system> <options>

# List filtered ROMs for all systems
bin/romkit.sh list

# List filtered ROMs for specific system
bin/romkit.sh list n64

# Set verbose mode
bin/romkit.sh list n64 --log-level DEBUG

# Download/Install ROMs
bin/romkit.sh install <system>

# Re-build the ROM folder structure
bin/romkit.sh organize <system>

# Print which ROM files are no longer needed according to system settings
bin/romkit.sh vacuum <system>
```

update:

```
# Update RetroPie-Setup, RetroPie packages, and the OS
bin/update.sh

# Update RetroPie-Setup and its packages
bin/update.sh retropie

# Update just RetroPie-Setup
bin/update.sh retropie_setup

# Update just RetroPie packages
bin/update.sh packages

# Update just the OS
bin/update.sh system
```

cache:

```
# Delete everything in the tmp/ folder
bin/cache.sh delete

# Update no-intro DATs based on Love Pack P/C zip
bin/cache.sh sync_nointro_dats /path/to/love_pack_pc.zip
```

sd:

```
# Create new SD card with RetroPie on it
bin/sd.sh create /path/to/device

# Back up SD card
bin/sd.sh backup /path/to/device /path/to/backup/folder

# Restore SD card
bin/sd.sh restore /path/to/device /path/to/backup/folder

# RSync files from the retropie partition to another directory
bin/sd.sh sync /path/to/mounted_retropie_source /path/to/retropie_target

# RSync media files only from the retropie partition to another directory
bin/sd.sh sync_media /path/to/mounted_retropie_source /path/to/retropie_target
```

## Cheat Sheet

Since the standalone emulators are always going to work slightly differently than
libretro cores, I have a cheat sheet to remind me how to use the system:

### Exiting

| System            | Keyboard       | Controller                  |
| ----------------- | -------------- | --------------------------- |
| dreamcast         | ESC            | Select (to Menu)            |
| n64 (mupen64plus) | ESC            | Hotkey + Start              |
| pc                | CTRL+F9        | None                        |
| nds               | ESC            | Right Analog Left (to Menu) |
| psp               | ESC            | Right Analog Left (to Menu) |
| *                 | Hotkey + Start | Hotkey + Start              |

It's too easy to accidentally hit a single button during gameplay,
so instead of exiting when pressing Right Analog Left, the emulator
will always go to its native menu.

### Controllers

| System        | Controller setup                                                  |
| ------------- | ----------------------------------------------------------------- |
| c64           | Switch Port 1 / 2 controller with virtual keyboard (Select)       |
| intellivision | Switch Left / Right controller with Select                        |
| nds           | Only the last configured joystick will be set up                  |
| psp           | Only the last configured joystick will be set up                  |
| videopac      | Requires 2 controllers (Left / Right controller is game-specific) |

Please note that due to limitations in how controllers are set up in NDS (Nintendo DS)
and PSP (PlayStation Portable), retrokit can only automatically configured one
controller.  The last configured controller input under `.hardware.controllers.inputs`
in [config/settings.json](config/settings.json) will be the used.

Other controllers can still be used, but you must either manually configure it in the
emulator's UI or use the same button mappings for all controllers.

### Menus

| System        | Keyboard   | Controller         |
| ------------- | ---------- | ------------------ |
| arcade        | Tab        | N/A                |
| dreamcast     | Select     | Select             |
| nds           | Tab        | Right Analog Left  |
| psp           | N/A        | Right Analog Left  |
| *             | Hotkey + X | Hotkey + X         |

### Cheats

| System        | Emulator      | How to Cheat                                      |
| ------------- | ------------- | ------------------------------------------------- |
| arcade        | lr-fbneo      | Options menu in Retroarch GUI (Hotkey + X)        |
| arcade        | lr-mame*      | Cheats menu in MAME UI (Tab on Keyboard)          |
| *             | lr-*          | Cheats menu in Retroarch GUI (Hotkey + X)         |

## Hardware

Please note that this process has only been tested with an Ubuntu-based
laptop for flashing the sd card.

### Controllers

To identify your controller names and ids, there's unfortunately no easy way out
of the box that I'm aware of.  However, you can follow the instructions here: https://askubuntu.com/a/368711

Here's a simplified version you can run:

```sh
cat > sdl2-joystick.c <<EOF
#include <SDL.h>
int main() {
  SDL_Init(SDL_INIT_JOYSTICK);
  for (int i = 0; i < SDL_NumJoysticks(); ++i) {
    SDL_Joystick* js = SDL_JoystickOpen(i);
    SDL_JoystickGUID guid = SDL_JoystickGetGUID(js);
    char guid_str[1024];
    SDL_JoystickGetGUIDString(guid, guid_str, sizeof(guid_str));
    const char* name = SDL_JoystickName(js);
    printf("%s \"%s\"\n", guid_str, name);
    SDL_JoystickClose(js);
  }
  SDL_Quit();
}
EOF

gcc -o sdl2-joystick sdl2-joystick.c `pkg-config --libs --cflags sdl2`
./sdl2-joystick
```

Alternatively, you can either:

* Find your controller in the [SDL controller database](https://github.com/gabomdq/SDL_GameControllerDB/blob/master/gamecontrollerdb.txt) or
* Set up your controllers through EmulationStation

If you're not familiar with SDL GUIDs, setting up your controllers through EmulationStation
is probably the best way.

### Default Keyboard inputs

| RetroPad Button | Key         |
| --------------- | ----------- |
| A               | X           |
| B               | Y           |
| X               | S           |
| Y               | A           |
| Start           | Enter       |
| Select          | Right Shift |
| LS (L)          | Q           |
| RS (R)          | W           |
| LT (L2)         | 1           |
| RT (R2)         | 2           |

Hotkey: Select

References:

* [Key Bindings](https://docs.libretro.com/guides/input-and-controls/#default-retroarch-keyboard-bindings)
* [Hotkeys](https://retropie.org.uk/docs/Controller-Configuration/#hotkey)

## Emulators

The following emulators / cores are built from source:

* dosbox-staging (unofficial, no binaries available yet)
* lr-yabasanshiro (unofficial, no binaries available yet)
* mupen64plus (Due to crashes described [here](https://retropie.org.uk/forum/topic/30313/solved-gliden64-crashing-back-to-emulationstation-for-every-n64-rom?_=1622729300554))
* yabasanshiro (unofficial, no binaries available yet)

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
* [Joshua Rancel](https://www.youtube.com/watch?v=Dwa6LDLZ2rE) for the default splash screen (Retro History)
* eXo for Dosbox game configuration settings
* RetroPie forums
* Reddit forums
* ...and everyone who has put so much work in over the years to help make all of this even possible

## Future improvements

There are too many improvements to count here, but some ideas are:

* Sinden Lightgun autoconfig (once I receive it)
* Support for non-Raspbian platforms
* Computer-based emulators (Amigo, Apple II, etc.)
* More advanced filters for certain systems

If you want to make changes for your own specific setup, feel free to.  I'll accept
contributions for anything that will make it easier for you to customize this to your
own setup.

Also, if you have improvements that will help everyone (e.g. perhaps there are better
ways of doing autconfig for controllers), I'll happily review those.
