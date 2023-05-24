# System configuration

In addition to general configuration settings for retrokit, there are also system-specific
configuration settings.  These are stored in 1 of 2 locations:

* `config/systems/settings-common.json`
* `config/systems/<system>/settings.json`

The `settings-common.json` provides a way to define default settings that are shared across
all system-specific setting files.

This documentation provides an overview of the different types of settings that
can be configured.

## Scraper

The `scraper` setting is used to configure how the system will be scraped.

Example:

```jsonc
{
  "scraper": {
    // The list of scraping modules to use (in order of priority)
    "sources": ["screenscraper"],

    // Whether to import titles for your games from the system's DAT file
    "import_dat_titles": true,

    // Additional arguments to include when calling Skyscraper
    "args": [],

    // Additional arguments to include when building the gamelist with Skyscraper
    "gamelist_args": ["--flags", ",skipexistingmarquees,skipexistingscreenshots,skipexistingvideos,skipexistingwheels"],
    "gamelist_include_base_args": true
  }
}
```

Typical recommendations:

* Just use Screenscraper unless you're working with mame/mess-based games
* Import DAT titles for all non-mame/mess-based games
* Skip processing media that already exists

## Game state

The `gamestate` setting is used to indicate where an emulator stores the state
of a game, such as save states.  This is used by retrokit for managing the
import, export, and vacuuming of game states.

These settings are stored under 2 properties: `retroarch` and the emulator
definition.  For example:

```jsonc
{

  "retroarch": {
    // Game state specific to libretro emulators
    "gamestate": [
      "{rom_dir}/{rom}.ldci",
      "{rom_dir}/{rom}.sav",
      "{rom_dir}/{rom}.srm",
      "{rom_dir}/{rom}.state"
    ]
  },
  "emulators": {
    "redream": {
      "default": true,
      // Game state specific to redream.  Filenames aren't predictable, so
      // we just match everything under the state directories.
      "gamestate": [
        "/opt/retropie/configs/dreamcast/redream/cache/*",
        "/opt/retropie/configs/dreamcast/redream/saves/*",
        "/opt/retropie/configs/dreamcast/redream/states/*",
        "/opt/retropie/configs/dreamcast/redream/vmu*.bin"
      ]
    },
    "lr-flycast": {
      "core_name": "flycast",
      "library_name": "Flycast"
      // Game state will be automatically set via the "retroarch" setting above
    }
  }
}
```

In the above example, you can see that there are a couple of ways to define
game state and the syntax can vary as well.

`gamestate` definitions support 2 template variables:

* `{rom_dir}` - The directory in which the game exists on the filesystem
* `{rom}` - The name of the game (minus any file extension)

Additionally, when specifying the path, you can use glob syntax, such as `*`,
to match more than 1 file.

## Mess Artwork

MAME (and, therefore, MESS) is able to emulate many systems beyond arcade
systems.  Some of these systems are LCD-based, such as the Game & Watch and
Tiger Electronics.  For these games, artwork is required in order to
player the game.

By default, this artwork is installed automatically by retrokit.  However,
there are multiple versions of the artwork that area available to install.
In order to customize this selection process, you can add the following
setting:

```json
{
  "mess": {
    "artwork": {
      "background_only": true
    }
  }
}
```

This configures retrokit to auto-select artwork based on just the presence
of the background images needed for the LCD system.  This provides the
highest performance available when compared to other, more complicated,
artwork.

## BIOS

Many systems require one or more BIOS files in order to run.  In order to
help automate the installation of these BIOS files, you can configure the
system settings with the information needed for how to source these files.

For example:

```jsonc
{
  "bios": {
    // Source base uRL
    "url": "$BIOS_URL/libretro/3DO Company, The - 3DO",

    // Where to install the BIOS files
    "dir": "$HOME/RetroPie/BIOS",
    "files": {
      // Target name : Source URL
      "3do_arcade_saot.bin": "{url}/3do_arcade_saot.bin",
      "panafz10.bin": "{url}/panafz10.bin"
    }
  }
}
```

The following systems have required and/or optional BIOS files:

* 3do
* atari5200
* atari7800
* atarijaguar
* atarilynx
* channelf
* coleco
* dreamcast
* gamegear
* gb
* gba
* gbc
* intellivision
* mastersystem
* megadrive
* nds
* neogeocd
* pce-cd
* pokemini
* psx
* saturn
* segacd
* supergrafx
* videopac

Note that BIOS files for `arcade` games are built into the non-merged zip
files for the game.

## Cheats

Many systems support the ability to enable cheat codes in order to unlock functionality
or change the behavior of the game.  These cheat codes often need to be sourced from an
external website and are not integrated directly within the emulator.

The following systems provide cheats built-in to the emulator:

* nds
* psp

