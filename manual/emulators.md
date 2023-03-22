# Emulators

## Building from source

Most emulators are installed using the binary assuming you're using:

* Raspberry Pi 4b+
* Raspbian Buster

This is because [pre-built binaries](https://github.com/obrie/retrokit/releases/tag/latest)
have been provided for emulators that would normally be built from source.

The following emulators fall in that category:

* actionmax
* advmame w/ joystick fixes
* lr-mame 0.222
* lr-mame 0.244
* lr-mame2016 w/ lightgun fixes
* lr-swanstation
* lr-yabasanshiro

### Caching binaries

Binaries are built and cached on github.  In order to utilize these binaries, the
scriptmodules must be set up to point to retrokit's binary repository.

To build new binaries and deploy them to github, the following commands can be run:

```sh
bin/cache.sh build_emulator_binaries [package_name]
bin/cache.sh sync_emulator_binaries [package_name]
```

These commands must be run on a Raspberry Pi 4.  In order to build the binaries,
retrokit uses RetroPie's builder module to create an isolated RetroPie environment
so that your own system doesn't affect the build process.

Theoretically these commands should be capable of being run on other distributions,
but I've found most success running directly on a Pi.

## Performance

Not all systems perform well on the Pi 4.  Those with performance issues on some
games include:

* 3do
* atarijaguar
* gameandwatch
* mess
* n64
* pc
* psp
* saturn

To the best of my ability, I've attempted to capture compatibility ratings and emulator
selections for these systems to find the games that work pretty well.  For these reasons,
you'll find that these systems have fewer games installed than others.

### Compatibility

For emulators that can experience poor performance on the Pi 4, there are ratings that
have been gathered from various sources to identify which games work well and which games
don't.

The ratings are roughly categorized like so:

| Rating | Description                                          |
| ------ | ---------------------------------------------------- |
| 5      | Near perfection or perfection (no noticeable issues) |
| 4      | 1 or 2 minor issues                                  |
| 3      | 1 or 2 major issues, but still playable              |
| 2      | 3 or more major issues, not fun to play              |
| 1      | Unplayable                                           |

Some of this is subjective.  For the most part, the defaults in retrokit avoid
selecting games that have major issues.  The intention is to make it clear which games
you'll actually enjoy playing and which you won't.
