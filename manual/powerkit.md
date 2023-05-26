# powerkit

`powerkit` is an advanced safe shutdown tool that supports both safe power
shutdown and safe emulator shutdown.

## Overview

`powerkit` is a service that runs in the background with 2 primary goals:

* Responding to physical `reset` buttons based on the current running context
* Responding to physical `shutdown` buttons

The signals for the physical buttons can come from multiple sources:

* Physical switches on the case (e.g. argon1, nespi, gpi, etc.)
* Button combinations on a joystick
* Button combinations on a keyboard

`powerkit` is similar, in roots, to the [ES-generic-shutdown](https://github.com/crcerror/ES-generic-shutdown)
project, but introduces several additional features.

## Reset

The function of "reset" varies depending on the context in which the system is running:

* If an emulator is running, `reset` will terminate the emulator and return to EmulationStation
* If EmulationStation is running, `reset` will restart EmulationStation
* If neither an emulator nor EmulationStation is running, `reset` will restart the OS

The major benefit of this, combined with powerkit's integration with RetroArch input
configuration profiles, is that you can utilize your existing `exit` input configurations
across all standalone emulators.  For example, suppose you've configured the following:

* Hotkey: `select`
* Start button: `start`
* `quit_press_twice = true`

In this scenario, pressing `select+start` twice would exit a libretro emulator.  When
`powerkit` is running, it will read these configurations from RetroArch and implement
the same behavior for standalone emulators.  This means you don't have to worry about
which combinations of buttons / menus to go through for each emulator.

### Delays

In order to ensure that `powerkit` doesn't attempt a reset for libretro emulators when
using the joystick/keyboard `exit_emulator` hotkey combo, `powerkit` will wait a
configured number of seconds before it terminates the emulator.  This ensures that
any libretro emulator is given enough time to gracefully terminate before `powerkit`
kicks in.

### Reset protection

In some cases, you may accidentally press a physical reset button multiple times or
press the exit button combo multiple times on your joystick.  To protect against
interpreting this as multiple resets, `powerkit` will suppress any reset that happens
less than 5 seconds after a prior reset.  This window can be configured in the
`powerkit.cfg` file.

## Shutdown

The function of "shutdown" is consistent for every integration: it will gracefully
turn off the system.

Note that there is currently no integration for `shutdown` with the joystick / keyboard.
Instead, this must be done either from the case or from the `EmulationStation` menu.

### Hold Time

In some cases, such as with the NesPi case, you can configure how long the shutdown
button must be pressed before a shutdown event is interpreted.  By default, this is
2 seconds.

## Integrations

The actual buttons that trigger a `reset` or `shutdown` will vary based on case:

| Case    | Function  | How to trigger                              |
| ------- | --------- | ------------------------------------------- |
| nespi   | reset     | Press the "Reset" button                    |
| nespi   | shutdown  | Press the "Power" button                    |
| argon1  | reset     | Double tap the Power button                 |
| argon1  | shutdown  | Hold the Power button for 3+ seconds        |
| gpi2    | shutdown  | Switch power to off                         |

For the keyboard, `reset` will be based on the following RetroArch configurations:

* `quit_press_twice` - Whether the quit hotkey combo must be pressed twice
* `input_enable_hotkey` - The hotkey that's expected to be pressed
* `input_exit_emulator` - The key used for exiting the emulator

For joysticks, `reset` will be based on the following RetroArch configurations:

* `quit_press_twice` - Whether the quit hotkey combo must be pressed twice
* `input_enable_hotkey_btn` - The hotkey that's expected to be used
* `input_exit_emulator_btn` - The button used for exiting the emulator

## Dependencies

powerkit has minimal dependencies:

* devicekit
* psutil
* gpiozero

To install the relevant Python dependencies:

```bash
powerkit/setup.sh depends
```

Note that `devicekit` must be present in the same parent directory as `powerkit`.

To remove dependencies:

```bash
powerkit/setup.sh remove
```

To install powerkit via the retrokit setupmodule:

```bash
bin/setup.sh install powerkit
```

## Getting Started

To use the powerkit CLI manually:

```bash
python3 powerkit/cli.py /path/to/powerkit.cfg
```

## Example Configuration

```ini
[provider]

# Name of the software shutdown provider to use (hotkey is always enabled)
id = argon1

[reset]

# Whether to enable a reset button
# enabled = true

# Minimum number of seconds that must pass before another reset is processed
# min_process_interval = 5

[shutdown]

# Whether to enable a shutdown button
# enabled = true

# Total number of seconds before a held button is considered for shutdown
# hold_time = 2

[hotkey]

# Whether to enable reset functionality via keyboard retroarch exit hotkeys
# keyboard = true

# Whether to enable reset functionality via joystick retroarch exit hotkeys
# joystick = true

# Number of seconds to delay until triggering a reset after the hotkey combo is detected
# trigger_delay = 2

[logging]

# Log-level (DEBUG, INFO, WARN, ERROR)
# level = INFO
```
