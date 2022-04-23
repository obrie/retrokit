# retrokit

retrokit provides software automation for the management of retro-gaming systems
with RetroPie / Raspberry Pi 4 using currently known best practices as I understand them.

Specifically, it can set up:

* Cases (e.g. Argon)
* Controllers (including autoconfig for advmame, drastic, mupen64plus, ppsspp, redream, and ir)
* IR configuration
* VNC
* Display settings
* Splash screens (async loading process, reduces load time by 2s)
* Scraping (via skyscraper) with automated fallback queries
* Themes
* Retroarch configuration
* EmulationStation configuration
* Overlays / Bezels (with lightgun-compatible auto-generatino)
* Cheats (RetroArch, MAME, NDS, etc.)
* HiScores
* Launch images
* Emulator installation
* Game manuals
* System controller reference guides
* ROM Playlist (m3u) auto-generation for multi-disc games
* EmulationStation Collections management (including lightguns)
* Sinden lightgun controller configuration
* In-game manuals
* Printable gamelists
* Autoconfig overrides
* Bluetooth
* SSH
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

* Automatic joystick selection for Commodore 64 via C64 Dreams project
* Automatic integration of eXoDOS configurations for PC games
* Automatic selection of the best emulator per-game for Arcade, Atari Jaguar, and N64
* Automatic filtering of runnable games for 3Do, PSP, Sega Saturn, and more
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

retrokit, romkit, manualkit, and all of the supporting tools represent the work I did
to build a configuration management system for my personal setup.

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
* 1TB or more storage capacity

You can have complete control over what parts of retrokit get used via everything
in the `config/` folder, particularly `config/settings.json`.

I strongly recommend forking this repo and using your fork to update and track
all of your personal preferences.

## Instructions

### Creating a base image

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

### Install via base image

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
bin/setup.sh configure system-retroarch n64

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

vacuum:

```
# Vacuum ROM files no longer needed
bin/vacuum.sh roms | bash

# Vacuum manuals for ROMs no longer installed
bin/vacuum.sh manuals | bash

# Vacuum scraped media for ROMs no longer installed
bin/vacuum.sh media | bash

# Vacuum overlays for ROMs no longer installed
bin/vacuum.sh overlays | bash
```

## Profiles

To override any configuration settings, you have two options:

1. Modify the settings directly in retrokit's `config/` directory
2. Create a profile that defines overrides which will be merged into
   or overwrite retrokit's `config/` settings.

Profiles are a way of overlaying retrokit's default configuration settings with
your own custom settings.  It does this by either merging your settings on top
of the default settings or completely overwriting the default settings, depending
on what makes most sense.

The default profile is called `mykit` as defined in the `PROFILES` environment
variable in [`.env.template`](.env.template).

The profile directory is structured like so:

```
profiles/
profiles/{profile_name}
profiles/{profile_name}/{config_file}
profiles/{profile_name}/{config_dir}/{config_file}
```

The directory structure is meant to mirror that of the folder at the
root of this project.  For example, suppose you wanted to change which systems
were installed.  To do so, you would define a `settings.json` override:

profiles/mykit/config/settings.json:

```json
{
  "systems": [
    "nes",
    "snes"
  ]
}
```

These settings will be merged into [`config/settings.json`](config/settings.json)
and then used throughout the project.

You can even define multiple profiles.  For example, support you wanted to define
a "base" profile and then layer customizations for different systems on top of that.
To do that, add something like this to your `.env`:

```
PROFILES=base,crt
# PROFILES=base,hd
```

In the examples about, a `base` profile defines overrides that you want to use for
all of your profiles.  A `crt` or `hd` profile then defines overrides that you want
to use for specific hardware configurations.

### Overrides

In general, anything under `config/` can be overridden by a profile.  The following
types of files will be *merged* into the defaults provided by retrokit:

* env
* ini
* json

The following specific configurations will be overwritten entirely by profiles:

* `config/controllers/inputs/*.cfg`
* `config/localization/locale`
* `config/localization/locale.gen`
* `config/localization/timezone`
* `config/skyscraper/videoconvert.sh`
* `config/systems/mame/default.cfg`
* `config/systems/mame2016/default.cfg`
* `config/themes/*`
* `config/vnc/*`
* `config/wifi/*`

