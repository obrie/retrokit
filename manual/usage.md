# Usage

This page provides basic examples for how to use the various CLI tools available
under the [`bin/`](/bin) folder.

## sd

The `sd` script provides utilities for creating, backing up, and restoring SD cards.
It's intended to be used in a linux environment and has only been tested under Ubuntu.

```bash
# Create new SD card with RetroPie on it
bin/sd.sh create /path/to/device

# Back up SD card
bin/sd.sh backup /path/to/device /path/to/backup/folder

# Restore SD card
bin/sd.sh restore /path/to/device /path/to/backup/folder

# RSync files from the retropie partition to another directory
# (recommend sudo for long-running ops)
sudo bin/sd.sh sync_full /path/to/mounted_retropie_source /path/to/retropie_target

# RSync media files only from the retropie partition to another directory
# (recommend sudo for long-running ops)
sudo bin/sd.sh sync_media /path/to/mounted_retropie_source /path/to/retropie_target
```

## setup

The `setup` script is your primary interface to retrokit.  It's used to run commands
for managing the various setup modules available in retrokit.

In general, all setup modules implement one or more of the following actions:

* depends - Install dependencies
* build - Build any required binaries for the service being installed
* configure - Set up configurations
* clean - Clean up any unneeded files left behind
* restore - Restore configurations to their original value
* remove - Remove any binaries / files installed from the `build` / `depends` actions
* vacuum - Remove any configuration files no longer needed (due to games being removed)

Additionally, the following meta-actions are implemented for all setup modules.  These
actions simply call several of the above actions.

* install - Calls depends, build, configure, clean
* update - Calls install with `FORCE_UPDATE=true`
* uninstall - Calls restore, remove
* reinstall - Calls uninstall, install

Example usage of the `setup.sh` script:

```bash
bin/setup.sh <action> <module> <args>

# Install all setup modules
bin/setup.sh install

# Install specific setup module
bin/setup.sh install splashscreen

# Install a range of setup modules (from splashscreen onward)
bin/setup.sh install splashscreen~

# Install a range of setup modules (based on order in config/settings.json)
bin/setup.sh install splashscreen~runcommand

# Install multiple specific setup  modules
bin/setup.sh install splashscreen,themes

# Install all system-specific setup modules for all systems
bin/setup.sh install system

# Install all system-specific setup modules for single system
bin/setup.sh install system n64

# Install all rom-specific setup modules for single system
bin/setup.sh install system-roms n64

# Install specific rom setup module for all systems
bin/setup.sh install system-roms-download

# Uninstall all setup modules
bin/setup.sh uninstall system

# Uninstall specific setup module
bin/setup.sh uninstall splashscreen

# Run specific function in a setup module
bin/setup.sh configure system-retroarch n64

# Add (very) verbose output
DEBUG=true bin/setup.sh install splashscreen
```

## update

The `update` script provides a way to update various parts of your system in a
clean and consistent way.

```bash
# Update the OS (apt dist-upgrade)
bin/update.sh system

# Update RetroPie-Setup and its installed packages
bin/update.sh retropie

# Update just RetroPie-Setup
bin/update.sh retropie_setup

# Update all installed RetroPie packages
bin/update.sh retropie_packages

# Update a specific RetroPie package
bin/update.sh retropie_packages lr-fbneo

# Update retrokit and its installed profiles
bin/update.sh retrokit

# Update just retrokit
bin/update.sh retrokit_setup

# Update all installed retrokit profiles
bin/update.sh retrokit_profiles

# Update emulator configurations overridden by retrokit.  This is intended
# to be run after updating your emulators since it will re-run configurations
# based on the latest defaults provided by RetroPie.
# 
# If this isn't run, then any changes to RetroPie defaults will *not* be
# picked up.
bin/update.sh emulator_configs
```

## docs

The `docs` script is used to generate printable documentation for your system.
For more information about this, see the [docs](docs.md) manual.

```bash
# Builds the intro and gamelist PDFs to the given output directory
bin/docs.sh build [/path/to/output_dir/]

# Builds the 1-page intro flyer to the given path
bin/docs.sh build_intro [/path/to/output.pdf]

# Builds a PDF with your system's gamelists using the given columns, sorted by system
bin/docs.sh build_gamelist '["system", "name", "players", "genres"]' /path/to/output.pdf

# Builds a PDF with your system's gamelists using the given columns, sorted by game name
bin/docs.sh build_gamelist '["name", "system", "players", "genres"]' /path/to/output.pdf
```

## image

The `image` script is used to create static images of RetroPie installed with retrokit.
It uses the [image-base](/profiles/image-base) profile, which includes:

* Basic textual content scraping from skyscraper
* Full gamelists (no actual games)
* Lightgun configurations
* Base version of all setup scripts installed

This image can be used as a starting point for your new hardware setup or for customizing
retrokit with additional profiles.

