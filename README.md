# retrokit

retrokit provides hands-off management of arcade systems using currently known best
practices as I understand them.

Specifically, it can set up:

* Argon cases
* Display settings
* Localization
* IR configuration
* Retroarch configuration
* Splash screens
* Scraping
* Bezels
* Themes
* Cheats
* Launch images
* VNC
* Wifi configuration
* Bluetooth
* Controllers
* Overclocking
* Emulation Station settings / systems
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

* 3DO
* Arcade
* Atari 2600
* Atari 7800
* Commodore 64
* Nintendo 64
* Nintendo Entertainment System
* Nintendo Game Boy
* Nintendo Game Boy Advanced
* Nintendo Game Boy Color
* PC
* PC Engine / TurboGrafx-16
* Playstation
* Sega CD0
* Sega Game Gear
* Sega Genesis / MegaDrive
* Sega Mastersystem
* Super Nintendo Entertainment System
* Turbografx
* MegaDrive
* PSX
* SegaCD

There are also system-specific features, including:

* Automatic joystick selection for Commodore 64 via C64 Dreams spreadsheet
* Automatic integration of eXoDOS configurations for PC games
* Automatic selection of the appropriate rom set for arcade games

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

The hardware setup assumes:

* Raspberry Pi 4
* Argon case
* 8bitdo SN30 Pro controllers
* 8Bitdo Arcade Stick

You can have complete control over what parts of retrokit get used via everything
in the config/ folder, particularly config/settings.json.

## Instructions

1. Flash new image with `bin/sd.sh`
1. Start up Pi
1. Connect your first controller (keyboard, for example)
1. Quit EmulationStation
1. Copy retrokit to your sd card to /home/pi/retrokit, including .env and config/blutooth/
1. Run `bin/update.sh system` to update Raspbian
1. Reboot
1. Run `bin/update.sh retropie` to update RetroPie-Setup and its packages
1. Run `bin/setup.sh` to run all setup modules

To access via VNC:

* Open in browser: `http://<ip address of rpi>:9080/stream/webrtc`

## Thanks

There are so many people / resources that I've pulled over time to make
retrokit what it is.  That includes:

* [Roslof's compatibility list](https://docs.google.com/spreadsheets/d/1Rq4shU1RUSdcc7cTVWeORMD-mcO6BwXwQ7TGw8f5_zw/edit#gid=1985896929) for Arcade and Nintendo 64 emulator / configuration
* [Progretto-Snaps](https://www.progettosnaps.net/) for filtering arcade roms via categories, ratings, and languages
* [C64 Dreams](https://www.zombs-lair.com/c64-dreams) for Commodore 64 game configuration settings
* [eXo](https://***REMOVED***) for Dosbox game configuration settings
* [Abdessamad Derraz](https://github.com/Abdess)
* [The Bezel Project](https://github.com/thebezelproject)
* [ehettervik](https://github.com/ehettervik) for the pixel theme
* [TMNTturtleguy](https://github.com/TMNTturtleguy) for the ComicBook theme
* RetroPie forums
* Reddit forums
* ...and everyone who has put so much work in over the years to help make all of this even possible

## Future work

The only future work I have planned is to automate my Sinden Lightgun setup once I
receive it.

If you want to make changes for your own specific setup, feel free to.  I'll accept
contributions for anything that will make it easier for you to customize this to your
own setup.

## TODO

Differences discovered with my actual machine and what retrokit does on a fresh install.

boot/config.txt:

* Uncomment overscan_scale=1 (and see what impact it has)
* Comment enable_uart=1