### Binary overrides

In addition to overriding configuration settings, you can also override binaries
that are related to configuration settings.  This includes:

* Retrokit setup scripts
* Custom RetroPie scriptmodules
* RetroPie controller autoconfig scripts
* Sinden controller scripts

These scripts are expected to be located in a `bin/` path under your profile's
directory with the same structure as retrokit's.  For example, to add a new setup
script for your profile, you can configure it like so:

profiles/mykit/config/settings.json:

```json
{
   "setup": [
      "...",
      "mycustomscript"
   ]
}
```

You would then create your setup script under `profiles/mykit/bin/setup/mycustomscript.sh`
to match the same structure as retrokit's `bin/` folder.

### Environment variables

Environment variables can be defined in 3 places:

* Current shell environment
* .env at the root of this project
* .env at the root of profiles/{name}/

Which environment variables take priority largely depends on how you've defined
your environment variables.  If your `.env` is configured like so:

```sh
export ROMKIT_DEMO=true
```

...then `ROMKIT_DEMO` will always be `"true"` regardless of the current shell
environment.  To instead respect the current environment, you can change the format
to:

```sh
export ROMKIT_DEMO=${ROMKIT_DEMO:-true}
```

### Use cases

Beyond building profiles for your own personalized systems, profiles could also
pave the path for adapting retrokit to systems beyond the Raspberry Pi 4.  If you
have a profile that you'd like to share for others to use, please let me know and
I'd be happy to add it to the documentation in this repo.

## Cheat Sheet

Since the standalone emulators are always going to work slightly differently than
libretro cores, I have a cheat sheet to remind me how to use the system:

### Exiting

| System            | Keyboard               |        Controller           |
| ----------------- | ---------------------- | --------------------------- |
| advmame           | Hotkey + Start (once)  | Hotkey + Start (once)       |
| dreamcast         | ESC                    | Select (to Menu)            |
| n64 (mupen64plus) | ESC                    | Hotkey + Start              |
| pc                | CTRL+F9                | None                        |
| nds               | ESC                    | Right Analog Left (to Menu) |
| psp               | ESC                    | Right Analog Left (to Menu) |
| manuals           | Hotkey + Up            | Hotkey + Up                 |
| *                 | Hotkey + Start (twice) | Hotkey + Start (twice)      |

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
and PSP (PlayStation Portable), retrokit can only automatically configure one
controller.  The last configured controller input under `.hardware.controllers.inputs`
in [config/settings.json](config/settings.json) will be used.

Other controllers can still be used, but you must either manually configure it in the
emulator's UI or use the same button mappings for all controllers.

### Menus

| System        | Keyboard   | Controller         |
| ------------- | ---------- | ------------------ |
| arcade - rgui | Hotkey + X | Hotkey + X         |
| arcade - mame | Tab        | L2                 |
| dreamcast     | Select     | Select             |
| nds           | Tab        | Right Analog Left  |
| psp           | N/A        | Right Analog Left  |
| *             | Hotkey + X | Hotkey + X         |

The following libretro MAME emulators support viewing the menu with a controller:

* lr-mame2015

### Cheats

| System        | Emulator      | How to Cheat                                       |
| ------------- | ------------- | -------------------------------------------------- |
| arcade        | lr-fbneo      | Options menu in Retroarch GUI                      |
| arcade        | lr-mame*      | Cheats menu in MAME GUI                            |
| dreamcast     | redream       | Cheats menu in Redream GUI                         |
| nds           | drastic       | Cheats menu in Drastic GUI                         |
| psp           | ppsspp        | Cheats menu in PPSSPP GUI ("Import from cheat db") |
| *             | lr-*          | Cheats menu in Retroarch GUI                       |

Cheats are not supported on the following systems / emulators:

* 3do
* arcade - lr-mame2010
* atarijaguar
* c64
* intellivision
* n64 - mupen64plus standalone
* sg-1000
* vectrex
* videopac

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

## Game Metadata

