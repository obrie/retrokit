# sindenkit

sindekit provides plug 'n play functionality as well as quality-of-life improvements
to using a [Sinden Lightgun](https://sindenlightgun.com/).  

## Overview

On Linux, there is currently no good solution for making Sinden Lightguns plug 'n play.
Currently, you must:

* Manually the service for each controller in the background each time
* Manually adjust configurations anytime you want to make minor changes to lightgun behavior

The purpose of `sindenkit` is to make as much of this automatic as possible so that
you, the user, don't have to worry about the technical details for how to start and
manager a Sinden Lightgun.

## Plug 'n Play

When `sindenkit` is installed, a set of udev rules are added that automatically:

* Starts the Sinden software when a lightgun is connected
* Stops the Sinden software when a lightgun is disconnected

`sindenkit` understands how many players are already connected and which Player
configuration to use.

## EmulationStation Menu

In order to help manage your Sinden lightgun behavior through the UI, a menu is install
to the EmulationStation RetroPie system.

### Calibrate

The "Calibrate" menu provides actions for supporting the calibration of lightguns
to your current screen.

* Calibrate Player 1
* Calibrate Player 2
* Set Screen Height
* Start All
* Start Player 1
* Start Player 2
* Stop All

### Controls

The "Controls" menu provides actions for changing the behavior of how controls work
on the lightgun.

* Enable Trigger Repeat
* Disable Trigger Repeat

### Recoil

The "Recoil" menu provides actions for changing the recoil behavior on your lightguns
(if they're installed).

* Disable Recoil
* Enable Recoil
* Recoil 25%
* Recoil 50%
* Recoil 75%
* Recoil 100%

## Usage

Example usage of sindenkit is shown below:

```bash
# Run the given command in the background (required to prevent udev rule timeouts)
sindenkit/sinden.sh backgrounded <add_device|remove_device> <devpath> <devname>

# Adds a lightgun device at the given dev path
sindenkit/sinden.sh add_device <devpath> <devname>

# Removes a lightgun device previously tracked at the given dev path
sindenkit/sinden.sh remove_device <devpath> <devname>

# Starts all players
sindenkit/sinden.sh start_all

# Starts the given player
sindenkit/sinden.sh start <player_id>

# Stops all players
sindenkit/sinden.sh stop_all

# Stops the given player
sindenkit/sinden.sh stop <player_id>

# Restarts the given player (stops, then starts)
sindenkit/sinden.sh restart <player_id>

# Runs the calibration software for the given player
sindenkit/sinden.sh calibrate <player_id>

# Changes the given configuration values for all players
sindenkit/sinden.sh edit_all key1=value1 key2=value2 ...

# Changes the given configuration values for a specific player
sindenkit/sinden.sh edit <player_id> key1=value1 key2=value2 ...
```
