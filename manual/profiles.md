# Profiles

To override any configuration settings, you have two options:

1. Modify the settings directly in retrokit's `config/` directory
2. Create a profile that defines overrides which will be merged into
   or overwrite retrokit's `config/` settings.

Profiles are a way of overlaying retrokit's default configuration settings with
your own custom settings.  It does this by either merging your settings on top
of the default settings or completely overwriting the default settings, depending
on what makes most sense.

To ensure that your custom profiles are not tracked by git, you should organize
them under `profiles/mykit`.

## Structure

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

You can even define multiple profiles.  For example, suppose you wanted to define
a "base" profile and then layer customizations for different systems on top of that.
To do that, add something like this to your `.env`:

```bash
PROFILES=mykit/base,mykit/crt
# PROFILES=mykit/base,mykit/hd
```

In the examples above, a `mykit/base` profile defines overrides that you want to use for
all of your profiles.  A `mykit/crt` or `mykit/hd` profile then defines overrides that you want
to use for specific hardware configurations.

## Overrides

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

## Binary overrides

In addition to overriding configuration settings, you can also override binaries
that are related to configuration settings.  This includes:

* Retrokit setup scripts
* Custom RetroPie scriptmodules
* RetroPie controller autoconfig scripts
* Sinden controller scripts

These scripts are expected to be located the same path as the original scripts are
(e.g. `bin/`, `ext/`, etc.).  For example, to add a new setup script for your profile,
you can configure it like so:

profiles/mykit/config/settings.json:

```json
{
  "setup": {
    "modules|custom": {
      "add": [
        "mycustomscript"
      ]
    }
  }
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
export PROFILES=filter-demo
```

...then `PROFILES` will always be `"filter-demo"` regardless of the current shell
environment.  To instead respect the current environment, you can change the format
to:

```bash
export PROFILES=${PROFILES:-filter-demo}
```

## Profile dependencies

To help make it easier to build profiles that build on other profiles, you can
can profile dependencies.  For example, suppose you wanted to define
a "base" profile and then layer customizations for different systems on top of that.
Your base profile might look like so:

```
profiles/mykit/base/config/settings.json
```

Your layered customization might then look like so:

```
profiles/mykit/tv/.env
profiles/mykit/tv/config/settings.json
```

In the `mykit/tv` environment, you would then define the dependency on `base` like
so:

```
#include mykit/base
```

You can include multiple include lines as well:

```
#include overclock
#include kiosk
#include lightgun
#include mykit/base
```

With this functionality, you can codify each hardware build that you create and simply
reference that from the root `.env`:

```bash
export PROFILES=${PROFILES:-mykit/tv}
```

## Third-Party Profiles

Beyond building profiles for your own personalized systems, profiles could also
pave the path for adapting retrokit to systems beyond the Raspberry Pi 4.  If you
have a profile that you'd like to share for others to use, please let me know and
I'd be happy to add it to the documentation in this repo.

If you want to host your profile on Github, the only thing I ask is to help
make it easier for others to discover retrokit profiles by naming the repo like
so: `retrokit-profile-<name>`.

## Built-in Profiles

There are a ton of profiles that have been built for all the different hardware
builds that I've created over the years.  Those profiles are described below.

### [8bitdo-arcadestick](/profiles/8bitdo-arcadestick/)

