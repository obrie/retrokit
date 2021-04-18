# RetroKit

retrokit provides hands-off management of arcade systems using currently known best
practices for:

* Argon cases
* Display
* IR
* Retroarch configuration
* Scraping
* Bezels
* Themes
* Cheats
* Launch images
* VNC

Additionally, it provides hands-off management of rom sets via ROMKit for:

* Arcade
* Atari2600
* C64
* GameGear
* MegaDrive
* NES
* PC
* PSX
* SNES

This includes complete control over filtering of Games *and* integration
with external providers to download games that you legally own.

This means you can set up your arcade machine from scratch to feature-complete
with less than a few minutes worth of work.  The automated scripts could take
24-48 hours to complete.

This is built for RetroPie / Raspberry Pi 4.  You may customize it to your
own needs.

## Hardware reference

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

Would have done differently:

* Argon ONE M.2 + SSD

Second generation machine:

* Intel NUC + Debian

References:

* [Tom's Hardware: Raspberry Pi MicroSD Cards](https://www.tomshardware.com/best-picks/raspberry-pi-microsd-cards)
* [Android Central: Raspbery Pi MicroSD Cards](https://www.androidcentral.com/best-sd-cards-raspberry-pi-4)

## Controllers

Connection types:

* Wired > 2.4ghz > Bluetooth

Preferred hardware:

* 8bitdo wireless controllers

Keys to reducing input lag:

* TV Game Mode
* Wired controllers
* Use NTCS version of games
* Enable runahead

References:

* [Input latency](https://docs.google.com/spreadsheets/d/1KlRObr3Be4zLch7Zyqg6qCJzGuhyGmXaOIUrpfncXIM/edit)
* [Input lag](https://retropie.org.uk/docs/Input-Lag/)
* [SDL Keycodes](https://wiki.libsdl.org/SDLKeycodeLookup)

## Frontends

Retropie vs. Lakka vs. Recalbox vs. Batocera

* Retropie: Better overall experience
* Recalbox: too simple, not enough compatible
* Lakka: Too advanced
* Batocera: Too simple

Retropie is the preferred frontend.

## Storage

USB Drive vs. MicroSD:

* The various pros don't really apply for this setup
* Everything is scripted, so transferring ROMs is easy
* Using MicroSD frees up a USB port and bus speed
* Cost is somewhat similar
* Compatiblity is not an issue
* Data will be backed up and stored elsewhere 

References:

* [Running ROMs form a USB drive](https://retropie.org.uk/docs/Running-ROMs-from-a-USB-drive/)

## Configurations

### Retroarch

* https://retropie.org.uk/docs/RetroArch-Configuration/
* https://docs.libretro.com/guides/overrides/

### Retroarch Core Options

All Cores: [Retroarch Cores](/opt/retropie/configs/all/retroarch-core-options.cfg):

* [FBNeo](https://github.com/libretro/docs/blob/master/docs/library/fbneo.md)
* [SNES](https://github.com/libretro/docs/blob/master/docs/library/snes9x_2010.md)
* [VICE](https://docs.libretro.com/library/vice/#core-options)

ROM-specific: /opt/retropie/configs/all/retroarch/config/{core}/{rom[.zip]}.opt

References:

* https://retropie.org.uk/forum/topic/22816/guide-retroarch-system-emulator-core-and-rom-config-files
* https://retropie.org.uk/docs/RetroArch-Core-Options/

## Emulators

* https://emulation.gametechwiki.com/
