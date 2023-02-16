## Controllers

To identify your controller names and ids, there's unfortunately no easy way out
of the box that I'm aware of.  However, you can follow the instructions here: https://askubuntu.com/a/368711

Here's a simplified version you can run:

```sh
cat > sdl2-joystick.c <<EOF
#include <SDL.h>
int main() {
  SDL_Init(SDL_INIT_JOYSTICK);
  for (int i = 0; i < SDL_NumJoysticks(); ++i) {
    SDL_Joystick* js = SDL_JoystickOpen(i);
    SDL_JoystickGUID guid = SDL_JoystickGetGUID(js);
    char guid_str[1024];
    SDL_JoystickGetGUIDString(guid, guid_str, sizeof(guid_str));
    const char* name = SDL_JoystickName(js);
    printf("%s \"%s\"\n", guid_str, name);
    SDL_JoystickClose(js);
  }
  SDL_Quit();
}
EOF

gcc -o sdl2-joystick sdl2-joystick.c `pkg-config --libs --cflags sdl2`
./sdl2-joystick
```

Alternatively, you can either:

* Find your controller in the [SDL controller database](https://github.com/gabomdq/SDL_GameControllerDB/blob/master/gamecontrollerdb.txt) or
* Set up your controllers through EmulationStation

If you're not familiar with SDL GUIDs, setting up your controllers through EmulationStation
is probably the best way.

### Configuration

You can configure your controllers through `config/settings.json` like so:

```
{
  "hardware": {
    "controllers": {
      "inputs": [
        {
          "name": "Keyboard"
        },
        {
          "name": "Xbox 360 Controller",
          "id": "030000005e0400008e02000014010000",
          "description": "8Bitdo X-Input, Wired, Triggers to Buttons, Xbox layout (Arcade Stick)",
          "swap_buttons": false
        },
        {
          "name": "Xbox One Controller",
          "id": "050000005e040000fd02000030110000",
          "description": "8Bitdo X-Input, Bluetooth, Triggers to Buttons, Xbox layout (Arcade Stick)",
          "swap_buttons": false
        },
        {
          "name": "8Bitdo SN30 Pro",
          "id": "05000000c82d00000161000000010000",
          "description": "8Bitdo D-Input, Bluetooth, Nintendo Layout",
          "swap_buttons": true,
          "axis": {
            "ABS_X": 128,
            "ABS_Y": 128,
            "ABS_Z": 128,
            "ABS_RZ": 128
          }
        }
      ]
    }
  }
}
```

### Default Keyboard inputs

| RetroPad Button | Key         |
| --------------- | ----------- |
| A               | X           |
| B               | Y           |
| X               | S           |
| Y               | A           |
| Start           | Enter       |
| Select          | Space       |
| LS (L)          | Q           |
| RS (R)          | W           |
| LT (L2)         | 1           |
| RT (R2)         | 2           |

Hotkey: Select

References:

* [Key Bindings](https://docs.libretro.com/guides/input-and-controls/#default-retroarch-keyboard-bindings)
* [Hotkeys](https://retropie.org.uk/docs/Controller-Configuration/#hotkey)
