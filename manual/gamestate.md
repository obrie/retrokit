# Game State

Game state exists in all shapes and sizes across systems.  Finding the right set of
files to back up can be challenging.  To help simplify this, game state can be quickly
exported / imported using the `system-roms-gamestate`  setup module.

## Export

The export / import functionality currently supports either generating a single
export ZIP file per system or a shared export file across all systems.

Below is some example usage:

```sh
# Generates a per-system export file to tmp/<system>/export.zip
bin/setup.sh export system-roms-gamestate

# Generates an export file to the given path
bin/setup.sh export system-roms-gamestate nes /path/to/export.zip

# Generates a single export file for all systems to the given path
bin/setup.sh export system-roms-gamestate /path/to/export.zip merge=true
```

## Import

To import a backup, you can use one of the commands below:

```sh
# Imports, without ovewriting, game state for all systems
bin/setup.sh import system-roms-gamestate

# Imports game state for a specific system from the given path, without overwriting
bin/setup.sh import system-roms-gamestate nes /path/to/export.zip

# Imports *and* overwrites game state for a specific system / export path
bin/setup.sh import system-roms-gamestate nes /path/to/export.zip overwrite=true
```

## Vacuum

If you've deleted games that you no longer want on your system, it can also be useful
to remove the associated game state.  To do that, you can run one of the following
commands:

```sh
# Remove unused game state for all systems (only prints commands, does not execute them)
bin/setup.sh vacuum system-roms-gamestate

# Remove unused game state for specific system
bin/setup.sh vacuum system-roms-gamestate nes

# Remove all game state (only prints commands, does not execute them)
bin/setup.sh remove system-roms-gamestate nes
```

Note that these commands never actually delete anything.  Instead, they will print the
commands you'd want to run.  If you want to combine both at once, you can run all
printed commands like so:

```sh
# Executes the `rm` commands that get printed
bin/setup.sh vacuum system-roms-gamestate nes | bash
```

## Enhancements

This functionality could be enhanced in a large number of ways, such as building
some form of backup on top of this feature.  Implementing this would be fairly
straightforward since all of the work to identify the relevant game state files is
already done.