Provides `arcade` system overrides to support the [8BitDo Arcade Stick](https://www.8bitdo.com/arcade-stick/).

* Changes arcade button layout to: a,b,x,y,r2,r,l2,l,r3,l3

### [8bitdo-dinput](/profiles/8bitdo-dinput/)

Sets up controller configurations for 8BitDo controllers in d-input mode.
Controllers include:

* SN30 Pro (Wired + Bluetooth)
* Arcade Stick

### [8bitdo-xinput](/profiles/8bitdo-xinput/)

Sets up controller configurations for 8BitDo controllers in x-input mode.
Controllers include:

* SN30 Pro (Wired + Bluetooth)
* Arcade Stick

### [case-argon](/profiles/case-argon/)

Installs and configures the system for use in an argon1 case.  This includes:

* Installing argon1 power/fan management utilities
* Sets up the system boot configuration
* Updates powerkit to be set up for argon1 cases

### [case-gpi2](/profiles/case-gpi2/)

Installs and configures the system for use in an gpi2 case.  This include the following:

* Installs the necessary screen / audio overlays from https://github.com/RetroFlag/GPiCase2-Script
* Sets up the system boot configuration to automatically switch between HDMI and LCD display
* Automatically switches EmulationStation audio settings based on HDMI connection
* Automatically toggles RetroArch overlays based on HDMI connection
* Changes manualkit triggers to use Select+Up since there's no L2 button
* Updates powerkit to be set up for gpi2 cases
* Adds several shortcuts in EmulationStation's `ports` menu to help improve HDMI/LCD differences
* Integrates xboxdrv so that you can have l2/r2, thumbl, thumbr, and axis controls using the case's controls

...as well as the following fixes:

* Converts mono sound to stereo
* Fixes audio not playing during boot splashscreen

EmulationStation shortcuts available:

* Toggle Game Overlays - Toggles the display of RetroArch overlays
* Toggle Stereo Output - Toggles the patch to convert mono audio to stereo (useful if using headphones)

You can trigger all of the additional buttons not normally available by using xboxdrv
hotkeys:

* L2 (Left Trigger): L + X
* R2 (Right Trigger): L + Y
* Left Thumb Stick: L + A
* Right Thumb Stick: L + B
* Left Axis: L + D-Pad
* Right Axis: R + D-Pad

The above xboxdrv configuration can be viewed [here](/profiles/case-gpi2/config/xboxdrv/gpi2.xboxdrv).

As you can see, there's a ton that this profile does to improve your quality of life when using
the GPi2 cases.  I *strongly* recommended using this profile when building your system with the GPi2
case.  It makes everything work much more smoothly.

### [case-nespi](/profiles/case-nespi/)

Installs and configures the system for use in an nespi 4 case.  This includes:

* Sets up the system boot configuration for power management
* Updates powerkit to be set up for nespi cases

### [display-hdmi](/profiles/display-hdmi/)

Sets up the system boot configuration parameters for using in a display connected
by HDMI.

### [display-hdmi-1080](/profiles/display-hdmi-1080/)

Dependencies:

* display-hdmi

Sets up the system boot configuration parameters for using in a 1080p60 display
connected by HDMI.

### [display-sd](/profiles/display-sd/)

Sets up the system to be used for an SD display.  This includes:

* Display RetroArch overlays
* Use 4x3 launch images and splashscreens

### [filter-1g1r](/profiles/filter-1g1r/)

The `filter-1g1r` profile sets up the romkit prioritization rules so that only
a single game is chosen from a group of clones.

In general, the following prioritization is:

* Country
* Prototype
* Addons
* Romsets
* Release Year (ascending)
* Non-versioned release
* Version (ascending)
* Number of flag groups
* Name length
* Name (alphabetical)

Additionally, system-specific prioriziations are defined as well.

arcade / gameandwatch / mess:

* Prefer the parent over a clone

c64:

* carts > tapes > preservation project
* Publisher
* Re-release
* Loader

pc:

* Release Year (descending)

psp:

* Original release (vs. DLC)

### [filter-1tb](/profiles/filter-1tb/)

Dependencies:

* filter-1g1r

The `filter-1tb` profile assumes that there is 1TB of capacity available for installing
ROMs.  These filters generally have the following rules:

* 1G1R (one game per region)
* Excluded categories: Adult, Board games, Casino, Educational
* For CD-based systems, 1G1F (one game per franchise, e.g. sports franchies)

The approximate capacity required per system is broken down below:

< 10MB:

* atari2600
* atari5200
* atari7800
* atarilynx
* channelf
* coleco
* gameandwatch
* intellivision
* ngp
* pokemini
* sg-1000
* vectrex
* videopac

< 150MB:

* amiga
* atarijaguar
* c64
* gamegear
* gb
* mastersystem
* nes
* ngpc
* pcengine
* ports
* sega32x
* tic80
* wonderswan
* wonderswancolor

< 1GB:

* gbc
* megadrive
* mess
* snes

< 10GB:

* gba
* n64
* neogeocd

< 50GB:

* 3do
* arcade
* daphne
* nds
* pc
* pce-cd
* saturn
* segacd

< 300GB:

* dreamcast
* psp
* psx

Note that this does *not* include other data such as BIOS files / scraped media.
It also only includes a selection of PC games.

Additional files:

| Extra        | Capacity |
| ------------ | -------- |
| Manuals      | 20GB     |
| Screenshots  | 3GB      |
| Videos       | 21GB     |

### [filter-demo](/profiles/filter-demo/)

The `filter-demo` profile is intended to select a handful of games from each system
that demonstrates some of the various functionality available, including:

* Running every supported emulator
* Different controls (joystick, keyboard, lightgun)
* Different filetypes (e.g. tapes vs. cartridges in c64)

This is a great profile to use just to get a sense of what a retrokit system
would look like with just a few games installed.

### [filter-handheld-512gb](/profiles/filter-handheld-512gb/)

Dependencies:

* filter-1tb

The `filter-handheld-512gb` profile assumes that there is 512GB of capacity available
for installing ROMs and that the system this is being used on is a handheld.  This
is the filter primarily used for Gpi Case 2 hardware setups.  The filters is this
profile generally have the following rules:

* High-rated games
* Fewer sports genres
* USA and World regions only

Additionally, only the following systems are included:

* arcade
* atari2600
* atarilynx
* gameandwatch
* nes
* snes
* n64
* gb
* gbc
* gba
* pokemini
* nds
* megadrive
* gamegear
* psx
* psp
* ngpc
* mess
* wonderswan
* wonderswancolor
* ports

The intention is to only include systems that make most sense in a handheld format.

### [filter-local](/profiles/filter-local/)

The `filter-local` profile is primarily used when you are managing and downloading
your list of games yourself.  This filter will instruct romkit to look at the
filesystem to determine what games have been selected by the user *rather than*
building a list based on some predefined set of filters.

### [filter-none](/profiles/filter-none/)

The `filter-none` profile is used to simply tell romkit that there should be
no games selected in each system's list.  This is more of an internal profile
used when building images and ensuring that no stubbed-out game files are left
behind on the image.

### [filter-reset](/profiles/filter-reset/)

The `filter-reset` profile is intended to disable all filters and priority (1g1r)
configurations regardless of what's set in other profiles.

### [image-base](/profiles/image-base/)

The `image-base` profile is used for building retrokit images.  It has a few main
configurations it overrides:

* Allow EmulationStation to scan the filesystem for games
* Disable everything but textual content in skyscraper
* Create stubbed-out game files in romkit
* Ensure that gamelists only include high-compatibility games
* Remove setup scripts that consume significant disk space or might accidentally violate copyright

### [kiosk](/profiles/kiosk/)

The `kiosk` profile makes changes to your system in order to reduce the possibility
of users accidentally changing settings or triggering unexpected behaviors on the
system.  This includes:

* Hide all text on bootup (great if trying to avoid this looking like a computer under the hood)
* Disable in-game libretro reset hotkeys (can be pressed too easily when button smashing)
* Launch EmulationStation in Kiosk mode
* Disable all RetroArch menus except cheats and netplay
* Disable most RetroArch hotkey bindings except menu, pause, and state slots
* Disable most RetroPie setting menus except Bluetooth, Wifi, and Netplay
* Disable most mupen64plus hotkey bindings
* Disable mode switch hotkey in pce-cd and pcengine
* Disable quick system select in EmulationStation

The goal here is to avoid things getting messed up and poor experiences when your
kids are playing and smashing all the buttons.

### [kit-base](/profiles/kit-base/)

Dependencies:

* 8bitdo-xinput
* lightgun
* kiosk
* filter-1g1r
* filter-1tb

This is the base profile used for all hardware kits described in the [hardware](hardware.md)
documentation.  It includes:

* 8bitdo controller configurations in x-input mode
* lightgun support
* kiosk mode
* 1tb game filters

### [kit-handheld-gpi2](/profiles/kit-handheld-gpi2/)

Dependencies:

* kit-base
* case-gpi2
* display-sd
* filter-handheld-512gb

The `kit-handheld-gpi2` profile is used for the GPi CASE 2 hardware kits.  It includes everything
from the base kit as well as:

* GPi configuration
* 512gb game filters

### [kit-tv-argon](/profiles/kit-tv-argon/)

Dependencies:

* kit-base
* case-argon
* display-hdmi-1080

The `kit-tv-argon` profile is used for argon1 hardware kits that are connected to a 1080p60 TV.
It includes everything from thebase kit.

### [kit-tv-nespi](/profiles/kit-nespi/)

Dependencies:

* kit-base
* case-nespi
* display-hdmi-1080

The `kit-tv-nespi` profile is used for nespi 4 hardware kits that are connected to a 1080p60 TV.
It includes everything from thebase kit.

### [lightgun](/profiles/lightgun/)

The `lightgun` profile is used for setting up all of the per-system and per-game configurations
required to use the Sinden lightgun with every supported system.  When using this lightgun,
every game should work out-of-the-box with the Sinden lightgun.  This means there's no messing
around with getting all of the right configurations and tweaks in place.

This profile includes:

* autoport configurations to automatically select the right mouse index for RetroArch
* Player 1/2 RetroArch configurations
* Player 1/2 Sinden configurations
* Enabled lightgun overlays for RetroArch/Daphne

Additionally, per-system and per-game RetroArch configuration settings (such as device type
and input mappings) are set up for the following systems:

* 3do
* arcade
* atari2600
* c64
* daphne
* dreamcast
* mastersystem
* megadrive
* nes
* psx
* segacd
* snes

`autoport` is used heavily in the development of this lightgun as it allows us to use default
shared RetroArch configurations for device type selection.

### [lightgun-sd](/profiles/lightgun-sd/)

Dependencies:

* lightgun

The `lightgun-sd` profile is used to set up lightgun games to work in a 4:3 aspect ratio.
It does this by setting up all lightgun games to point to the default `base` overlay
configuration.  This configuration is set with a 4:3 aspect ratio border.

### [manualkit-compressed](/profiles/manualkit-compressed/)

The `manualkit-compressed` profile is used for creating and sync'ing compressed versions
of manuals in manualkit to archive.org.  It does this by:

* Downloading the original files from archive.org
* Using the manualkit compression scheme to downsample the PDFs
* Disabling clean, ocr, and mutate functionality
* Storing the results in a .files-compressed folder

This profiles is intended to be used internally for the management of manualkit manuals.

### [manualkit-original](/profiles/manualkit-original/)

The `manualkit-original` profile is used for creating and sync'ing original quality versions
of manuals in manualkit to archive.org.  It does this by:

* Disabling compression
* Downloading manuals from their original sources

This profiles is intended to be used internally for the management of manualkit manuals.

### [metakit](/profiles/metakit/)

The `metakit` profile is used by metakit to define a set of rules for identifying which
regional game name is considered the "primary" game in a group and, therefore, defines
the name of the group.  Groups consist of all of the clones for a single game title,
whether that's defined directly in the system's database or through the community's
understanding of game releases.

This profile is intended to be used internally by retrokit for the management of database
updates.

### [network-wired](/profiles/network-wired/)

The `network-wired` profile is intended to be used in hardware configurations where the
wifi is not needed since a wired connection is provided (or no network connection is
required at all).  It does this by:

* Disabling the wifi interface via the boot options

### [none](/profiles/none/)

The `none` profile is a basic placeholder.  It literally does nothing.  However, it can
sometimes be useful if you want to make sure that there are no profiles being used and
you're just using what's provided by retrokit in its base configuration.

### [overclock](/profiles/overclock/)

The `overclock` profile provides some default system overrides that should work fine for
most Raspberry Pi 4b devices.  This includes:

* over_voltage: 2
* arm_freq: 1750

This is considered a "low boost".  "High boost" options are also available, but not enabled
by default.

### [platform-rpi-bullseye](/profiles/platform-rpi-bullseye/)

The `platform-rpi-bullseye` profile provides certain overrides so that retrokit can be
run on Bullseye distributions of the Raspberry Pi OS instead of Buster.

For example:

* Use the FKMS display driver to support VNC and manualkit in a non-X11 environment
* Set the default distribution to bullseye for generating binary builds and images
* etc.

This should be used anytime you expect to be using retrokit on a bullseye installation.

*NOTE* that bullseye isn't yet officially supported by RetroPie, so you shouldn't
expect *everything* to work just yet.
