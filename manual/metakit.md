## Game Metadata

Game metadata comes from a variety of sources.  When possible, retrokit caches those
those sources instead of pulling from them directly.  An overview of metadata
and where it comes from is described below.

| System      | Metadata                 | In Git? | Source                                        |
| ----------- | ------------------------ | ------- | --------------------------------------------- |
| arcade      | Categories               | Yes     | https://www.progettosnaps.net/                |
| arcade      | Emulator compatibility   | Yes     | https://docs.google.com/spreadsheets/d/1Rq4shU1RUSdcc7cTVWeORMD-mcO6BwXwQ7TGw8f5_zw |
| arcade      | Languages                | Yes     | https://www.progettosnaps.net/                |
| arcade      | Ratings                  | Yes     | https://www.progettosnaps.net/                |
| atarijaguar | Emulator compatibility   | Yes     | https://retropie.org.uk/forum/topic/27999/calling-pi-4-atari-jaguar-fans |
| c64         | "Best Of" (C64 Dreams)   | Yes     | https://docs.google.com/spreadsheets/d/1r6kjP_qqLgBeUzXdDtIDXv1TvoysG_7u2Tj7auJsZw4 |
| dreamcast   | Parent/Clone info        | Yes     | https://github.com/unexpectedpanda/retool     |
| n64         | Emulator compatibility   | Yes     | https://docs.google.com/spreadsheets/d/1Rq4shU1RUSdcc7cTVWeORMD-mcO6BwXwQ7TGw8f5_zw |
| nds         | Parent/Clone info        | Yes     | https://github.com/unexpectedpanda/retool     |
| pc          | DAT                      | Yes     | exodos                                        |
| pc          | DOSBox Config            | Yes     | exodos                                        |
| pc          | Emulator compatibility   | Yes     | https://docs.google.com/spreadsheets/d/1Tx5k3F0_AO6w00WrXULMBSUTRhtLyIhHI8Wz8GuqLfQ/edit#gid=2000917190 |
| pce-cd      | Parent/Clone info        | Yes     | https://github.com/unexpectedpanda/retool     |
| psp         | Parent/Clone info        | Yes     | https://github.com/unexpectedpanda/retool     |
| psx         | Genres                   | Yes     | https://github.com/stenzek/duckstation/raw/master/data/resources/database/gamedb.json |
| psx         | Parent/Clone info        | Yes     | https://github.com/unexpectedpanda/retool     |
| saturn      | Parent/Clone info        | Yes     | https://github.com/unexpectedpanda/retool     |
| saturn      | Emulator compatibility   | Yes     | https://www.uoyabause.org/games               |
| segacd      | DOSBox Config            | Yes     | exodos                                        |
| segacd      | Parent/Clone info        | Yes     | https://github.com/unexpectedpanda/retool     |
| *           | No-Intro DATs            | Yes     | https://datomatic.no-intro.org/index.php?page=download |
| *           | Genre / Rating info      | Yes     | https://www.screenscraper.fr/                 |

If possible, the preference would always be that retrokit/romkit is pulling from
the source for all of the above metadata.  However, some sources either aren't in
a format that can be parsed (e.g. they're a forum post), don't allow direct
downloads (e.g. dat-o-matic), or require an excessively large download to access
a small file (e.g. pc dosbox configurations).

### Clone info

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
it easier to work with, the same general rules are applied to the custom clonelists generated for
Redump DAT files.
