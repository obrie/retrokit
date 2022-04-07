# Controls

[Reference Diagrams](https://retropie.org.uk/docs/Controller-Configuration/#controller-configuration)

## Controllers

Connection types:

* Wired > 2.4ghz > Bluetooth

Preferred hardware:

* 8Bitdo Sn30 Pro Bluetooth Gamepad (Sn Edition)
  D-Input mode

* 8Bitdo Arcade Stick
  2.4ghz, X-Input mode, D-Pad

Keys to reducing input lag:

* TV Game Mode
* Wired controllers
* Use NTCS version of games
* Enable runahead

References:

* [Input latency spreadsheet](https://docs.google.com/spreadsheets/d/1KlRObr3Be4zLch7Zyqg6qCJzGuhyGmXaOIUrpfncXIM/edit)
* [Input lag tips](https://retropie.org.uk/docs/Input-Lag/)
* [SDL Keycodes](https://wiki.libsdl.org/SDLKeycodeLookup)

Autoconfig setup:

* bin/controllers

Manual configuration (if necessary):

* config/systems/arcade/advmame.rc
* config/systems/dreamcast/redream.cfg
* config/systems/n64/InputAutoCfg.ini
* config/systems/nds/drastic.cfg
* config/systems/psp/controls.ini

## Commodore 64

| RetroPad Button | JoyStick                |
| --------------- | ----------------------- |
| D-Pad           | Joystick                |
| Left Analog     | Mouse/paddles           |
| B               | Fire button             |
| X               | Space                   |
| L2              | Escape (RUN/STOP)       |
| R2              | Enter (RETURN)          |
| Select          | Toggle virtual keyboard |
| Start           | F1                      |

References:

* [Key Bindings](https://retropie.org.uk/docs/Commodore-64-VIC-20-PET/#controls_1)

### Virtual Keyboard

Virtual Keyboard:

* Right ctrl / Keyboard:ASR changes port
* RST - Reset
* ZOM - Turbo trigger
* ASR - Aspect Screen Ratio
* JOY - Port
* SVD - Save Disk
* STB - Status Bar
