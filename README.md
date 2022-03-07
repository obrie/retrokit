# retrokit

retrokit provides hands-off management of arcade systems using currently known best
practices as I understand them.

Specifically, it can set up:

* Cases (e.g. Argon)
* Bluetooth
* Controllers (including autoconfig for advmame, drastic, mupen64plus, ppsspp, redream, and ir)
* IR configuration
* SSH
* VNC
* Wifi configuration
* Overclocking
* Display settings
* Localization
* Splash screens (async loading process, reduces load time by 2s)
* Custom Retropie modules
* Scraping (via skyscraper) with automated fallback queries
* Themes
* Retroarch configuration
* EmulationStation configuration
* Overlays / Bezels
* Cheats (RetroArch, MAME, NDS, etc.)
* HiScores
* Launch images
* Emulator installation
* ROM Playlist (m3u) auto-generation for multi-disc games
* EmulationStation Collections management
* Lightgun collections
* Lightgun-compatible overlay auto-generation
* Sinden lightgun controller configuration
* In-game manuals
* Enhanced Kiosk mode (prevent retroarch changes)
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
* OCR'd / Searchable

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
* Automatic filtering of runnable games for Sega Saturn
* Optimized settings per-game for Arcade, Atari Jaguar, and N64
* Conversion of ISO-based ROMs to CHD for Dreamcast, PCEngine, PSX, and SegaCD
* Conversion of ISO-based ROMS to CSO for PSP
* DLC support for PSP (PSN) ROMs

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
* 1TB or more storage capacity

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
| manuals           | Hotkey + Up    | Hotkey + Up                 |
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
| arcade      | Emulator compatibility   | No      | https://docs.google.com/spreadsheets/d/1Rq4shU1RUSdcc7cTVWeORMD-mcO6BwXwQ7TGw8f5_zw |
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
Redump DAT files.  In order to reduce maintenance, the clonelists only contain ROMs that have clones.

## Manuals

The manuals in this project were all hand-sourced from a variety of public websites.  Only
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
* jpg / jpeg / png / gif / bmp / tif

Once downloaded, these formats will all be converted into PDF, maintaining the quality of the
original manual when possible.

### Archival

In order to support the long-term archival of manuals, all manuals referenced in this project
have been archived on archive.org.  This not only ensures that the manuals live beyond the
life of their source projects, but also provides a more stable source to download manuals
from.  Over time, this archive will be updated to reflect additional manuals made available
or new systems supported.

Reference: https://archive.org/details/romkit-manualkit

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
    "postprocess": {
      "resolution": 300,
      "quality_factor": 0.3,
      "downsample_filesize_threshold": 0,
      "downsample_resolution_threshold": 1.0
    }
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
pieces of information for identification a manual:

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
        "regional_priority": false,
        "allow_fallback": true
      }
    }
  },
```

By default, retrokit will prefer languages based on the priority order defined in the system's
configuration.  However, two additional settings are available to adjust this behavior:

* `regional_priority` - If set to `true`, this will prioritize languages according to the
  regions from the ROM name rather than the order defined in the configuration
* `allow_fallback` - If set to `true`, then this will fall back to the list of languages
  defined in the configuration if `regional_priority` is `true` and no regional languages
  matched

### Controls

`manualkit` can be controlled by keyboard or controller.  These settings can be modified in
`config/manuals/manualkit.conf`.  It's expected that the `keyboard_toggle` and `joystick_toggle`
buttons will be pressed in combination with retroarch's configured `hotkey` button.  For
example, the default configuration expects that `select` + `up` will be used to toggle the
display of the manual on the screen.

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
| atarijaguar   | 75MB     |
| atarilynx     | 10MB     |
| c64           | 70MB     |
| coleco        | 3MB      |
| dreamcast     | 115GB    |
| gamegear      | 50MB     |
| gb            | 65MB     |
| gba           | 3.5GB    |
| gbc           | 230MB    |
| intellivision | 2MB      |
| mastersystem  | 40MB     |
| megadrive     | 530MB    |
| n64           | 4.5GB    |
| nds           | 35GB     |
| nes           | 75MB     |
| ngpc          | 20MB     |
| pc            | 13GB     |
| pcengine      | 10GB     |
| ports         | 115MB    |
| psp           | 265GB    |
| psx           | 266GB    |
| saturn        | 20GB     |
| sega32x       | 60MB     |
| segacd        | 35GB     |
| sg-1000       | 1MB      |
| snes          | 650MB    |
| vectrex       | 200KB    |
| videopac      | 500KB    |

Note that this does *not* include other data such as BIOS files / scraped media.
It also only includes a selection of PC games.

If you wanted to include the entire PC collection, you would need another 500GB
or so (so a 2TB drive).

## Emulators

The following emulators / cores are built from source:

* lr-yabasanshiro (unofficial, no binaries available yet)

### Performance

Not all systems perform well on the Pi 4.  Those with performance
issues on some games include:

* 3do
* atarijaguar
* n64
* pc
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
* eXo for Dosbox game configuration settings
* RetroPie forums
* Reddit forums
* ...and everyone who has put so much work in over the years to help make all of this even possible

## Future improvements

There are too many improvements to count here, but some ideas are:

* More comprehensive compatibility ratings
* Support for non-Raspbian platforms
* Computer-based emulators (Amigo, Apple II, etc.)

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
