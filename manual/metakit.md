# metakit

[metakit](/lib/metakit/) is a tool used to create a unified definition for game metadata
in all systems supported by retrokit.  Since metadata is pulled from a variety of sources,
it's important to define a standard schema so that all downstream tools (like romkit) can
use that metadata without having to worry about what system it's dealing with.

## Design

`metakit` is designed with a few goals in mind:

* Metadata for a game and all of its clones are grouped together
* As much metadata as possible is pulled from external sources (rather than managed manually)
* Metadata files are validated, maintained, and updated in an automated fashion
* All changes to metadata groups are reflected within retrokit

These goals are intended to help ensure that this data is high-quality and can be
kept up-to-date as system DAT files are updated.

## Usage

```bash
# Downloads any external metadata that hasn't already been downloaded (this will not update)
bin/metakit.sh cache_external_data <system>

# Reformats the system metadata file, keeping the data clean
bin/metakit.sh format <system>

# Removes unneeded data from the metadata and scraper files (e.g. data for games that no longer exist)
bin/metakit.sh vacuum <system>

# Forces any external data used by the system to be re-downloaded
bin/metakit.sh recache_external_data <system>

# Forces all scraped metadata to be refreshed from the source
bin/metakit.sh rescrape <system>

# Forces machines that have incomplete scrape metadata to be refreshed from the source
bin/metakit.sh scrape_incomplete <system>

# Forces machines that have were never found in the scraper sources
bin/metakit.sh scrape_missing <system>

# Brings all romset dats up-to-date
bin/metakit.sh update_dats <system>

# Migrates groups to their current names as defined by the system's DAT
# files and the priority settings defined in the metakit configuraiton
bin/metakit.sh update_groups <system>

# Update the content of the database based on internal/external data
bin/metakit.sh update_metadata <system>

# Runs the following (in order):
# * update_dats
# * update_groups
# * vacuum
# * recache_external_data
# * scrape
# * update_metadata
bin/metakit.sh update <system>

# Validate the content of the system's database
bin/metakit.sh validate <system>

# Validates that machines are mapped properly to names in each romset's discovery data.
# That is, this ensures that the machine is found in any external archives configured
# for a system (based on either the machine's name or its alternates).
bin/metakit.sh validate_discovery <system>
```

## Supported metadata

The following types of metadata are currently supported.

### Age Rating

The maturity rating for the game.

Property: `age_rating`

Systems:

* all

Sources:

