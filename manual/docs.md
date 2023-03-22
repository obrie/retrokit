# Documentation

Documentation is critical to a successful system build.  So, in addition to manuals and
reference sheets available per-game, *printable* documentation can also be built for your
system.  This documentation currently includes:

* Introduction to the system
* Game lists

In particular, game lists are useful if you want others to be able to look through which
games to play while someone is playing a game or controlling the system.  Think of it like
a karaoke playlist.

## Usage

To generate the documentation, you can use the following command(s):

```bash
bin/docs.sh build [/path/to/output_dir/]
bin/docs.sh build_intro [/path/to/output.pdf]
```

This will generate PDF files in the `docs/build` folder.  Two game lists are generated: one
sorted by name and one sorted by system.

These commands must be run on the system that has the games.  Additionally, it relies on
EmulationStation's gamelists being filled in (either by your favorite scraper or yourself).

## Example

Below is an example screenshot of a gamelist document that can be generated with this tool:

![Game List By Name](/manual/examples/docs/gamelist-by_name.png)

As you can see, game lists include several pieces of information:

* Name of the game
* System
* Number of players
* Genres

Your friends will often find it fun just to browse through your game list!