Game metadata comes from a variety of sources.  When possible, retrokit pulls
directly from those sources instead of caching and maintaining them in this
codebase.  An overview of metadata and where it comes from is described below.

| System      | Metadata                 | In Git? | Source                                        |
| ----------- | ------------------------ | ------- | --------------------------------------------- |
| arcade      | Categories               | No      | https://www.progettosnaps.net/                |
| arcade      | Emulator compatibility   | Yes     | https://docs.google.com/spreadsheets/d/1Rq4shU1RUSdcc7cTVWeORMD-mcO6BwXwQ7TGw8f5_zw |
| arcade      | Languages                | No      | https://www.progettosnaps.net/                |
| arcade      | Ratings                  | No      | https://www.progettosnaps.net/                |
| atarijaguar | Emulator compatibility   | Yes     | https://retropie.org.uk/forum/topic/27999/calling-pi-4-atari-jaguar-fans |
| c64         | "Best Of" (C64 Dreams)   | Yes     | https://docs.google.com/spreadsheets/d/1r6kjP_qqLgBeUzXdDtIDXv1TvoysG_7u2Tj7auJsZw4 |
| dreamcast   | Parent/Clone info        | Yes     | https://github.com/unexpectedpanda/retool     |
| n64         | Emulator compatibility   | Yes     | https://docs.google.com/spreadsheets/d/1Rq4shU1RUSdcc7cTVWeORMD-mcO6BwXwQ7TGw8f5_zw |
| nds         | Parent/Clone info        | Yes     | https://github.com/unexpectedpanda/retool     |
| pc          | DAT                      | Yes     | exodos                                        |
| pc          | DOSBox Config            | Yes     | exodos                                        |
| pc          | Emulator compatibility   | Yes     | https://docs.google.com/spreadsheets/d/1Tx5k3F0_AO6w00WrXULMBSUTRhtLyIhHI8Wz8GuqLfQ/edit#gid=2000917190 |
| pcengine    | Parent/Clone info        | Yes     | https://github.com/unexpectedpanda/retool     |
| psp         | Parent/Clone info        | Yes     | https://github.com/unexpectedpanda/retool     |
| psx         | Genres                   | No      | https://github.com/stenzek/duckstation/raw/master/data/database/gamedb.json |
| psx         | Parent/Clone info        | Yes     | https://github.com/unexpectedpanda/retool     |
| saturn      | Parent/Clone info        | Yes     | https://github.com/unexpectedpanda/retool     |
| saturn      | Emulator compatibility   | Yes     | https://www.uoyabause.org/games               |
| segacd      | DOSBox Config            | Yes     | exodos                                        |
| segacd      | Parent/Clone info        | Yes     | https://github.com/unexpectedpanda/retool     |
| *           | No-Intro DATs            | Yes     | https://datomatic.no-intro.org/index.php?page=download |
| *           | Genre / Rating info      | Yes     | https://www.screenscraper.fr/                 |