* [Screenscraper](https://www.screenscraper.fr/)
* [Progretto Snaps](https://www.progettosnaps.net/)

### Alternate Names

Other names the game may be referred to as.  This can be useful if an archive
source is different from the latest DAT file for a system.

Property: `alternates`

Systems:

* all

Sources:

* User-defined

### Buttons

The action associated with each button on the controller.

Property: `buttons`

Systems:

* arcade

Sources:

* https://github.com/Texacate/Visual-RetroPie-Control-Maps

### Category

The type of rom (e.g. game, tool, etc.).

Property: `category`

Systems:

* All cd-based systems (via redump)

Sources:

* Redump DAT files

### Controls

The types of controllers used (e.g. lightgun, joy, etc.).

Property: `controls`

Systems:

* arcade
* lightgun-supported systems

Sources:

* MAME
* Sinden Lightgun compatiblity spreadsheet

### Developer

The name of the company that developed the game.

Property: `developer`

Systems:

* all

Sources:

* MAME
* [Screenscraper](https://www.screenscraper.fr/)

### Emulation

The preferred emulator and compatibility rating.

Property: `emulation`

Systems:

* arcade
* atari5200
* atarijaguar
* dreamcast
* n64
* nds
* psp
* psx
* saturn

Sources:

* [Roslof compatibility](https://docs.google.com/spreadsheets/d/1Rq4shU1RUSdcc7cTVWeORMD-mcO6BwXwQ7TGw8f5_zw)
* [Yabause](https://www.uoyabause.org/games)
* [RetroPie Forums](https://retropie.org.uk/forum/topic/27999/calling-pi-4-atari-jaguar-fans)

### Genres

The genres associated with the game.

Property: `genres`

Systems:

* all

Sources:

* [Progretto Snaps](https://www.progettosnaps.net/)
* [Duckstation](https://github.com/stenzek/duckstation/raw/master/data/resources/database/gamedb.json)
* [Screenscraper](https://www.screenscraper.fr/)

### Languages

The languages used within the game.

Property: `languages`

Systems:

* arcade

Sources:

* [Progretto Snaps](https://www.progettosnaps.net/)

### Manuals

Manuals available for the game.

Property: `manuals`

Systems:

* all

Sources:

* Various

### Mechanical

Whether the game requires mechanical features.

Property: `mechanical`

Systems:

* arcade
* gb

Sources:

* MAME

### Media

Additional media used for the game, such as: artwork, overlay, etc.

Property: `media`

Systems:

* all

Sources:

* [Progretto Snaps](https://www.progettosnaps.net/)

### Merge

Additional game titles to mark as clones when not specified explicitly in the
system's DAT files.

Property: `merge`

Systems:

* all

Sources:

* [retool](https://github.com/unexpectedpanda/retool)

There are important differences between what's considered the parent and what's considered the
clone between different systems.

No-Intro DAT files generally sort games based on the rules laid out [here](https://forum.no-intro.org/viewtopic.php?p=9503&sid=7c1efa5d868e8dd0d0836f033691563a#p9503):

> 0. Final/Complete > Proto/Beta/Demo
> 1. Games containing En language > Other languages
> 2. World > Continent/Multi Country > Country
> 3. Old "main" console regions (EUR/USA/JPN) > Other countries (so i.e. Japan > Spain)
> 4. Country with earlier dump available
> 5. Highest revision

On the other hand, Redump DAT files are sorted chronologically based on the order in which they
were dumped.  Additionally, Redump does not provide clone metadata for its ROMs.

In order to (a) provide some consistency, (b) provide some stability in the metadata, and (c) make
it easier to work with, the same general rules are applied to the merge groups generated from
Redump DAT files.

### Peripherals

System peripherals supported, such as `link_cable`, `multitap`, etc.

Property: `peripherals`

Systems:

* all

Sources:

* [Black Falcon Games](https://blackfalcongames.net/?p=155)
* [Duckstation](https://github.com/stenzek/duckstation/raw/master/data/resources/database/gamedb.json)
* [Nintendo Wiki](https://nintendo.fandom.com/)
* [Sega Retro](https://segaretro.org/)

### Players

Maximum number of players supported.

Property: `players`

Systems:

* all

Sources:

* [Screenscraper](https://www.screenscraper.fr/)

### Publisher

The company that published the game.

Property: `publisher`

Systems:

* all

Sources:

* [Screenscraper](https://www.screenscraper.fr/)

### Rating

Community-based rating.

Property: `rating`

Systems:

* all

Sources:

* [Screenscraper](https://www.screenscraper.fr/)

### Screen

Details about the screen (e.g. orientation).

Property: `screen`

Systems:

* arcade
* wonderswan
* wonderswancolor

Sources:

* MAME

### Series

A series name to associate multiple games together.

Property: `series`

Systems:

* arcade

Sources:

* [Progretto Snaps](https://www.progettosnaps.net/)

### Tags

Custom, user-defined tags.

Property: `tags`

Systems:

* all

Sources:

* [C64 Dreams](https://docs.google.com/spreadsheets/d/1r6kjP_qqLgBeUzXdDtIDXv1TvoysG_7u2Tj7auJsZw4)
* [Video Game Kraken](http://videogamekraken.com/list-of-english-friendly-wonderswan-games)

### Year

Release year.

Property: `year`

Systems:

* all

Sources:

* MAME
* [Screenscraper](https://www.screenscraper.fr/)
