# Extensions

retrokit provides a number of extensions to RetroPie that help improve overall quality of
life when building and running new systems.  This documentation helps describe those
extensions.

## autostart

`autostart.sh` (located at `/opt/retropie/configs/all/autostart.sh`) is executing on system
startup and is responsible for launching emulationstation.  On its own this is a simple, yet
effective, script.  However, there are cases where retrokit ideally integrates additional
hooks into the "autostart" script so that certain commands are executed *before* emulationstation
launches and certain commands are executed *after* emulationstation launches.

In order to allow for various scripts to be hooked into the autostart process, `autostart.sh`
is reimplemented so that it supports the following hooks:

* onstart
* onend

When `autostart.sh` runs, the following will happen:

* All scripts in `/opt/retropie/configs/all/autostart.d/onstart/` are executed
* `/opt/retropie/configs/all/autostart-onlaunch.sh` is executed

When the `onlaunch` script, ends the following will happen:

* All scripts in `/opt/retropie/configs/all/autostart.d/onend/` are executed

## configscripts

In RetroPie, configscripts are responsible for configuring emulators based on
new inputs being set up through EmulationStation.  By default, RetroPie supports
automatically configuring the following emulators:

* daphne
* emulationstation
* mupen64plus
* openmsx
* pifba
* pisnes
* reicast
* retroarch

This functionality is fantastic and makes using an emulator so much easier because,
as a user, you don't need to learn the ins and outs of each emulator's configuration
system.  The challenge is that retrokit makes use of many other standalone emulators
that are not natively autoconfigured by RetroPie.

The [`es-configscripts`](/ext/es-configscripts/) directory contains scripts for configuring
additional emulators used by retrokit.  Those systems include:

* advmame
* drastic
* hypseus
* ppsspp
* redream
* sinden
* supermodel3

Additionally, there are custom extensions / overrides for existing emulators and the
system via the following configscripts:

* ir - Support for IR remote controls
* retroarch-nkb - Adds support for Player 2/3/4 Keyboard configuration in RetroArch
* retrokit-mupen64plus - Adds support for Keyboard configuration in mupen64plus (rather than being hard-coded)
* retrokit-overrides - Adds support for automatically disabling certain buttons enabled via autoconf

For usage of `retrokit-overrides`, see an example [here](profiles/kiosk/config/controllers/autoconf.cfg).

## runcommand

`runcommand` is the launch program used by RetroPie to run an emulator from EmulationStation.
When `runcommand` runs, there are 3 potential hooks for users to add custom scripts into the
lifecycle of the command:

* `runcommand-onstart.sh`
* `runcommand-onlaunch.sh`
* `runcommand-onend.sh`

These hooks can be incredibly useful for different types of integrations.  However, since only a
single script is supported for each hook, it means that we can't easily manage hooks from
multiple applications (and from the user!) in an effective way.  We'd end up needing a way to
flag sections of the script.

Ideally, these hooks behave more like EmulationStation's -- where you can define multiple scripts
per hook.  *This* is what the runcommand extension does in retrokit.

The above scripts are implemented in order to call multiple scripts:

* `runcommand-onstart.sh` will call all scripts defined in `/opt/retropie/configs/all/runcommand.d/onstart/`
* `runcommand-onlaunch.sh` will call all scripts defined in `/opt/retropie/configs/all/runcommand.d/onlaunch/`
* `runcommand-onend.sh` will call all scripts defined in `/opt/retropie/configs/all/runcommand.d/onend/`

## scriptmodules

The `scriptmodules` extension in retrokit is used for integrating additional scriptmodules within
RetroPie's own `ext/` folder.  This includes emulators, libretro cores, and additional supplementary
modules.

Most if the scriptmodules in retrokit are based on, or inspired by, scriptmodules built by others
in the community.

### emulators

The following emulator modules are included:

* `actionmax` - Installs the `actionmax` emulator at https://github.com/DirtBagXon/actionmax-pi
* `advmame-joy` - Installs the `advmame` emulator with patches that disable overrides in advmame
   which hard-code controls for certain controllers
* `supermodel3` - Installs the `model3emu` emulator at https://github.com/DirtBagXon/model3emu-code-sinden

### libretrocores

The following libretro core modules are included:

* `lr-duckstation`
* `lr-mame0222` - lr-mame, frozen at version 0.222
* `lr-mame0244` - lr-mame, frozen at version 0.244
* `lr-mame2016-lightgun` - lr-mame2016 with lightgun improvements
* `lr-mess-atarijaguar` - lr-mess emulator commands for atarijaguar
* `lr-mess-gameandwatch` - lr-mess emulator commands for gameandwatch
* `lr-swanstation`
* `lr-yabasanshiro`

### ports

The following port modules are included:

* emptyports - Creates the directory and system for `ports`

`emptyports` is used because retrokit adds entries to `ports` outside the context of
a RetroPie scriptmodule.  In order to avoid replicating the logic for setting up the
`ports` system, a scriptmodule is instead used to assist with that.

### supplementary

The following supplementary modules are included:

* mame-tools - Builds tools (such as chdman) for the latest version of MAME
* p2keyboard - Provides a UI for configuration Player 2 keyboard controls in RetroArch
* retrokit - UI controls for managing retrokit
* retrokit-system - Interface for setting up custom emulators / retroarch configs outside the context of a scriptmodule (for use with lr-mess)
* xpadneo-plus - xpadneo with v0.10.0 backports and support for triggers_to_buttons
