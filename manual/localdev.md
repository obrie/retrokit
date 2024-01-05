# Local Development

This document describes everything you might need to know in terms of doing
local development of retrokit.

## General Maintenance

There's a certain amount of upkeep required for metadata that's used in retrokit.
Over time, new rom database files are released, new metadata becomes available,
new manuals are discovered, etc. and those all need to be tracked in retrokit so
that they can be used.

### Metadata

To update DAT files, scrape new games, and update metadata:

```sh
bin/metakit.sh update
```

To update DAT files from no-intro, you must first download the daily pack and store it
at `tmp/No-Intro Love Pack (PC XML).zip`.  To download the daily pack:

* Navigate to https://datomatic.no-intro.org/index.php?page=download&op=daily&s=64
* Select "P/C XML"
* Selet *only* the "Main" set

Once you download the file, you can run `bin/metakit.sh update_dates` for all of the
no-intro systems.

### Manuals

To find new manuals:

```sh
bin/metakit.sh find_manuals
```

Typically this is done on both a quarterly basis and when dat files are updated for a system
(for any new games that have been added since the last time they were cached in this repo).

## Systems Maintenance

### c64

When a new version of C64 Dreams is released, the following commands should be run
in order to synchronize the metadata:

```sh
bin/setup.sh install admin/c64-retroarch
```

### pc

When a new version of dosbox-staging is released, the following commands should be run in
order to synchronize the metadata:

```
bin/setup.sh install admin/pc-mapperfiles
```
