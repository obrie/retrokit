# powerkit

In addition to installing tools for managing hardware like fan speed within cases,
retrokit also includes a service called powerkit which manages safe shutdown of
your system.

There are 2 buttons that powerkit understands: reset and shutdown.  The function
of reset varies depending on the context in which the system is running:

* If an emulator is running, `reset` will terminate the emulator
* If EmulationStation is running, `reset` will restart EmulationStation
* If neither an emulator nor EmulationStation is running, `reset` will restart the OS

On the other hand, `shutdown` will always be interpreted as a request to gracefully
turn off the system.

Keep in mind that the actual buttons that trigger a `reset` or `shutdown` will vary
based on case:

| Case    | Function  | How to trigger                              |
| ------- | --------- | ------------------------------------------- |
| nespi   | reset     | Press the "Reset" button                    |
| nespi   | shutdown  | Press the "Power" button                    |
| argon1  | reset     | Double tap the Power button                 |
| argon1  | shutdown  | Hold the Power button for 3+ seconds        |
| gpi2    | shutdown  | Switch power to off                         |
