# Controls

[Reference Diagrams](https://retropie.org.uk/docs/Controller-Configuration/#controller-configuration)

## Controllers

Connection types:

* Wired > 2.4ghz > Bluetooth

Preferred hardware:

* 8bitdo wireless controllers (D-input mode)

Keys to reducing input lag:

* TV Game Mode
* Wired controllers
* Use NTCS version of games
* Enable runahead

References:

* [Input latency](https://docs.google.com/spreadsheets/d/1KlRObr3Be4zLch7Zyqg6qCJzGuhyGmXaOIUrpfncXIM/edit)
* [Input lag](https://retropie.org.uk/docs/Input-Lag/)
* [SDL Keycodes](https://wiki.libsdl.org/SDLKeycodeLookup)

Configurations:

* config/controllers
* config/systems/arcade/advmame.rc
* config/systems/dreamcast/redream.cfg
* config/systems/n64/InputAutoCfg.ini (to support d-pad)

## Keyboard

| RetroPad Button | Key         |
| ----------------| ----------- |
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
