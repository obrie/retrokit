# manualkit

manualkit is a Python application that can display PDFs on the screen based on either the game
being viewed in EmulationStation or the game being played.  Features of manualkit include:

* Automatic integration with Retroarch controls via `devicekit` so you can use your joystick to control manualkit
* Automatically pause the current game you're playing when displaying manuals
* Display manuals over any existing content, including both EmulationStation and any emulator
* High-performance navigation of PDFs including the use of turbo mode during long navigation
* Zoom controls, especially useful with small handheld devices or small text
* Complete control of inputs when displaying manuals (to prevent emulators from interpreting inputs)
* Integration with EmulationStation lifecycle hooks to determine which game is being viewed
* High-performance loading / control of manualkit using a long-lived server
* Supplementary PDF support for use with system/game reference sheets
* Persistence of location in a manual when toggling display

## Goals

For many retro gaming systems, manuals provided a treasure chest of information for how to
play a game.  It's frustrating to have to spend time looking for manuals online when you
stumble upon a new game that you want to play.  Even then, you have to have a separate device
to look through the manual while you're playing -- not convenient when all you have is a
handheld device.

The goal of manualkit is to provide instant access to game manuals, whether from within a game
or from your emulator launcher (i.e. EmulationStation).

## Configuration

`manualkit` is configured via the [`manualkit.cfg`](/config/manualkit/manualkit.cfg).
For full details on the various configuration options to choose from, you can reference
that file.

By default, the following controls are used when toggle:

| Control  | Keyboard / Frontend | Keyboard / Game | Controller / Frontend | Controller / Game |
| -------- | ------------------- | --------------- | --------------------- | ----------------- |
| Toggle   | m                   | Up              | L2                    | Up                |
| Hotkey   | None                | Select (Space)  | None                  | Select            |

When a manual is being displayed, the following controls are used:

| Control  | Keyboard  | Controller    |
| -------- | --------- | ------------- |
| Next     | Page Down | Right Trigger |
| Prev     | Page Up   | Left Trigger  |
| Zoom In  | =         | X             |
| Zoom Out | +         | Y             |
| Up       | Up        | Up            |
| Down     | Down      | Down          |
| Left     | Left      | Left          |
| Right    | Right     | Right         |

Below is an example configuration:

```ini
[keyboard]
retroarch = false
toggle_frontend = m
next = pagedown
prev = pageup
zoom_in = equals
zoom_out = minus

[profile_frontend]

suspend = false
hotkey_enable = false

[profile_emulator]

suspend = true
hotkey_enable = true
```

## Integration

In order to run `manualkit`, it must be launched when the system starts.  In order to do this,
`manualkit` hooks into the `autostart.sh` script.  You can see these scripts [here](/lib/manualkit/autostart/).
Upon startup, `manualkit` will run a long-lived Python process.  This process uses a FIFO file
or providing communication between events that occur on the system and the `manualkit` process.

`manualkit` is designed this way for one primary reason: It avoids the startup overhead of having to
run the Python process anytime a manual is displayed.  This means we can quickly notify the
process of a new manual to activate when scrolling through game lists without impacting the
performance of the system.

In addition to being run on startup, `manualkit` must integrate into one of the following
in order to know when to load a manual or a new game:

* EmulationStation hooks
* Runcommand hooks

EmulationStation hooks are preferred for several reasons:

* It allows for the use of manualkit within EmulationStation by utilizing `system-select` and `game-select` hooks
* It allows integration with EmulationStation's controller autoconfig lifecycle to know when to reload device controls
* It provides hooks for when a game is started / terminated

If you're not running EmulationStation or, for some reason, you don't want `manualkit` using these
hooks, then you can still integrate with `runcommand`'s onstart/onend scripts.  This will still
allow you to bring up manuals while playing the game.

It's possible to integrate `manualkit` with other frontends, but there's no built-in support for it.

## Dependencies

`manualkit` has the following dependencies:

* devicekit
* PyMuPDF
* psutil

Due to version requirements and what's available on the current release of Raspbian,
mupdf must be built from source.  To install the required dependencies, you can run
the following:

```bash
manualkit/setup.sh depends
```

Note that `devicekit` must be present in the same parent directory as `manualkit`.

