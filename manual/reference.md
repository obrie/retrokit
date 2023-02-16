
## Cheat Sheet

Since the standalone emulators are always going to work slightly differently than
libretro cores, I have a cheat sheet to remind me how to use the system:

### Exiting

| System            | Keyboard               |        Controller           |
| ----------------- | ---------------------- | --------------------------- |
| advmame           | Hotkey + Start (once)  | Hotkey + Start (once)       |
| dreamcast         | ESC                    | Select (to Menu)            |
| n64 (mupen64plus) | ESC                    | Hotkey + Start              |
| pc                | CTRL+F9                | None                        |
| nds               | ESC                    | Right Analog Left (to Menu) |
| psp               | ESC                    | Right Analog Left (to Menu) |
| manuals           | Hotkey + Up            | Hotkey + Up                 |
| *                 | Hotkey + Start (twice) | Hotkey + Start (twice)      |

It's too easy to accidentally hit a single button during gameplay,
so instead of exiting when pressing Right Analog Left, the emulator
will always go to its native menu.

### Controllers

| System        | Controller setup                                                  |
| ------------- | ----------------------------------------------------------------- |
| c64           | Switch Port 1 / 2 controller with virtual keyboard (Select)       |
| intellivision | Switch Left / Right controller with Select                        |
| videopac      | Requires 2 controllers (Left / Right controller is game-specific) |

### Menus

| System        | Keyboard   | Controller         |
| ------------- | ---------- | ------------------ |
| arcade - rgui | Hotkey + X | Hotkey + X         |
| arcade - mame | Tab        | L2                 |
| dreamcast     | Select     | Select             |
| nds           | Tab        | Right Analog Left  |
| psp           | N/A        | Right Analog Left  |
| *             | Hotkey + X | Hotkey + X         |

The following libretro MAME emulators support viewing the menu with a controller:

* lr-mame2015

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
* arcade - lr-mame2010
* atarijaguar
* c64
* intellivision
* n64 - mupen64plus standalone
* sg-1000
* vectrex
* videopac
