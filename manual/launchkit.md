# launchkit

[launchkit](/lib/launchkit/) is an alternative to RetroPie's built-in launchimage feature.
It's intended to be, more or less, a drop-in replacement.  It enables the following:

* Shows the launch image on the screen until the emulator takes over rendering
* Adjusts launch images to the available screen size in order to avoid image skew

The impact of this is two fold:

* The amount of time it takes to launch an emulator is reduced since the runcommand script
  isn't sleeping while the launch image is dislaying
* The same launch image can be used across different display sizes

## How it works

When using `launchkit`, launch images must be suffixed with `launching-extended.{png,jpg}`
instead of `launching.{png,jpg}`.  This is required in order to prevent RetroPie from using
its own internal logic.

`launchkit` will look in the following locations for a launch image (in order of priority):

* /opt/retropie/configs/{system}/images/{rom_name}-launching-extended.{png,jpg}
* /opt/retropie/configs/{system}/launching-extended.{png,jpg}
* /opt/retropie/configs/all/launching-extended.{png,jpg}

If an image is found:

* The TTY is switched to graphics mode so that an image can be displayed
* The screen's dimensions are calculated in order to center the launch image
* The image is rendered to the screen using `ffmpeg` (which immediately exits)
* A background monitoring thread is started

The monitoring thread is used to check when either the runcommand dialog is displayed
*or* the emulator has exited.  This ensures that we clear the screen when other
things may be getting displayed on the screen.  Assuming this doesn't happen, then
the image will be automatically cleared when the emulator starts rendering.