To remove dependencies:

```bash
manualkit/setup.sh remove
```

## Usage

`manualkit` must be run as `root` using `sudo` in order for it to have the necessary permissions to
draw on top of the screen.

```bash
# Show a specific manual
sudo python3 manualkit/cli.py --pdf /path/to/game.pdf

# Equivalent to the above command
sudo python3 manualkit/cli.py /opt/retropie/configs/all/manualkit.cfg --pdf /path/to/game.pdf --profile frontend --server false

# Show a manual with a supplementary reference PDF
sudo python3 manualkit/cli.py --pdf /path/to/game.pdf --supplementary-pdf /path/to/supplementary.pdf

# Use an explicit configuration and start manualkit with the emulator profile (meaning an emulator is running)
sudo python3 manualkit/cli.py --pdf /path/to/game.pdf --profile emulator
```

In most cases, the preferred way to run `manualkit` is as a server.  In this mode, `manualkit` can switch
which PDF it's configured to use rather than terminating and re-running `manualkit` each time a new game
is selected.  This is particularly useful in cases where you're scrolling through EmulationStation.

When `manualkit` runs in server mode, it uses a Linux FIFO file to enable communication between clients
and the server.  This type of API is used in order to keep the design as simple as possible.

Example usage:

```bash
# Start server
sudo python3 manualkit/cli.py /path/to/manualkit.cfg --server --profile frontend --track-pid $PPID

# Hide manualkit, load a new PDF, and reconfigure it to use the emulator profile
echo \
  'hide'$'\n' \
  'reset_display'$'\n' \
  'load'$'\t'"$rom_manual_file"$'\t'"$rom_reference_file"$'\t''true'$'\n' \
  'set_profile'$'\t''emulator' > /opt/retropie/configs/all/manualkit.fifo
```

The following server commands are available:

* `hide` - Hides the manual if it's currently being displayed (or does nothing)
* `reset_display` - Resets the connected display, to be re-opened the next time we attempt to show a PDF
* `load` - Loads a new PDF / supplementary PDF
* `set_profile` - Sets the input profile to use (frontend / emulator)
* `reload_devices` - Reloads the configuration used for all input devices

Examples:

```bash
echo 'hide' > /path/to/manualkit.fifi

echo 'reset_display' > /path/to/manualkit.fifi

# Note that the last argument is whether to pre-render the first page of the manual
echo 'load'$'\t'"/path/to/manual.pdf"$'\t'"/path/to/reference.pdf"$'\t''true' > /path/to/manualkit.fifi

echo 'set_profile'$'\t''emulator' > /path/to/manualkit.fifi

echo 'reload_devices' > /path/to/manualkit.fifi
```

## Manuals

There are over 18,000 manuals that have been hand-sourced over 2 years for this project.  They
come from a variety of websites which are all defined in each system's data file.  All manuals
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

```bash
PROFILES=manualkit-original bin/manualkit.sh remote_sync_system_manuals <system>
PROFILES=manualkit-compressed bin/manualkit.sh remote_sync_system_manuals <system>
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

```jsonc
{
  "manuals": {
    "archive": {
      "url": "https://archive.org/download/romkit-manualkit/{system}/original.zip/{parent_title} ({languages}).pdf",
      "processed": false
    },
    // ...
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

The logic for determining which manual to use for a specific game is largely based on language
preference for the user, *not* the country identifiers in the game filename.  The relevant
retrokit configuration is:

```jsonc
{
  "metadata": {
    "manuals": {
      // Allowlist of languages to pick for manuals.  Manuals in other langauges will never
      // be selected.
      "languages": [
        "en",
        "en-gb"
      ],

      // Prioritize languages according to the game name and the languages selected above
      // rather than *just* the order in which they're defined
      "prioritize_region_languages": false,

      // Only use languages associated with the region defined in the game name?
      "only_region_languages": false
    }
  },
  // ...
}
```

By default, retrokit will prefer languages based on the region of the game being installed.

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

* System features available (e.g. cheats, netplay, etc.)
* Keyboard controls
* Hotkey configurations
* Game-specific controller overrides

The guides are dynamically generated from your current configuration in RetroArch
and additional system-specific configurations for:
