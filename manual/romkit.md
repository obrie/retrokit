# romkit

romkit is a tool for listing, filtering, organizing, converting, and installing games
from romsets.  Think of it like clrmamepro, but with the following functionality:

* CLI-based
* Provides both filtering and prioritization grouping (i.e. 1g1r)
* Compatible with all game systems available in retrokit
* Integrates with `metakit` for comprehensive metadata lookup
* Downloads, converts, and installs games from private archives
* Manages favorites and collections
* Provides a systems for organizing ROMs

## Overview

`romkit` is one of the core tools providing the foundation upon which retrokit is built.
It provides a way to parse romsets, filter their contents, and manage the files for
games using a single interface across all types of gaming systems.

## Dependencies

The minimum romkit dependencies are:

* lxml
* pycurl
* requests

Additionally, if you're going to be processing game files, you may need to have the
following system dependencies installed:

* mame-tools (chdman)
* p7zip-full (if working with 7z files)
* trrntzip (if you want standardized CRC values for your .zip files)
* nibtools (for converting .nib files to .g64 -- generally not needed)

To install the relevant Python / system dependencies:

```bash
# Install the minimum Python dependencies
romkit/setup.sh depends

# Install the dependencies that may be used for processing game files (chdman, 7z, trrntzip)
romkit/setup.sh optional_depends

# Install all required dependencies
romkit/setup.sh all_depends
```

To install `nibtools` via retrokit:

```bash
bin/setup.sh install c64/tools
```

To remove dependencies:

```bash
romkit/setup.sh remove
```

## Quick Start

`romkit` works out of the box without having to make any configuration changes to
retrokit.

To install romkit on your RetroPie system:

```bash
bin/setup.sh install romkit
```

To use the romkit CLI through retrokit:

```bash
bin/romkit.sh <action> <system> <options>

# List filtered ROMs for all systems
bin/romkit.sh list

# List filtered ROMs for specific system
bin/romkit.sh list n64

# Set verbose mode
bin/romkit.sh list n64 --log-level DEBUG

# Download/Install ROMs
bin/romkit.sh install <system>

# Re-build the ROM folder structure
bin/romkit.sh organize <system>

# Print which ROM files are no longer needed according to system settings
bin/romkit.sh vacuum <system>
```

Every system will, by default, list all games available in the DAT files that
are configured for each system.

To use romkit directly (without going through the `bin/romkit.sh` helper script):

```bash
python3 romkit/cli.py list path/to/settings.json
```

## High-Level Design

There are multiple concepts in romkit that are important to be familiar with.  They're
described below.

System Models:

* System - An individual game system
* ROMSet - A DAT file describing all of the games available for a system
* Machine - A single game (or one disc from a game)
* File - An individual rom file from the game
* Disk - An additional disk file required by the game (arcade systems only)
* Sample - An audio sample required by the game (arcade systems only)
* Playlist - The collection of discs required by a game
* Attribute - Metdata associated with a game

Processing:

* Rule - A logic condition being applied for filtering or sorting/prioritization purposes
* RuleSet - A collection of rules
* SortableSet - A collection of rules for the purposes of sorting/prioritization (buiding 1g1r sets)

Installing:

* Resource - A description for where a file is sourced from and where it should be installed
* Action - A conversion action to run after sourcing a file but before it's been installed
* Discovery - A way to discover URLs for romsets

## Attributes

The following types of attributes are currently supported for use in filtering
and sorting/prioritizing roms:

