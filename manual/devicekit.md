# devicekit

[`devicekit`](/lib/devicekit/) is a Python library for building applications based on the controls
set up in RetroArch.  It's used to power the controls for both [`manualkit`](/manual/manualkit.md)
and [`powerkit`](/manual/powerkit.md).  While other libraries exist for interacting
with system controllers, this library is built with the following goals in mind:

* Provide compatibility with RetroArch controller configurations

  This means that when you set up your controller configuration through EmulationStation,
  it'll be automatically picked up and read by devicekit -- no additional configurations
  required.

* Provide high-level functionality, such as repeat events, key down/up events, and "grab" support

## Dependencies

devicekit has the following dependencies:

* evdev
* pyudev

To install the dependencies, you can run the following:

```bash
devicekit/setup.sh depends
```

To remove dependencies:

```bash
devicekit/setup.sh remove
```

## Example

Below is an example integration with `devicekit`:

```python
#!/usr/bin/env python3

import signal

import devicekit.retroarch as retroarch
from devicekit.input_device import DeviceEvent
from devicekit.input_type import InputType
from devicekit.input_listener import InputListener

class Example():
    def run(self):
        retroarch_config = retroarch.Config()
        self._listener = InputListener()
        self._listener.on(InputType.JOYSTICK, 'exit_emulator', self._on_exit_emulator, grabbed=False, hotkey=True, on_key_down=True, retroarch=True, repeat=False)
        self._listener.on(InputType.JOYSTICK, 'state_slot_decrease', self._on_state_slot_decrease, grabbed=False, hotkey=True, on_key_down=True, retroarch=True, repeat=False)
        self._listener.listen()
    
    def _on_exit_emulator(self, event: DeviceEvent) -> None:
        print(f'Triggered exit sequence on device {event.device.id}')
    
    def _on_state_slot_decrease(self, event: DeviceEvent) -> None:
        print(f'Triggered state slot decrease sequence on device {event.device.id}')

if __name__ == '__main__':
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    Example().run()
```

As you can see, this makes it incredibly easy to build new applications that use existing
configurations to drive functionality and behavior in the system with a joystick and/or
keyboard.

Below is an example of the repeat functionality:

```python
#!/usr/bin/env python3

import signal

import devicekit.retroarch as retroarch
from devicekit.input_device import DeviceEvent
from devicekit.input_type import InputType
from devicekit.input_listener import InputListener

class Example():
    def run(self):
        retroarch_config = retroarch.Config()
        self._listener = InputListener(repeat_delay=1, repeat_interval=0.1, repeat_turbo_wait=3)
        self._listener.on(InputType.JOYSTICK, 'a', self._on_press_a, grabbed=False, hotkey=False, on_key_down=True, retroarch=True, repeat=True)
        self._listener.listen()
    
    def _on_press_a(self, event: DeviceEvent) -> None:
        print(f'Triggered A on device {event.device.id}, turbo: {event.turbo}')

if __name__ == '__main__':
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    Example().run()
```

In this example, when the user holds down the `a` joystick button, after 1 second the callback
will start repeating every 0.1 seconds.  After 3 seconds, the event will indicate that the
repeater is now in turbo mode.  That can mean different things depending on the application.
For example, in manualkit this means that we start skipping through manuals multiple pages
at a time instead of 1 page at a time.

## Usage

`devicekit` is used by the following libraries:

* manualkit
* powerkit

For more complex examples of usage, it's best to reference those libraries and how they
interface with `devicekit`.
