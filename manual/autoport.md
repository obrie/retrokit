### Automatic port selection

In some cases, you may want to prioritize the order in which specific controllers are chosen
as Player 1, Player 2, etc.  For example, you may have:

* Controllers for specific systems
* Lightgun controllers for lightgun games
* Trackball inputs for trackball games
* etc.

To support this, you can use a feature built into retrokit called `autoport`.  Autoport uses
pre-configured profiles to determine the priority order of joystick and mouse devices when
starting up a game.  You will find these configurations located here:

| Scope  | retrokit path                                     | RetroPie path                                            |
| ------ | ------------------------------------------------- | --------------------------------------------------------- |
| Global | config/autoport/autoport.cfg                      | /opt/retropie/config/systems/all/autoport.cfg             |
| System | config/systems/{system}/autoport.cfg              | /opt/retropie/config/systems/{system}/autoport.cfg        |
| Game   | config/systems/{system}/autoport/{name|title}.cfg | /opt/retropie/config/systems/{system}/autoport/{name}.cfg |

See `config/autoport/autoport.cfg` for the examples and documentation on how to use this.

These configurations will be processed during the runcommand `onlaunch` hook.  It will prioritize
each of the above configurations like so (highest to lowest):

* Game
* System
* Global

When looping through the set of devices, `autoport` will attempt to match as many inputs
of a particular name before it moves onto the next input name.  If an input can't be found,
then it will move onto the next input.

This feature is supported on the following emulators:

* libretro cores
* drastic
* hypseus
* ppsspp
* redream