If possible, the preference would always be that retrokit/romkit is pulling from
the source for all of the above metadata.  However, some sources either aren't in
a format that can be parsed (e.g. they're a forum post), don't allow direct
downloads (e.g. dat-o-matic), or require an excessively large download to access
a small file (e.g. pc dosbox configurations).

### Clone info

There are important differences between what's considered the parent and what's considered the
clone between different systems.

No-Intro DAT files generally sort games based on the rules laid out [here](https://forum.no-intro.org/viewtopic.php?p=9503&sid=7c1efa5d868e8dd0d0836f033691563a#p9503):

> 0. Final/Complete > Proto/Beta/Demo
> 1. Games containing En language > Other languages
> 2. World > Continent/Multi Country > Country
> 3. Old "main" console regions (EUR/USA/JPN) > Other countries (so i.e. Japan > Spain)
> 4. Country with earlier dump available
> 5. Highest revision

On the other hand, Redump DAT files are sorted chronologically based on the order in which they
were dumped.  Additionally, Redump does not provide clone metadata for its ROMs.

In order to (a) provide some consistency, (b) provide some stability in the metadata, and (c) make
it easier to work with, the same general rules are applied to the custom clonelists generated for
Redump DAT files.

## Manuals

The manuals used by this project were all hand-sourced from a variety of public websites.  Only
manuals that have been defined in the DAT files used by retrokit are included.  All manuals
are installed in PDF format, but they can be sourced from a variety of formats.  Details
about the process are described below.

### Sources

The specific website used to source manuals largely depends on the system and the community
based around it.  Manuals often exist on many different websites and in different forms.
In general, the follow priorities are used when determining which source to use:

1. **Quality**: Higher quality > lower quality
1. **Resolution**: Higher resolution > lower resolution (unless it's 600+ dpi)
1. **Color**: Color > Black and White
1. **Watermark**: Non-watermarked manuals > watermarked manuals
1. **Language**: Single language > multi-language (unless it's just truncated)
1. **Archives**: Archive.org sources > other sources
1. **Ownership**: Community-owned websites > individually-owned websites

As you can see, there are a large number of considerations to keep in mind when
identifying the appropriate source for each individual manual.

### Source formats

The following source formats are supported:

* pdf
* cbz / zip
* cb7 / 7z
* cbr / rar
* html
* txt
* doc / docx / wri / rtf
* jpg / jpeg / png / gif / bmp / tif

Once downloaded, these formats will all be converted into PDF, maintaining the quality of the
original manual when possible.

### Archival

In order to support the long-term archival of manuals, all manuals referenced in this project
have been archived on archive.org.  This not only ensures that the manuals live beyond the
life of their source projects, but also provides a more stable source to download manuals
from.  Over time, this archive will be updated to reflect additional manuals made available
or new systems supported.

Reference: https://archive.org/details/retrokit-manuals

### Compression

For many manuals, the quality of the manual from the original source is higher than necessary
for use in a typical retro gaming console.  While using the original manuals can sometimes be
useful, there is a significant disk usage overhead associated with that.  For this reason, the
default configuration is to enable post-processing on manuals to reduce overall filesize.

The archive.org archives provide 2 already post-processed versions of manuals:

* Original quality
* Medium/High quality

If you want to configure your own post-processing configuration, you can still use the archive.org
manuals by using a configuration like so:

config/settings.json:
```json
{
  "manuals": {
    "archive": {
      "url": "https://archive.org/download/romkit-manualkit/{system}/original.zip/{parent_title} ({languages}).pdf",
      "processed": false
    },
    ...
  }
}
```

### Organization

All manuals have been organized by system and categorized by language.  Every manual has been
reviewed to identify which languages are included.  The ISO 639-1 standard is used for
identifying languages.  In general, regional identifiers are not included in the language
code unless it is significant for differentiating manuals.  For example, `en` generally refers
to US-based English manuals while `en-gb` generally refers to non-US based English manuals.

The titles given to manuals are based on the *parent* title.  There are, therefore, 2 main
pieces of information for identifying a manual:

* Parent title (no modifier details)
* Comma-delimited list of languages

### Manual Selection

The logic for determining which manual to use for a specific ROM is largely based on language
preference for the user, *not* the country identifiers in the ROM filename.  The relevant
retrokit configuration is:

```json
  "metadata": {
    "manual": {
      "languages": {
        "priority": [
          "en",
          "en-gb"
        ],
        "prioritize_region_languages": false,
        "only_region_languages": false
      }
    }
  },
```

By default, retrokit will prefer languages based on the priority order defined in the system's
configuration.  However, two additional settings are available to adjust this behavior:

* `prioritize_region_languages` - If set to `true`, this will prioritize languages according to the
  regions from the ROM name rather than the order defined in the configuration
* `only_region_languages` - If set to `true`, then this will only use manuals in languages
  associated with the region defined for the RM

### Controls

`manualkit` can be controlled by keyboard or controller.  These settings can be modified in
`config/manuals/manualkit.conf`.  It's expected that the keyboard / joystick `toggle`
buttons will be pressed in combination with retroarch's configured `hotkey` button.  For
example, the default configuration expects that `select` + `up` will be used to toggle the
display of the manual on the screen.

### Arcade manuals

As far as I've been able to find, there doesn't exist any form of player instruction manuals
for arcade games.  You can attempt to cut out instructions from bezel artwork, but that's a
very time consuming process that I haven't undertaken.  There *do* exist owner manuals for
the arcade cabinets themselves, but that's not helpful to most players.

As an alternative, I've built manuals based on several sources:

* Cabinets from https://www.progettosnaps.net/cabinets/
* Flyers from https://www.progettosnaps.net/flyers/
* Select artwork from https://www.progettosnaps.net/artworks/
* Game initialization data from https://www.progettosnaps.net/gameinit/

The generated manuals aren't perfect, but I felt having some form of instructions was better
than nothing.  You can see how these manuals are generated in the
[generate_arcade_manuals.sh](bin/tools/generate_arcade_manual.sh) script.

If anyone has better sources or wants to build better manuals, I'd fully support that effort.

### Reference Guides

In addition to the game manuals themselves, reference "cheat" sheets have been created for
each individual system with documentation on what controls / hotkeys are available for the
system and how they map between the original controller and your controller.

The intention behind these reference guides is to make it easy to look up what controls
are available rather than having to look up the controls in RetroPie or RetroArch
documentation.

These guides include:

* System features available (e.g. cheats, netplay, etc.)
* Keyboard controls
* Hotkey configurations
* Images of the system's original controller
* Images of RetroArch's controller configuration
* Game-specific controller overrides

The guides can be viewed by loading the manual via manualkit's configured hotkey and
scrolling to the end of the manual (you can just go in reverse if you're on the first
page of the manual).  If the game has no manual, an image will be displayed saying
"No Manual".  However, you'll still be able to scroll forward to the reference guide.

## Documentation

In addition to manuals and reference sheets available per-game, printable documentation
can also be generated.  This documentation currently includes:

* Introduction to the system
* Game lists

In particiular, game lists are useful if you want others to be able to look through which
games to play while someone is playing a game or controlling the system.  Think of it like
a karaoke playlist.

To generate the documentation, you can use the following command(s):

```bash
bin/docs.sh build
```

This will generate PDF files in the `docs/build` folder.

## Storage Capacity

The default filters assume that there is 1TB of capacity available for installing
ROMs.  These filters generally have the following rules:

* 1G1R (one game per region)
* Excluded categories: Adult, Board games, Casino, Educational
* For CD-based systems, 1G1SF (one game per sports franchise)

The approximate capacity required per system is broken down below:

| System        | Capacity |
| ------------- | -------- |
| 3do           | 40GB     |
| arcade        | 13GB     |
| atari2600     | 6MB      |
| atari7800     | 3MB      |
| atarijaguar   | 125MB     |
| atarilynx     | 11MB     |
| c64           | 135MB     |
| coleco        | 3MB      |
| dreamcast     | 113GB    |
| gamegear      | 51MB     |
| gb            | 61MB     |
| gba           | 3.3GB    |
| gbc           | 226MB    |
| intellivision | 2MB      |
| mastersystem  | 41MB     |
| megadrive     | 515MB    |
| n64           | 3.5GB    |
| nds           | 36GB     |
| nes           | 72MB     |
| ngpc          | 17MB     |
| pc            | 13GB     |
| pcengine      | 11GB     |
| ports         | 114MB    |
| psp           | 230GB    |
| psx           | 266GB    |
| saturn        | 13GB     |
| sega32x       | 64MB     |
| segacd        | 35GB     |
| sg-1000       | 2MB      |
| snes          | 633MB    |
| vectrex       | 280KB    |
| videopac      | 748KB    |

Note that this does *not* include other data such as BIOS files / scraped media.
It also only includes a selection of PC games.

If you wanted to include the entire PC collection, you would need another 500GB
or so (so a 2TB drive).

Additional files:

| Extra        | Capacity |
| ------------ | -------- |
| Covers       | 2GB      |
| Manuals      | 19GB     |
| Screenshots  | 3GB      |
| Videos       | 20GB     |
| Wheels       | 660MB    |

## Emulators

The following emulators / cores are built from source:

* lr-swanstation (unofficial, no binaries available yet)
* lr-yabasanshiro (unofficial, no binaries available yet)

### Performance

Not all systems perform well on the Pi 4.  Those with performance
issues on some games include:

* 3do
* atarijaguar
* n64
* pc
* psp
* saturn

To the best of my ability, I've attempted to capture compatibility
ratings and emulator selections for these systems to find the games
that work pretty well.  For these reasons, you'll find that these
systems have fewer games installed than others.

### Compatibility

For emulators that can experience poor performance on the Pi 4, there are
ratings that have been gathered from various sources to identify which games
work well and which games don't.

The ratings are roughly categorized like so:

| Rating | Description                                          |
| ------ | ---------------------------------------------------- |
| 5      | Near perfection or perfection (no noticeable issues) |
| 4      | 1 or 2 minor issues                                  |
| 3      | 1 or 2 major issues, but still playable              |
| 2      | 3 or more major issues, not fun to play              |
| 1      | Unplayable                                           |

Some of this is subjective.  For the most part, the defaults in retrokit avoid
filtering for games that have major issues.

## Thanks

There are so many people / resources that I've pulled over time to make
retrokit what it is.  That includes:

* [Roslof's compatibility list](https://docs.google.com/spreadsheets/d/1Rq4shU1RUSdcc7cTVWeORMD-mcO6BwXwQ7TGw8f5_zw/edit#gid=1985896929) for Arcade and Nintendo 64 emulator / configuration
* [Progretto-Snaps](https://www.progettosnaps.net/) for filtering arcade roms via categories, ratings, and languages
* [C64 Dreams](https://www.zombs-lair.com/c64-dreams) for Commodore 64 gamelists and configuration settings
* [Abdessamad Derraz](https://github.com/Abdess)
* [The Bezel Project](https://github.com/thebezelproject) for overlays
* [ehettervik](https://github.com/ehettervik) for the pixel theme
* [TMNTturtleguy](https://github.com/TMNTturtleguy) for the ComicBook theme
* [DTEAM](https://retropie.org.uk/forum/topic/27999/calling-pi-4-atari-jaguar-fans/8?_=1621951484030) for Atari Jaguar settings
* [valerino](https://github.com/valerino/RetroPie-Setup) for lr-mess integration
* [zerojay](https://github.com/zerojay/RetroPie-Extras) for lr-mess-jaguar scriptmodule
* [Joshua Rancel](https://www.youtube.com/watch?v=Dwa6LDLZ2rE) for the default splash screen (Retro History)
* [unexpectedpanda](https://github.com/unexpectedpanda/retool) for clonelists
* [ScreenScraper](https://www.screenscraper.fr/) for game metadata
* [Steven Cozart](https://github.com/Texacate/Visual-RetroPie-Control-Maps) for arcade control maps (including Kevin Jonas, Howard Casto and yo1dog)
* [Dan Patric](https://archive.org/download/console-logos-professionally-redrawn-plus-official-versions) for console logos
* [Mark Davis](https://vectogram.us/) for controller images
* [Wikimedia](https://commons.wikimedia.org/) for conroller images
* [louiehummv](https://retropie.org.uk/forum/topic/28693/a-workaround-for-the-northwest-drift-issue) for axis calibration fixes
* eXo for Dosbox game configuration settings
* RetroPie forums
* Reddit forums
* ...and everyone who has put so much work in over the years to help make all of this even possible

## Future improvements

There are too many improvements to count here, but some ideas are:

* Move manualkit to sdl2
* Unify system metadata into a single file
* Support for more systems (Amiga, Apple II, etc.)
* Support for non-Raspbian platforms
* Separate retrokit, romkit, and manualkit
* More comprehensive compatibility ratings

If you want to make changes for your own specific setup, feel free to.  I'll accept
contributions for anything that will make it easier for you to customize this to your
own setup.

Also, if you have improvements that will help everyone (e.g. perhaps there are better
ways of doing autconfig for controllers), I'll happily review those.

## FAQ

* Wouldn't it be easier to just distribute an image?

This would be illegal.  I'm not in the business of distributing ROMs illegally,
only providing an system that makes it easier for you to legally manage your
RetroPie.
