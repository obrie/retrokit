# Images

Like RetroPie, pre-made images are available for the Raspberry Pi 4b.  The
intention of these images is to create an image with the following configuration:

* Lightgun configurations set up
* Game-specific RetroArch and autoport overrides set up
* Reference system manuals
* Pre-made gamelists with textual content scraped via screenscraper
* Pre-made collections
* Base version of all setup scripts installed (e.g. emulators pre-installed, etc.)

The above is configured based on any possible game from No-Intro / Redump / Exodos.
This means that you only need to add the necessary game files and you should be
able to start playing it with little to no additional configuration.

The image does **not** contain:

* BIOS files
* Game files
* Per-game overlays
* Game manuals
* Scraped media (i.e. images and videos)

## How it works

Images are created using the following commands:

```bash
# Runs the initialization, update, install, cleanup, and export process
bin/image.sh create

# Compresses the exported image
bin/image.sh compress_img
```

You can then use this image to start building your system.

## Recommendations

In general, I would suggest starting with the base RetroPie image and **not**
the retrokit image.  The reason is that you're in a better position to receive
support and become familiar with retrokit if you're integrating it yourself.

retrokit images are made available mostly for demonstration purposes and so
that you can explore it before committing to using it.

## Downloads

You can find the latest images here:

* [MEGA - retrokit folder](https://mega.nz/folder/fkQyTDqY#GDQK2_BwLFupHHiwwfQ0Mg)