All other systems that support cheats use libretro emulators.  The source for cheats
for these emulators are from the [libretro website](http://buildbot.libretro.com/assets/frontend/cheats.zip).

The libretro cheats archive provides a list of cheats, grouped by system name.  As a
result, we need to configure in retrokit which libretro system names to look at when
trying to find a cheat for a retropie system.

For example:

```json
{
  "cheats": {
    "names": [
      "Atari - 5200"
    ]
  }
}
```

In the above setting, you would be configuring the `atari5200` system to find
cheats for libretro emulators in the directed named "Atari - 5200" from the cheats
database.

The following systems have libretro emulators that are configured to support cheats:

* atari2600
* c64
* coleco
* dreamcast
* gamegear
* gb
* gba
* gbc
* mastersystem
* megadrive
* n64
* nes
* ngp
* ngpc
* saturn
* sega32x
* segacd
* sg-1000
* snes

In some cases, the `cheats` configuration setting may be added, but isn't supported
for any of the libretro emulators currently used by retrokit.

## Themes

For individual systems, `themes` define media used outside of EmulationStation and
the emulators themselves.  Currently, this includes:

* `launch_image` - The image to show after selecting a game and before the emulator is loaded

You can override the launch image for a system like so:

```json
{
  "themes": {
    "launch_image": "https://github.com/TMNTturtleguy/ComicBook-Theme-Launch-Images-for-Retropie/raw/master/16x9-Launching_ComicRip/mame/launching.png"
  }
}
```

By default, the launch image will be based on what's defined in `config/settings.json`.

## Overlays

When playing games on a 16:9 screen, you might notice that there are black bars primarily
on the left / right.  The reason for this is that most retro game systems were not designed
to be displayed on a widescreen display.  They were typically designed for a 4:3 aspect
ratio.  The black bars often leave much to be desired when setting up your own custom system.

This is where overlays come in.  For libretro emulators, you can set up your system so that
those black bezels are replaced with artwork for the game.  [The Bezel Project](https://github.com/thebezelproject)
is one group that's worked hard to build game-specific bezels for these systems.

To define overlays for an individual systems, you can configure it like so:

```jsonc
{
  "overlays": {
    // The default horizontal overlay to display if a game-specific one isn't found
    "default": "https://github.com/thebezelproject/bezelprojectSA-MAME/raw/master/retroarch/overlay/MAME-Horizontal.png",

    // The default vertical overlay to display if a game-specific one isn't found
    "vertical": "https://github.com/thebezelproject/bezelprojectSA-MAME/raw/master/retroarch/overlay/MAME-Vertical.png",

    // The list of github repos to discover bezels from (in priority order)
    "repos": [
      {
        "repo": "thebezelproject/bezelproject-MAME",
        "path": "retroarch/overlay/ArcadeBezels"
      },
      {
        "repo": "thebezelproject/bezelprojectSA-MAME",
        "path": "retroarch/overlay/ArcadeBezels"
      }
    ],

    // For systems that support Sinden lightgun integration, the position to place the
    // lightgun border.  Default is (0,0)
    "lightgun_border": {
      "offset_x": 0,
      "offset_y": 0
    }
  }
}
```

In retrokit, overlays are expected to be stored in Github.  The reason is primarily
because of the large availability of bezels through The Bezel Project.  You can
defined game-specific overlays from other websites as well by providing those
media paths in the [`data` file](/data) for the system.

If a game-specific overlay isn't found in the given repos, then retrokit will
automatically determine whether to use a horizontal or vertical overlay based on
the available metadata for the system.

For Sinden lightgun integration, a border will also be drawn on top of the selected
overlay based on the configuration settings in the system and the [retrokit settings](/manual/settings.md).

## romkit

In addition to all of the settings described so far, all of the settings for `romkit`
are also needed when setting up a new system configuration.  Those settings are added
side-by-side with the system-specific settings used elsewhere in retrokit.

See the [romkit](/manual/romkit.md) documentation for more information.

## Systems-specific configurations

### arcade

In most systems, there's little difference between emulators when it comes to which
buttons are used for specific controls in a game.  However, in the `arcade` system,
the difference can be significant.  Since retrokit uses Roslof's compatibility
spreadsheet to choose emulators based on the game, you can end up with completely
reversed controls if the chosen emulator for a game happens to change over time.

To help keep the controls consistent across all `arcade` emulators, the `controls`
setting can be configured to explicitly defined what layout you want to use.
retrokit will then use that information to translate the emulator's controls to
the layout you've defined.

For example, you can define your layout like so:

```json
{
  "controls": {
    "layout": [
      "b",
      "a",
      "y",
      "x",
      "r",
      "l",
      "r2",
      "l2",
      "r3",
      "l3"
    ]
  }
}
```

The default layouts for each emulator is shown below:

| Emulators                               | Layout                  |
|-----------------------------------------|-------------------------|
| lr-mame2003                             | b,y,x,a,l,r,l2,r2,l3,r3 |
| lr-mame2010 / lr-mame2015 / lr-mame2016 | a,b,x,y,l,r,l2,r2,l3,r3 |
| lr-mame / lr-mame2003-plus              | b,a,y,x,l,r,l2,r2,l3,r3 |
| lr-fbneo / advmame                      | b,a,y,x,r,l,r2,l2,r3,l3 |

As you can see, the controls you may be used to in a specific emulator
may change significantly when switching to another emulator.
