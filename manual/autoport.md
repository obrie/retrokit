# autoport

[autoport](/lib/autoport/) is an automatic controller (joystick *and* mouse) selection tool
for emulators.  It will prioritize which controllers are used as Player 1, Player 2, etc. based
on predefined configuration settings.

The benefit of autoport is that you don't need to care which order your joystick or mouse
was plugged in to.  You can guarantee that certain controllers are always chosen for
Player 1, Player 2, etc.

## Features

autoport is inspired by [RetroPie-joystick-selection](https://github.com/meleu/RetroPie-joystick-selection)
but introduces a more sophisticated controller selection system as well as support for
additional emulators.

autoport currently supports the following emulators:

* libretro cores
* drastic
* hpyseus
* mupen64plus
* ppsspp
* redream

This means that autoport will adjust the input configuration for every one of these emulators
based on a single configuration file.

The following high-level features are supported by autoport:

* Joystick and mouse selection
* Filter by name, vendor_id, product_id, usb path, device_id, running system processes, etc.
* Set the device type automatically in libretro cores and redream
* Detailed control over how many devices get configured and which player they're associated with
* Profile-based configurations so you can use different autoport configurations based on the game being played
* Global, system, emulator, and game-specific overrides

## Configuration files

Autoport uses pre-configured profiles to determine the priority order of joystick and mouse
devices when starting up a game.  You will find these configurations located here:

| Scope    | retrokit path                                             | RetroPie path                                                          |
| -------- | --------------------------------------------------------- | ---------------------------------------------------------------------- |
| Global   | config/autoport/autoport.cfg                              | /opt/retropie/config/systems/all/autoport.cfg                          |
| System   | config/systems/{system}/autoport.cfg                      | /opt/retropie/config/systems/{system}/autoport.cfg                     |
| Emulator | config/systems/{system}/autoport/emulators/{emulator}.cfg | /opt/retropie/config/systems/{system}/autoport/emulators/{emlator}.cfg |
| Game     | config/systems/{system}/autoport/{name|title}.cfg         | /opt/retropie/config/systems/{system}/autoport/{name}.cfg              |

It will prioritize each of the above configurations like so (highest to lowest):

* Game
* Emulator
* System
* Global

## Configuration

At its most basic, autoport configurations are structured like so:

```
[base]

mouse1...
mouse2...
mouse...

joystick1...
joystick2...
joystick...

[autoport]

profile = base
enabled = true
```

As you might imagine, this can get a lot more advanced.  For each input (whether that's a mouse
or a joystick), you can configure the following filters:

* name: The name of the device
* vendor_id: The Vendor ID of the device
* product_id: The Product ID of the device
* usb_path: A full or partial filesystem path for the device
* related_usb_path: A full or partial filesystem path for another input connected to the same usb port
* device_id: The unique identifier for the device (e.g. the bluetooth mac address)
* running_process: A system process that must be running for the input to be considered connected

Example configuration:

```
joystick1_vendor_id = "1234"
joystick1_product_id = "5678"
```

Additionally, each input can define how it gets set up in the emulator:

* set_device_type: The type of device to configure in the emulator (libretro cores and redream)
* limit: The maximum number of devices to select from this device type

Example configuration:

```
joystick1_limit = 2
joystick1_set_device_type = 123
```

Finally, you can control how joysticks and mice get set up overall with the following configurations:

* start: The player id to start configuring from
* limit: The total number of devices to assign to players
* skip: Specific player ids to skip when assigning devices
* order: The explicit order in which to assign inputs to players
* set_device_type: The type of device to configure in the emulator (libretro cores and redream)
* set_device_type_p2: The type of device to configure for a specific player number

Example configuration:

```
joystick_start = 2
joystick_limit = 1
```

To see a full example configuration, review [autoport.cfg](/config/autoport/autoport.cfg).

## Profiles

autoport supports the concept of profiles.  A profile is a group of configurations intended for
a certain category of games.  The default "base" profile is used when a specific profile isn't
referenced.  Below is an example of an autoport configuration that defines multiple profiles:

```
[base]

[lightgun]

# Assume by default we're not working with more than 2 lightguns
mouse_limit = 2
joystick_profile = base

[trackball]

# Assume by default we're not working with more than 2 trackballs
mouse_limit = 2
joystick_profile = base

# Example:

# mouse1 = "Kensington ORBIT WIRELESS TB Mouse"

[keyboard]

keyboard_limit = 1
joystick_profile = base
mouse_profile = base

[dial]

joystick_profile = base
mouse_profile = base

[pedal]

joystick_profile = base
mouse_profile = base

[paddle]

joystick_profile = base
mouse_profile = base

[autoport]

profile = base
enabled = true
```

The biggest benefit of profiles is that you can define a single configuration across
all of your systems and reference different profiles based on the type of game you're
playing.

Additionally, when paired with retrokit, autoport profiles will be automatically selected
based on metadata known about what inputs are used by certain games.  This can make
setting up inputs, such as lightguns, very easy to do.

## Examples

Below are some example use cases you could run into.

### Sinden lightguns

To set up Sinden lightguns to be set up as a mouse for Player 1 / Player 2, you can
define an autoport profile like so:

```
[lightgun]

mouse1 = "Unknown SindenLightgun Mouse"
mouse1_related_usb_path = "ttyACM0"
mouse1_running_process = "LightgunMono.exe"

mouse2 = "Unknown SindenLightgun Mouse"
mouse2_related_usb_path = "ttyACM1"
mouse2_running_process = "LightgunMono2.exe"
```

This configuration will ensure that the Sinden Lightgun software is running
and connected before using it as an input.

### GPi Case

Support you have a GPi case and you want to prioritize wireless controllers over the
built-in gamepad.  You can do that like so:

```
[base]

joystick1 = "8Bitdo SN30 Pro"
joystick1_device_id = "e4:17:d8:f8:f0:75"
joystick2 = "8Bitdo SN30 Pro"
joystick2_device_id = "e4:17:d8:96:f0:75"
joystick3 = "8Bitdo SN30 Pro"
joystick4 = "Microsoft X-Box 360 pad"
joystick4_usb_path = "usb"
joystick5 = "Microsoft X-Box 360 pad"
joystick5_usb_path = "serial"
```

This prioritizes, in oder:

* Specific bluetooth controllers
* Wired usb controllers
* The built-in controller (serial connection)

## Different profiles

Below is my autoport.cfg that defines different profiles based on the type of inputs
the game supports:

```
[base]

mouse1 = "Telink Wireless Receiver Mouse"
mouse2 = "Kensington ORBIT WIRELESS TB Mouse"

joystick1 = "8BitDo Ultimate Wireless / Pro 2 Wired Controller"
joystick2 = "8Bitdo SN30 Pro"
joystick3 = "Microsoft X-Box 360 pad"

[arcade]

joystick1 = "8BitDo Arcade Stick"
joystick2 = "8BitDo Ultimate Wireless / Pro 2 Wired Controller"
joystick3 = "Microsoft X-Box 360 pad"

[trackball]

mouse1 = "Kensington ORBIT WIRELESS TB Mouse"
```

## How it works

During the runcommand `onlaunch` hook, autoport will read from all of the various configurations
defined on the system to determine which profile is active.  Based on that profile, it will attempt
to match as many inputs of a particular name before it moves onto the next input name.  If an input
can't be found, then it will move onto the next input.

After the game is terminated, the `onend` hook will be executed, causing autoport to revert any
changes it may have needed to make to the emulator's configuration files.  If there is a system
crash or this hook is never executed, it will still revert those changes the next time a game
is launched.