| Rule Name              | Metadata Source  | Description                                                               |
|------------------------|------------------|---------------------------------------------------------------------------|
| age_ratings            | age_rating       | Game age rating (ESRB, PEGI, or SS)                                       |
| bios                   | datfile          | Whether the machine is a BIOS                                             |
| buttons                | buttons          | Input button names (i.e. what each button does in the game)               |
| categories             | category         | Machine type categorization (e.g. Games, Applications, Utilities, etc.)   |
| collections            | config           | Assigned collections                                                      |
| comments               | datfile comments | Machine comments                                                          |
| controls               | controls         | Input control type requirements (e.g. lightgun, joy, etc.)                |
| descriptions           | name             | Machine descriptions (same as name except for arcade systems)             |
| developers             | developer        | Total number of flag groups in the name                                   |
| disc_titles            | name             | Machine disc title                                                        |
| emulator_compatibility | emulation        | Whether the assigned emulator is compatible with the assigned romset      |
| emulator_ratings       | emulation        | Emulator performance rating                                               |
| emulators              | emulation        | Total number of flag groups in the name                                   |
| favorites              | config           | Whether the machine is marked as a favorite                               |
| filesystem             | n/a              | Whether the machine is present on the filesystem                          |
| flag_groups            | name             | All Flags (text between parens) from the description                      |
| flag_groups_total      | name             | Total number of flag groups in the name                                   |
| flags                  | name             | Individual Flags (text between parens) from the description               |
| genres                 | genres           | Genre, as identified by the system or community                           |
| group_is_title         | group            | Whether the machine has the same title as the group                       |
| groups                 | group            | Groups of related titles not defined by a romset                          |
| is_parent              | datfile parent   | Whether the machine is a parent or clone                                  |
| languages              | languages        | Language(s) used by the game, assuming it can't be identified by the name |
| manual_exists          | manuals          | Whether the machine has a manual                                          |
| media                  | media            | Media associated with the machine, such as artwork                        |
| names                  | name             | Machine name                                                              |
| parent_disc_titles     | datfile parent   | Parent machine disc title                                                 |
| parent_names           | datfile parent   | Parent machine name                                                       |
| parent_titles          | datfile parent   | Parent machine title                                                      |
| titles                 | name             | Machine title                                                             |
| versions               | name             | Best-guess version number in the title                                    |
| peripherals            | peripherals      | Peripherals supported (e.g. multitap)                                     |
| players                | players          | Maximum number of players supported by the machine                        |
| publishers             | publisher        | Game publisher                                                            |
| ratings                | rating           | Community-determined rating of the game                                   |
| romsets                | config           | The machine's romset name                                                 |
| runnable               | datfile          | Whether the machine is runnable                                           |
| orientations           | screen           | Screen orientation                                                        |
| series                 | series           | The series the game belongs to                                            |
| systems                | config           | The machine's system name                                                 |
| tags                   | tags             | The machine's system name                                                 |
| years                  | year             | Year of the release                                                       |

## Configuration

`romkit` is configured via a json file that describes everything required for the
system being used.  Below is an example configuration at its most basic.

```jsonc
{
  "system": "vectrex",
  "metadata": {
    "path": "data/vectrex.json"
  },
  "romsets": {
    "nointro": {
      "resources": {
        "dat": {
          "source": "file://$RETROKIT_HOME/cache/nointro/GCE - Vectrex (Parent-Clone).dat"
        }
      }
    }
  }
}
```

You can then list the files in that DAT file like so:

```bash
$ RETROKIT_HOME=$PWD python3 lib/romkit/cli.py list test.json
{"system": "vectrex", "romset": "nointro", "name": "3D Crazy Coaster (USA)", "id": "da39a3ee5e6b4b0d3255bfef95601890afd80709", "disc": "3D Crazy Coaster", "title": "3D Crazy Coaster", "category": null, "path": null, "filesize": 0, "description": "3D Crazy Coaster (USA)", "comment": null, "is_bios": false, "runnable": true, "is_mechanical": false, "url": null, "favorite": false, "year": 1983, "developer": "GCE", "publisher": "GCE", "age_rating": null, "genres": ["Simulation"], "collections": [], "languages": [], "rating": 0.9, "players": 1, "emulator": null, "emulator_rating": null, "manual": {"languages": ["en"], "url": "http://vectrex.de/_static/2014/3D-Crazy_Coaster_Manual.pdf"}, "media": {}, "series": null, "orientation": "horizontal", "controls": [], "peripherals": [], "buttons": [], "tags": [], "group": {"name": "3D Crazy Coaster", "title": "3D Crazy Coaster"}}
{"system": "vectrex", "romset": "nointro", "name": "3D Mine Storm (USA)", "id": "da39a3ee5e6b4b0d3255bfef95601890afd80709", "disc": "3D Mine Storm", "title": "3D Mine Storm", "category": null, "path": null, "filesize": 0, "description": "3D Mine Storm (USA)", "comment": null, "is_bios": false, "runnable": true, "is_mechanical": false, "url": null, "favorite": false, "year": 1983, "developer": "GCE", "publisher": "GCE", "age_rating": "E", "genres": ["Shooter"], "collections": [], "languages": [], "rating": 0.75, "players": 2, "emulator": null, "emulator_rating": null, "manual": {"languages": ["en"], "url": "http://vectrex.de/_static/2014/3D-Mine_Storm_Manual.pdf"}, "media": {}, "series": null, "orientation": "horizontal", "controls": [], "peripherals": [], "buttons": [], "tags": [], "group": {"name": "3D Mine Storm", "title": "3D Mine Storm"}}
...
```

### `system`

The `system` setting is used to identify the name of the system that's being used.
This should match the naming scheme used by retrokit, which is based on RetroPie's
system names.

### `metadata`

The `metadata` setting is used for 2 main purposes:

* Configure where the system's metadata is stored (from metakit)
* Define metadata default overrides

For example:

```jsonc
{
  // ...
  "metadata": {
    "path": "$RETROKIT_HOME/data/vectrex.json",
    "defaults": {
      "emulation": {
        "rating": 0
      }
    }
  }
}
```

In the above example, we've done the following:

* Set the path to the system's metadata file
* Changed the default emulation rating to be 0 (metadata values will override this per-game)

### `attributes`

The `attributes` setting is used to change how certain attributes behave when
used by romkit.  Currently the following attributes support behavior overrides:

* manuals

For example:

```jsonc
{
  // ...
  "attributes": {
    "manuals": {
      "languages": [
        "en",
        "en-gb"
      ],
      "prioritize_region_languages": false
    }
  }
}
```

In this example, we've configured the `manuals` attribute to prioritize certain languages
and ignore the region defined in the game's name.

### `romsets`

The `romsets` setting is used to provide romkit with the databases used for looking
up the list of games available in the system.  You can define more than 1 romset
for systems that may be split into multiple databases.

#### Resources

Each romset is made up of 1 or more "resources".  A resource describes 3 important
things:

* Where is the resource sourced from?
* Where should the resource be installed to on the filesystem?
* What transformation should happen when the resource is installed?
* How can we cross-reference the resource if the name changes?

There are 5 types of resources that can be defined for romsets:

* dat (the database file)
* machine (the machine's file/package)
* playlist (an m3u for multiple machines)
* disk (arcade only)
* sample (arcade only)

All resources, except `dat`, are optional.  You only need to provide the other
resources (such as `machine`) if you intend on installing games from some
external archive.

Resources can be sourced from either the local file system or a remote url:

```jsonc
// Locally sourced
"dat": {
  "source": "file://$RETROKIT_HOME/cache/nointro/GCE - Vectrex (Parent-Clone).dat"
}

// Remotely sourced
"dat": {
  "source": "http://path/to/file.dat",
  "target": "$RETROKIT_HOME/tmp/vectrex/GCE - Vectrex (Parent-Clone).dat"
}
```

Oftentimes, the name of a game changes from year to year.  When that happens, we
need some way of easily knowing that the game's name has changed.  To help with
this, you can define an `xref` file.  This file uses the unique rom identifier
configured to the system and is created as a symlink so that if the name changes,
we can still use the rom identifier to discover the original name.

Below is an example:

```json
"machine": {
  "source": "{discovery_url}",
  "download": "$HOME/RetroPie/roms/dreamcast/.redump/{machine}.zip",
  "target": "$HOME/RetroPie/roms/dreamcast/.redump/{machine}.chd",
  "xref": "$HOME/RetroPie/roms/dreamcast/.redump/.xrefs/{machine_id}.chd",
  "install": {"action": "zip_to_chd"}
}
```

#### Install Actions

When installing a resource, you can perform an action on it in order to transform
it to the format that you'd like.  The default action is a simple "copy".  The
following actions are currently available:

| Action            | Description                                                |
|-------------------|------------------------------------------------------------|
| copy              | Copy file, as-is                                           |
| exodos_to_dat     | Convert an exodos XML file to a compatible dat file        |
| iso_to_cso        | Convert a PSP .iso file to .cso                            |
| playlist_to_m3u   | Generate an m3u file from a collection of discs for a game |
| seven_zip_extract | Extract one or more files from a .7z archive               |
| stub              | Create an empty file                                       |
| zip_extract       | Extract one or more files from a .zip archive              |
| zip_merge         | Merge files from one .zip archive into another             |
| zip_nibconv       | Convert between different Commodore disk formats           |
| zip_to_chd        | Convert .zip archive to .chd                               |
| zip_to_cso        | Convert .zip archive to .cso                               |

#### Examples

For example, consider the following Commodore 64 configuration:

```json
{
  "system": "c64",
  "romsets": {
    "nointro-carts": {
      "resources": {
        "dat": {
          "source": "file://$RETROKIT_HOME/tmp/No-Intro Love Pack (PC XML).zip",
          "target": "$RETROKIT_HOME/cache/nointro/Commodore - Commodore 64 (Parent-Clone).dat",
          "install": {"action": "zip_extract", "file": ".*/Commodore - Commodore 64 \\(Parent.*\\.dat"}
        }
      }
    },
    "nointro-tapes": {
      "resources": {
        "dat": {
          "source": "file://$RETROKIT_HOME/tmp/No-Intro Love Pack (PC XML).zip",
          "target": "$RETROKIT_HOME/cache/nointro/Commodore - Commodore 64 (Tapes) (Parent-Clone).dat",
          "install": {"action": "zip_extract", "file": ".*/Commodore - Commodore 64 \\(Tapes.*\\.dat"}
        }
      }
    },
    "nointro-pp": {
      "resources": {
        "dat": {
          "source": "file://$RETROKIT_HOME/tmp/No-Intro Love Pack (PC XML).zip",
          "target": "$RETROKIT_HOME/cache/nointro/Commodore - Commodore 64 (PP) (Parent-Clone).dat",
          "install": {"action": "zip_extract", "file": ".*/Commodore - Commodore 64 \\(PP.*\\.dat"}
        }
      }
    }
  }
}
```

This configuration:

* Defines 3 separate romsets that will be merged together in the romkit output
* Each romset's dat is sourced from a .zip archive on the local filesystem
* The romset dat is exacted from the archive and stored in specific folder

#### Discovery

When configuring romsets with machine/disk/sample resources, you may need
"discover" where those resources exist instead of having explicit urls for
them.  For example, consider the following:

```jsonc
{
  // ...
  "romsets": {
    "nointro": {
      // Discover files from the given provider that are under the URL `.../<machine>.zip`
      "discovery": {
        "type": "internetarchive",
        "urls": [
          "$ROMSET_DREAMCAST_REDUMP_URL"
        ],
        "match": "(?P<machine>[^/]+).zip"
      },
      "resources": {
        "dat": {
          "source": "$RETROKIT_HOME/cache/redump/Sega - Dreamcast.dat"
        },
        "machine": {
          // {discovery_url} will be the url based on the machine's name
          "source": "{discovery_url}",
          "download": "$HOME/RetroPie/roms/dreamcast/.redump/{machine}.zip",
          "target": "$HOME/RetroPie/roms/dreamcast/.redump/{machine}.chd",
          "xref": "$HOME/RetroPie/roms/dreamcast/.redump/.xrefs/{machine_id}.chd",
          "install": {"action": "zip_to_chd"}
        }
      },
      "auth": "internetarchive"
    }
  }
}
```

In the above example, we're looking up all of the files available in the remote
archive, matching them based on a regular expression, and then using the
`{discovery_url}` parameter to define the machine's source.

In addition, an additional authentication mechanism is used when downloading
from the remote archive.

Currently, the following discovery strategies are implemented:

* internetarchive

The following authentication strategies are implemented:

* internetarchive

#### Authentication

When resources are being downloaded from an external location, you may need to provide
some form of authentication alongside the HTTP requests being made.  To do so, you can
configure the `auth` property with a romset.

The following authenticiation strategies are implemented:

* internetarchive: Uses the cookies stored from the `ia` command-line tool

### `roms`

The `roms` setting is where most of the hard work is done.  This is where you'll be
setting up:

* Filters
* Prioritization (for 1g1r logic)
* Favorites
* Collections
* File organization

Each section is described below.

#### Identification

The `id` setting is used to tell romkit how to uniquely identify a game.  There are
two options here:

* `name`
* `crc`

Typically, `name` is used for MAME-like systems and `crc` is used for everything else.

The unique identifier here is used for many purposes in retrokit.  Most importantly,
in the context of romkit, it's often used for the `xref` path in a resource.  

#### Rules

Rules define the conditions required in order for a game to be included / excluded *or*
for sorting/prioritizing groups of games in order to build a 1G1R list.

Filtering rules are applied like so:

```jsonc
{
  // ...
  "roms": {
    "filters": {
      // Only select English titles
      "languages": [
        "en"
      ],
      // Don't select Board game / Casino games
      "!genres": [
        "Board game",
        "Casino"
      ]
    }
  }
}
```

Prioritization rules are applied like so:

```json
{
  "roms": {
    "priority": {
      "group_by": ["group", "disc_title"],
      // Order of rule names
      "order": ["flags"],
      // Actual rules
      "flags": [
        "USA",
        "World",
        "Europe"
      ]
    }
  }
}
```

The examples below are very basic.  romkit supports much more advanced filtering features
so that you can build the exact game list you want.  The examples below demonstrate the
different types of behavior you can add to rules.  These examples apply to rules used for
both filtering and prioritization.

```jsonc
// Disabled key (ignored by romkit)
"#flags": ["USA"]

// Disabled value (ignored by romkit)
"flags": ["#USA"]

// Inverts the condition (i.e. everything *except* these flags)
"!flags": ["USA"]

// Forces all matching games to be allowed, regardless of other rules
"+flags": ["USA"]

// Multiple rules tied to the same attribute
"flags/countries": ["USA"],
"flags/prototypes": ["Beta"]

// Union rules (useful if you want to add to a rule from multiple profiles)
"flags": ["USA"],
"flags|more": ["Europe"]

// The above is equivalent to:
"flags": ["USA", "Europe"]

// Rule transformation (typically used for priority rules)
"names.length": [10]

// Regular expression matching
"flags": ["/Europe", "/USA?"]
```

Additionally, prioritization rules support a few additional features that can be
useful:

```jsonc
// Sort machines in ascending order
"years": "ascending",

// Sort machines in descending order
"years": "descending"

// Sort machines according to a specific order (earlier matches are higher priority)
// Any value that's not matched is considered equivalent in terms of priority
"flags/countries": [
  "USA",
  "World",
  "Europe"
]

// Sort based on the total number of matches found in the list.  For example, a game
// with both "USA" *and* "Europe" flags is higher priority than a game with *just*
// a "USA" flag.
"flags.match_count": [
  "USA",
  "World",
  "Europe"
]
```

#### Filtering

The `filters` setting is used to remove games you don't want listed.  Filters are
implemented by utilizing rules.  See the section on Rules for more information.

Example filter configuration:

```jsonc
{
  "roms": {
    "filters": {
      // Remove games marked as incompatible
      "!emulator_compatibility": [false],
      // Remove games that don't work great
      "!emulator_ratings": [0, 1, 2, 3],
      // Only select games that are in English
      "languages": [
        "en"
      ]
    }
  }
}
```

#### Prioritization

The `priority` setting is used for choosing which game to use within a group of
clones.  Prioritization is implementing by utilizing rules.  See the section on
Rules for more information.

Example priority configuration:

```jsonc
{
  "roms": {
    "priority": {
      // Games are first grouped by their metakit `group` with a single game/playlist
      // selected.
      //
      // Games are then grouped by their `disc_title` so that only a single disc number
      // is chosen for multi-disc games
      "group_by": ["group", "disc_title"],

      // The order in which the priorities are determined
      "order": [
        "is_parent",
        "!flags/prototypes",
        "!flags.match_count/primary_countries",
        "names/alphabetical"
      ],

      // Choose the parent defined in the DAT
      "is_parent": [
        true
      ],

      // Prioritize non-prototype games (items matching earlier are lower priority)
      "!flags/prototypes": [
        "Pirate",
        "Proto",
        "Demo",
        "Alpha",
        "Beta",
        "Unl"
      ],

      // Prioritize games listing the matching countries
      "!flags.match_count/primary_countries": [
        "# Descending order (total count of number of primary countries in the flags)",
        "Europe",
        "USA",
        "Japan"
      ],

      // Prioritize games by their name
      "names/alphabetical": "ascending"
    }
  }
}
```

#### Favorites

The `favorites` setting provides a way to mark a game as being a favorite and include
that information in romkit's output.  This is useful when combined with a script that
defines your favorites in a frontend like EmulationStation.

`favorites` uses the same set of attribute rules that are used in the `filters` and
`priority` settings.

For example:

```json
{
  "roms": {
    "favorites": {
      "titles": [
        "/Bubble Bobble",
        "/Contra",
        "Excitebike",
        "Duck Hunt",
        "Ms. Pac-Man",
        "Pac-Man",
        "Popeye",
        "Rampage",
        "Paperboy",
        "/R.C. Pro-Am",
        "/Simpsons",
        "/Skate or Die",
        "/Super Mario Bros",
        "Tetris",
        "Winter Games",
        "World Games"
      ]
    }
  }
}
```

Example in the output:

```json
{"system": "nes", "romset": "nointro", "name": "Super Mario Bros. (World)", ..., "favorite": true, ...}
```

#### Collections

The `collections` setting provides a way to categorize games and include that information in
romkit's output.  This is useful when combined with a script that defines your collections
in a frontend like EmulationStation.  It's also useful in cases where you are using 3rd-party
profiles that defines various collections for you to pull into your game list.

Examples:

```json
{
  "roms": {
    "collections": {
      "Keyboard": {
        "filters": {
          "controls": ["keyboard"]
        }
      },
      "Lightguns": {
        "filters": {
          "controls": ["lightgun"]
        }
      },
      "Multitap": {
        "filters": {
          "peripherals": ["multitap"]
        }
      },
      "Trackball": {
        "filters": {
          "controls": ["trackball"],
          "!controls": ["lightgun"]
        }
      },
      "Manuals": {
        "filters": {
          "manual_exists": [true]
        }
      },
      "Multiplayer": {
        "filters": {
          "!players": [null, 1]
        }
      },
      "Kid-Friendly": {
        "filters": {
          "age_ratings": [
            "1",
            "3",
            "6",
            "7",
            "8",
            "9",
            "E",
            "EC",
            "KA"
          ]
        }
      }
    }
  }
}
```

As you can see, you use the same `filters` setting that you would typically use when
filtering your roms in general.  In fact, you can reference these collections when
filtering your own roms like so:

```json
{
  "roms": {
    "filters": {
      "collections": ["Keyboard"]
    },
    "collections": {
      "Keyboard": {
        "filters": {
          "controls": ["keyboard"]
        }
      }
    }
  }
}
```

By allowing you to reference collections, you can actually build out very complex
filtering configurations in individual collections, union them together in the
top-level `collections` filter and then apply a 1g1r prioritization sort method
to the results.  For example:

```json
{
  "roms": {
    "filters": {
      "collections": ["US Games", "Europe Games"]
    },
    "priority": {
      "group_by": ["group", "disc_title"],
      "order": ["flags"],
      "flags": [
        "USA",
        "Europe"
      ]
    },
    "collections": {
      "US Games": {
        "filters": {
          "flags": ["USA"]
        }
      },
      "Europe Games": {
        "filters": {
          "flags": ["Europe"]
        }
      }
    }
  }
}
```

In the above example, we're combining both US-based games and Europe-based games and
then prioritizing them.  There's a simpler way to write this configuration, but this
is just demonstrating the principle.

#### Organization

Once installed, romkit can organize your games into a directory structure based on
a set of filters.  For example, the below configuration installs all files from the
vectrex system to the `RetroPie/roms/vectrex` folder:

```json
{
  "roms": {
    "dirs": [
      {"path": "$HOME/RetroPie/roms/vectrex", "filters": {}}
    ],
    "files": {
      "machine": {"target": "{dir}/{machine_filename}"}
    }
  }
}
```

Suppose, however, that you wanted to categorize games by name.  You can do this like
so:

```json
{
  "roms": {
    "dirs": [
      {"path": "$HOME/RetroPie/roms/vectrex/0-9", "filters": {"names": ["/^[0-9]"]}},
      {"path": "$HOME/RetroPie/roms/vectrex/A-H", "filters": {"names": ["/^[a-h]"]}},
      {"path": "$HOME/RetroPie/roms/vectrex/I-P", "filters": {"names": ["/^[i-p]"]}},
      {"path": "$HOME/RetroPie/roms/vectrex/Q-Z", "filters": {"names": ["/^[q-z]"]}}
    ],
    "files": {
      "machine": {"target": "{dir}/{machine_filename}"}
    }
  }
}
```

As you can see, there are a lot of possible when it comes to organizing your games.

### `downloads`

When downloading games via your own private archives, you can set some limits
on how the download functionality behaves.

For example:

```json
{
  "downloads": {
    "concurrency": 2
  }
}
```

By default, romkit will use a concurrency of 5 when downloading from external sources.
If you want to adjust that concurrency, you can do so.

## Output

This section shows an example of what the output looks like for each command supported
by `romkit`.

### List

```bash
$ PROFILES=none bin/romkit.sh list vectrex | head -n 2
{"system": "vectrex", "romset": "nointro", "name": "3D Crazy Coaster (USA)", "id": "4601bde03875be01b670851ce509d1beb80adc00", "disc": "3D Crazy Coaster", "title": "3D Crazy Coaster", "category": null, "path": "/home/pi/RetroPie/roms/vectrex/.nointro/3D Crazy Coaster (USA).zip", "filesize": 8192, "description": "3D Crazy Coaster (USA)", "comment": null, "is_bios": false, "runnable": true, "is_mechanical": false, "url": "/3D%20Crazy%20Coaster%20%28USA%29.zip", "favorite": false, "year": 1983, "developer": "GCE", "publisher": "GCE", "age_rating": null, "genres": ["Simulation"], "collections": ["Manuals"], "languages": [], "rating": 0.9, "players": 1, "emulator": null, "emulator_rating": null, "manual": {"languages": ["en"], "url": "http://vectrex.de/_static/2014/3D-Crazy_Coaster_Manual.pdf"}, "media": {}, "series": null, "orientation": "horizontal", "controls": [], "peripherals": [], "buttons": [], "tags": [], "group": {"name": "3D Crazy Coaster", "title": "3D Crazy Coaster"}, "rom": {"name": "3D Crazy Coaster (USA).vec", "crc": "92709B11"}, "xref": {"path": "/home/pi/RetroPie/roms/vectrex/.nointro/.xrefs/4601bde03875be01b670851ce509d1beb80adc00.zip"}}
{"system": "vectrex", "romset": "nointro", "name": "3D Mine Storm (USA)", "id": "6e28f8f73def569f205148db38f01966e69ba680", "disc": "3D Mine Storm", "title": "3D Mine Storm", "category": null, "path": "/home/pi/RetroPie/roms/vectrex/.nointro/3D Mine Storm (USA).zip", "filesize": 8192, "description": "3D Mine Storm (USA)", "comment": null, "is_bios": false, "runnable": true, "is_mechanical": false, "url": "/3D%20Mine%20Storm%20%28USA%29.zip", "favorite": false, "year": 1983, "developer": "GCE", "publisher": "GCE", "age_rating": "E", "genres": ["Shooter"], "collections": ["Kid-Friendly", "Manuals", "Multiplayer"], "languages": [], "rating": 0.75, "players": 2, "emulator": null, "emulator_rating": null, "manual": {"languages": ["en"], "url": "http://vectrex.de/_static/2014/3D-Mine_Storm_Manual.pdf"}, "media": {}, "series": null, "orientation": "horizontal", "controls": [], "peripherals": [], "buttons": [], "tags": [], "group": {"name": "3D Mine Storm", "title": "3D Mine Storm"}, "rom": {"name": "3D Mine Storm (USA).vec", "crc": "B2313487"}, "xref": {"path": "/home/pi/RetroPie/roms/vectrex/.nointro/.xrefs/6e28f8f73def569f205148db38f01966e69ba680.zip"}}
```

### Vacuum

```bash
$ PROFILES=filter-none bin/romkit.sh vacuum vectrex
rm -rfv '/home/pi/RetroPie/roms/vectrex/.nointro/3D Crazy Coaster (USA).zip'
rm -rfv '/home/pi/RetroPie/roms/vectrex/.nointro/3D Mine Storm (USA).zip'
```

### Install

```bash
$ bin/romkit.sh install vectrex
2023-05-20 13:48:10,237 - [Armor..Attack (World)] Downloading Armor..Attack (World)
2023-05-20 13:48:12,391 - [Armor..Attack (World)] Installing from Armor..Attack (World)
2023-05-20 13:48:12,393 - [Bedlam (USA, Europe)] Downloading Bedlam (USA, Europe)
2023-05-20 13:48:14,101 - [Bedlam (USA, Europe)] Installing from Bedlam (USA, Europe)
2023-05-20 13:48:14,103 - [Berzerk (World)] Downloading Berzerk (World)
2023-05-20 13:48:15,890 - [Berzerk (World)] Installing from Berzerk (World)
...
2023-05-20 13:49:21,034 - [Armor..Attack (World)] Enabling in: /home/pi/RetroPie/roms/vectrex
2023-05-20 13:49:21,046 - [Bedlam (USA, Europe)] Enabling in: /home/pi/RetroPie/roms/vectrex
...
```

## Organization

```bash
$ bin/romkit.sh install vectrex
2023-05-20 13:49:21,034 - [Armor..Attack (World)] Enabling in: /home/pi/RetroPie/roms/vectrex
2023-05-20 13:49:21,046 - [Bedlam (USA, Europe)] Enabling in: /home/pi/RetroPie/roms/vectrex
...
```
