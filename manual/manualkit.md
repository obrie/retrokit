## Manuals

The manuals used by this project were all hand-sourced from a variety of public websites.  Only
manuals that have been defined in the DAT files used by retrokit are included.  All manuals
are installed in PDF format, but they can be sourced from a variety of formats.  Details
about the process are described below.

### Sources

The specific website used to source manuals largely depends on the system and the community
based around it.  Manuals often exist on many different websites and in different forms.
In general, the follow priorities are used when determining which source to use:

1. **Quality**: Higher quality > lower quality
1. **Resolution**: Higher resolution > lower resolution (unless it's 600+ dpi)
1. **Color**: Color > Black and White
1. **Watermark**: Non-watermarked manuals > watermarked manuals
1. **Language**: Single language > multi-language (unless it's just truncated)
1. **Archives**: Archive.org sources > other sources
1. **Ownership**: Community-owned websites > individually-owned websites

As you can see, there are a large number of considerations to keep in mind when
identifying the appropriate source for each individual manual.

### Source formats

The following source formats are supported:

* pdf
* cbz / zip
* cb7 / 7z
* cbr / rar
* html
* txt
* doc / docx / wri / rtf
* jpg / jpeg / png / gif / bmp / tif

Once downloaded, these formats will all be converted into PDF, maintaining the quality of the
original manual when possible.

### Archival

In order to support the long-term archival of manuals, all manuals referenced in this project
have been archived on archive.org.  This not only ensures that the manuals live beyond the
life of their source projects, but also provides a more stable source to download manuals
from.  Over time, this archive will be updated to reflect additional manuals made available
or new systems supported.

To generate archives:

```
PROFILES=manualkit-original SKIP_SYSTEM_CHECK=true bin/setup.sh install system-roms-manuals <system>
PROFILES=manualkit-original SKIP_SYSTEM_CHECK=true bin/cache.sh remote_sync_system_manuals <system> install=false
PROFILES=manualkit-compressed SKIP_SYSTEM_CHECK=true bin/setup.sh install system-roms-manuals <system>
PROFILES=manualkit-compressed SKIP_SYSTEM_CHECK=true bin/cache.sh remote_sync_system_manuals <system> install=false
```

Reference: https://archive.org/details/retrokit-manuals

### Compression

For many manuals, the quality of the manual from the original source is higher than necessary
for use in a typical retro gaming console.  While using the original manuals can sometimes be
useful, there is a significant disk usage overhead associated with that.  For this reason, the
default configuration is to enable post-processing on manuals to reduce overall filesize.

The archive.org archives provide 2 already post-processed versions of manuals:

* Original quality
* Medium/High quality

If you want to configure your own post-processing configuration, you can still use the archive.org
manuals by using a configuration like so:

config/settings.json:
```json
{
  "manuals": {
    "archive": {
      "url": "https://archive.org/download/romkit-manualkit/{system}/original.zip/{parent_title} ({languages}).pdf",
      "processed": false
    },
    ...
  }
}
```

### Organization

All manuals have been organized by system and categorized by language.  Every manual has been
reviewed to identify which languages are included.  The ISO 639-1 standard is used for
identifying languages.  In general, regional identifiers are not included in the language
code unless it is significant for differentiating manuals.  For example, `en` generally refers
to US-based English manuals while `en-gb` generally refers to non-US based English manuals.

The titles given to manuals are based on the *parent* title.  There are, therefore, 2 main
pieces of information for identifying a manual:

* Parent title (no modifier details)
* Comma-delimited list of languages

### Manual Selection

The logic for determining which manual to use for a specific ROM is largely based on language
preference for the user, *not* the country identifiers in the ROM filename.  The relevant
retrokit configuration is:

```json
  "metadata": {
    "manual": {
      "languages": {
        "priority": [
          "en",
          "en-gb"
        ],
        "prioritize_region_languages": false,
        "only_region_languages": false
      }
    }
  },
```

By default, retrokit will prefer languages based on the priority order defined in the system's
configuration.  However, two additional settings are available to adjust this behavior:

* `prioritize_region_languages` - If set to `true`, this will prioritize languages according to the
  regions from the ROM name rather than the order defined in the configuration
* `only_region_languages` - If set to `true`, then this will only use manuals in languages
  associated with the region defined for the RM

### Controls

`manualkit` can be controlled by keyboard or controller.  These settings can be modified in
`config/manualkit/manualkit.cfg`.  It's expected that the keyboard / joystick `toggle`
buttons will be pressed in combination with retroarch's configured `hotkey` button.  For
example, the default configuration expects that `select` + `up` will be used to toggle the
display of the manual on the screen.

### Arcade manuals

As far as I've been able to find, there doesn't exist any form of player instruction manuals
for arcade games.  You can attempt to cut out instructions from bezel artwork, but that's a
very time consuming process that I haven't undertaken.  There *do* exist owner manuals for
the arcade cabinets themselves, but that's not helpful to most players.

As an alternative, I've built manuals based on several sources:

* Cabinets from https://www.progettosnaps.net/cabinets/
* Flyers from https://www.progettosnaps.net/flyers/
* Select artwork from https://www.progettosnaps.net/artworks/
* Game initialization data from https://www.progettosnaps.net/gameinit/

The generated manuals aren't perfect, but I felt having some form of instructions was better
than nothing.  You can see how these manuals are generated in the
[generate_arcade_manuals.sh](bin/tools/generate_arcade_manual.sh) script.

If anyone has better sources or wants to build better manuals, I'd fully support that effort.

### Reference Guides

In addition to the game manuals themselves, reference "cheat" sheets have been created for
each individual system with documentation on what controls / hotkeys are available for the
system and how they map between the original controller and your controller.

The intention behind these reference guides is to make it easy to look up what controls
are available rather than having to look up the controls in RetroPie or RetroArch
documentation.

These guides include:

* System features available (e.g. cheats, netplay, etc.)
* Keyboard controls
* Hotkey configurations
* Images of the system's original controller
* Images of RetroArch's controller configuration
* Game-specific controller overrides

The guides are dynamically generated from your current configuration in RetroArch
and additional system-specific configurations for:

* c64
* daphne
* n64
* nes
* pc
* pcengine
* pce-cd

Additionally, there are ROM-specific guides available with special features, including:

* arcade: Joystick layout and button actions

With the Arcade reference guides, you can quickly pull up which buttons map to which
actions within the game and have it drawn on the screen to match your own control
panel layout.

All guides can be viewed by loading the manual via manualkit's configured hotkey and
scrolling to the end of the manual (you can just go in reverse if you're on the first
page of the manual).  If the game has no manual, an image will be displayed saying
"No Manual".  However, you'll still be able to scroll forward to the reference guide.
