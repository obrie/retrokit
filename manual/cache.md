# Cache

The retrokit cache is a way of keeping resources local to this repository and avoiding
a dependency on external websites when either (a) you're not connected to the
internet or (b) the external websites have reliability issues.  Over time, the
cache will be re-synced with the external sources to ensure that retrokit doesn't
fall too outdated.

## Resources

The following types of resources are stored in the cache:

* exodos configuration files and XML database
* FinalBurn Neo arcade database
* No-Intro databases
* Redump databases
* Screenscraper textual data

Almost everything in the cache is managed by [metakit](/manual/metakit.md).  Only
the following are not:

* exodos configuration files

## External cache

In addition to the local cache here, an external cache is also used in github for
storing large files, such as compiled binaries.  retrokit cached compiled binaries
in order to improve the speed at which emulators are set up.  Compiled binaries
are provided for the following emulators:

* actionmax
* advmame-joy (improves input joystick handling for advmame)
* lr-mame0222
* lr-mame0244
* lr-mame2016-lightgun (adds sinden lightgun support)
* lr-swanstation
* lr-yabasanshiro

In addition, the following types of resources are also stored in github:

* mame cheats
* mame tools
* splashscreen videos

You can find all large files stored in github here: https://github.com/obrie/retrokit/releases/tag/latest

For context, the reason we store large files in a tagged release on github is that it's
the only free solution for large files that can be distributed easily.

## Temporary files

The last type of data that's cached when using retrokit is anything that only needs to
be calculated once but doesn't need to be stored in git.  Those files are stored under
the `tmp/` directory.  This folder contains many different artifacts using by setup scripts,
including:

* thebezelproject repo databases
* romkit list cache per system
* retropie images when creating new hardwarebuilds
* romkit discovery data

## Usage

To work with the cache, the following commands are available:

```bash
# Delete all system-specific temporary data
bin/cache.sh delete <system|all>

# Compiles a binary for the given retropie package
bin/cache.sh build_emulator_binaries <package|all>

# Uploads the compiled binary for the given retropie package
bin/cache.sh sync_emulator_binaries <package|all>
```
