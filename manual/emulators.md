## Emulators

The following emulators / cores are built from source:

* lr-swanstation (unofficial, no binaries available yet)
* lr-yabasanshiro (unofficial, no binaries available yet)

### Performance

Not all systems perform well on the Pi 4.  Those with performance
issues on some games include:

* 3do
* atarijaguar
* n64
* pc
* psp
* saturn

To the best of my ability, I've attempted to capture compatibility
ratings and emulator selections for these systems to find the games
that work pretty well.  For these reasons, you'll find that these
systems have fewer games installed than others.

### Compatibility

For emulators that can experience poor performance on the Pi 4, there are
ratings that have been gathered from various sources to identify which games
work well and which games don't.

The ratings are roughly categorized like so:

| Rating | Description                                          |
| ------ | ---------------------------------------------------- |
| 5      | Near perfection or perfection (no noticeable issues) |
| 4      | 1 or 2 minor issues                                  |
| 3      | 1 or 2 major issues, but still playable              |
| 2      | 3 or more major issues, not fun to play              |
| 1      | Unplayable                                           |

Some of this is subjective.  For the most part, the defaults in retrokit avoid
filtering for games that have major issues.

## Game state

Game state can be quickly exported / imported using the `system-roms-gamestate`
setup module.  Additionally, you can vacuum (i.e. remove unused game state) and
delete all game state using this module as well.

The export / import functionality currently supports either generating a single
export ZIP file per system or a shared export file across all systems.

Below is some example usage:

```
# Remove unused game state for all systems (only prints commands, does not execute them)
bin/setup.sh vacuum system-roms-gamestate

# Remove unused game state for specific system
bin/setup.sh vacuum system-roms-gamestate nes

# Remove all game state (only prints commands, does not execute them)
bin/setup.sh remove system-roms-gamestate nes

# Generates a per-system export file to tmp/<system>/export.zip
bin/setup.sh export system-roms-gamestate

# Generates an export file to the given path
bin/setup.sh export system-roms-gamestate nes /path/to/export.zip

# Generates a single export file for all systems to the given path
bin/setup.sh export system-roms-gamestate /path/to/export.zip merge=true

# Imports, without ovewriting, game state for all systems
bin/setup.sh import system-roms-gamestate

# Imports game state for a specific system from the given path, without overwriting
bin/setup.sh import system-roms-gamestate nes /path/to/export.zip

# Imports *and* overwrites game state for a specific system / export path
bin/setup.sh import system-roms-gamestate nes /path/to/export.zip overwrite=true
```

This functionality could be enhanced in a large number of ways, or you can build
some form of backup on top of this feature.  The implementation is fairly straightforward
since all of the work to identify the relevant game state files is already done.
