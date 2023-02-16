## Usage

setup:

```
bin/setup.sh <action> <module> <args>

# Install all setup modules
bin/setup.sh install

# Install specific setup module
bin/setup.sh install splashscreen

# Install a range of setup modules (from splashscreen onward)
bin/setup.sh install splashscreen~

# Install a range of setup modules (based on order in config/settings.json)
bin/setup.sh install splashscreen~runcommand

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

romkit:

```
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

update:

```
# Update RetroPie-Setup, RetroPie packages, and the OS
bin/update.sh

# Update RetroPie-Setup and its packages
bin/update.sh retropie

# Update just RetroPie-Setup
bin/update.sh retropie_setup

# Update just RetroPie packages
bin/update.sh packages

# Update just the OS
bin/update.sh system

# Update emulator configurations (after emulator package updates)
bin/update.sh emulator_configs
```

cache:

```
# Delete everything in the tmp/ folder
bin/cache.sh delete

# Update no-intro DATs based on Love Pack P/C zip
bin/cache.sh sync_nointro_dats /path/to/love_pack_pc.zip
```

sd:

```
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

vacuum:

```
# Vacuum ROM files no longer needed
bin/vacuum.sh roms | bash

# Vacuum manuals for ROMs no longer installed
bin/vacuum.sh manuals | bash

# Vacuum scraper cache for ROMs no longer installed
bin/vacuum.sh media_cache | bash

# Vacuum scraped media for ROMs no longer installed
bin/vacuum.sh media | bash

# Vacuum overlays for ROMs no longer installed
bin/vacuum.sh overlays | bash

# Vacuum game state for ROMs no longer installed
bin/vacuum.sh gamestate | bash
```

migrate:

```
# Migrate filenames after updating to newer system DAT files
bin/migrate.sh

# Migrate a specific system
bin/migrate.sh nes
```

Common commands:

```
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
