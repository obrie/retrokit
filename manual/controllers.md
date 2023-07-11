# Controllers

With retrokit, controls for all emulators are autoconfigured through EmulationStation.
There should be few cases where you need to modify the input configurations by hand.
This is because retrokit introduces additional autoconfiguration scripts for a number
of emulators, including:

* advmame
* drastic
* hypseus
* ppsspp
* redream
* supermodel3

## Non-Interactive setup

You may want to set up a custom retrokit profile so that your controllers are
automatically configured without having to run them through EmulationStation.  In order
to do this, you'll first need to identify your controller names and ids.

Unfortunately, there's no easy way to do that out of the box.  However, you can follow the
instructions here: https://askubuntu.com/a/368711

Here's a simplified version you can run from your Raspberry Pi:

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

If you're not familiar with SDL GUIDs, setting up your controllers through EmulationStation
is probably the best way.

## Configuration

Once you've identified your controllers, you can configure them through `config/settings.json` like so:

```json
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

You can even set up Player 2/3/4 keyboard controls in RetroArch like so:

```json
{
  "hardware": {
    "controllers": {
      "inputs": [
        {
          "name": "Keyboard"
        },
        {
          "name": "Keyboard2"
        }
      ]
    }
  }
}
```

Keyboard2.cfg:

```xml
<?xml version="1.0"?>
<inputList>
  <!-- Represents the Player 2 controls on a keyboard -->
  <inputConfig type="keyboard2" deviceName="Keyboard2" deviceGUID="-1">
    <!-- r -->
    <input name="up" type="key" id="114" value="1" />
    <!-- f -->
    <input name="down" type="key" id="102" value="1" />
    <!-- d -->
    <input name="left" type="key" id="100" value="1" />
    <!-- g -->
    <input name="right" type="key" id="103" value="1" />
    <!-- 8 -->
    <input name="start" type="key" id="56" value="1" />
    <!-- 9 -->
    <input name="select" type="key" id="57" value="1" />
    <!-- 6 -->
    <input name="a" type="key" id="54" value="1" />
    <!-- 7 -->
    <input name="b" type="key" id="55" value="1" />
  </inputConfig>
</inputList>
```

Notice we identify which player id we're dealing with for the keyboard by both the `type`
and the `deviceName`.  Player 1 is identified by simply not providing a player number.