```bash
# Runs the initialization, update, install, cleanup, and export process
bin/image.sh create

# Equivalent to the above command.  These additional arguments can be provided
# to any of the command listed.
bin/image.sh create dist=buster platform=rpi4_400 retropie_version=4.8 profiles=image-base

# Downloads the RetroPie image and mounts the image
bin/image.sh init

# Initializes the retrokit environment
bin/image.sh init_system

# Updates the system (dist-upgrade)
bin/image.sh 'update system'

# Updates the RetroPie-Setup repository
bin/image.sh 'update retropie'

# Installs all of the configured retrokit setup modules
bin/image.sh 'setup install'

# Removes all stubbed-out game images left behind during setup
bin/image.sh cleanup_roms

# Removes any configurations with sensitive information used during setup
bin/image.sh cleanup_configs

# Cleans up any temporary files left behind during setup
bin/image.sh cleanup_tmp

# Exports the filesystem to a new image
bin/image.sh export_image

# Fixes the kernel configuration to reflect PARTUUID changes made by retropie
bin/image.sh fix_img

# Compresses the exported image
bin/image.sh compress_img
```

## vacuum

The `vacuum` script is responsible for removing any files that are no longer needed.
How does this happen?  If a game is installed, then many files might get created for
that game on the filesystem:

* Configurations
* Manuals
* Media
* Game state

If you decide you no longer want that game on your system, then you have to know all
of the files that may have gotten installed for that game and are also no longer
needed.  This is the concept behind a `vacuum`: look for game files that are no longer
needed given the current filters applied for a system.

**Note** that `vacuum` will never delete files *except* when running the `media_cache`
action, which uses Skyscraper's internal vacuum functionality.  Instead, the `vacuum.sh`
script will output the required shell comands to delete the necessary files.  This
gives you a chance to review what's being deleted *before* it's deleted.

```bash
# Vacuum installation and game state
bin/vacuum.sh all | bash

# Vacuum roms, manuals, media, overlays, and artwork
bin/vacuum.sh installation | bash

# Vacuum ROM files
bin/vacuum.sh roms | bash

# Vacuum manuals
bin/vacuum.sh manuals | bash

# Vacuum scraper cache (deletion is not reviewable)
bin/vacuum.sh media_cache

# Vacuum scraped media
bin/vacuum.sh media | bash

# Vacuum RetroArch overlays
bin/vacuum.sh overlays | bash

# Vacuum game state (e.g. save states)
bin/vacuum.sh gamestate | bash

# Vacuum mess artwork
bin/vacuum.sh mess_artwork | bash
```

## migrate

The `migrate` script can be used to migrate your existing game-specific files
based on newer system DAT files.

Over time, the names for games change based on the database files released by
groups like no-intro and redump.  When retrokit sync with these database files,
it's important that your system reflect those updates if you intend on
continuing to use retrokit.

You then have 2 options:

* Use retrokit for the initial setup of your system and then maintain it manually
* Use retrokit for continued maintenance and use the `migrate.sh` script to keep
  games in sync

To run the migration, you must run it *after* updating the `retrokit` git repo,
but *before* running any other `retrokit` scripts.  By default, the migration
will attempt to fix renamed games in the following places:

* EmulationStation media
* Emulationstation collections
* EmulationStation game lists
* Skyscraper database
* RetroArch configuration files
* Any filenames under your `$HOME/RetroPie/roms` directory

It does this by performing both filename and content matching.  Once a rename
is identified, it will print out the necessary shell command.  `migrate.sh` will
**not** automatically execute any renames.  The necessary commands will be printed
for you to review and then *you* must execute the commands yourself.

Example usage:

```bash
# Migrate all systems
bin/migrate.sh

# Migrate a specific system
bin/migrate.sh nes
```

## cache

The `cache` script is used for managing various cached parts of retrokit, including:

* Temporary files under `tmp/`
* Compiled emulator binaries stored in github releases

Example usage:

```bash
# Delete all system-specific temporary data
bin/cache.sh delete <system|all>

# Compiles a binary for the given retropie package
bin/cache.sh build_emulator_binaries <package|all>

# Uploads the compiled binary for the given retropie package
bin/cache.sh sync_emulator_binaries <package|all>
```

## Common commands

There are a set of commands you might find yourself most commonly running.
Those are shown below.

```bash
# Update RetroPie and configs
bin/update.sh retropie
bin/update.sh emulator_configs

# Update system
bin/update.sh system

# Update retrokit
bin/update.sh retrokit

# Install/Update system
bin/setup.sh install <system>

# Update custom scriptmodules
bin/setup.sh install retropie-scriptmodules

# Re-do everything
bin/update.sh system
bin/update.sh retropie
bin/update.sh emulator_configs
bin/setup.sh install

# Re-create reference documentation
bin/setup.sh update system-docs
bin/setup.sh update system-roms-docs
```
