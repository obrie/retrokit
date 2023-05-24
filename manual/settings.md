# Settings

The general configuration settings for retrokit are stored in [`config/settings.json`](/config/settings.json).
Although these settings can be fully customized through [profiles](/manual/profiles.md), there
are a number of defaults and configurations to become familiar with so you understand how it
affects retrokit.

## splashscreen

The `splashscreen` setting is used to control what's displayed on the screen while
RetroPie and your frontend (e.g. EmulationStation) are loaded.  Currently the following
types of splaschreens are supported:

* video

Additional formats could be supported in the future.  To specify your splashscreen:

```json
{
  "splashscreen": "https://github.com/obrie/retrokit/releases/download/latest/splashscreen-joshua_rancel-retro_history.mp4"
}
```

The value simply needs to be a path to a remote url.

## themes

The `themes` settings controls:

* What themes are available to use for EmulationStation
* What theme to use for launch images

The theme actually selected for EmulationStation is determined by the
[es_settings.cfg](/config/emulationstation/es_settings.cfg) file.

For example:

```jsonc
{
  "themes": {
    "library": [
      {
        "name": "pixel-metadata",
        "repo": "ehettervik",

        // The launch image template url associated with this theme
        "launch_images_base_url": "https://raw.githubusercontent.com/TMNTturtleguy/ComicBook-Theme-Launch-Images-for-Retropie/master/16x9-Launching_ComicRip/{platform}/launching.png"
      }
    ],

    // The theme to use for launch images (can be different from the theme selected for EmulationStation)
    "launch_theme": "pixel-metadata"
  }
}
```

## overlays

The `overlays` setting is used to define bezels/overlays used within RetroArch
emulators.  This is both for aesthetics and lightgun support.  For example:

```jsonc
{
  "overlays": {
    // Whether to use game-specific overlays
    "enable_game_overrides": true,

    // The border to draw for Sinden lightgun support
    "lightgun_border": {
      "enabled": false,

      // Width (in pixels) of the border
      "width": 30,

      // Color of theborder
      "color": "#ffffff",

      // Whether to fill within the outline (black)
      "fill": false,

      // Adjusts the brightness level of the image before adding the border
      "brightness": 0.25
    }
  }
}
```

## manuals

The `manuals` setting is used by the `system-roms-manuals` setup script for
controlling behavior of how manuals are sourced, created, and stored.
For the most part, you shouldn't have a need to modify the defaults are they're
intended to be used for internal purposes.  However, if you want to build
your own manuals, you can refer to the settings before for how to control
the behavior.

```jsonc
{
  "manuals": {
    // The archive.org location to source manuals from
    "archive": {
      // id / version used for upload management
      "id": "retrokit-manuals",
      "version": "compressed",

      // URL to where to find the manuals
      "url": "https://archive.org/download/retrokit-manuals/{system}/{system}-compressed.zip/{name} ({languages}).pdf",

      // Whether the manuals at the given source have already been processed by retrokit
      "processed": true,

      // Whether to pull from the source (defined in the system's metadata database)
      // if the manual isn't found with the URL template above
      "fallback_to_source": false
    },

    // Where manuals will be stored
    "paths": {
      // The base path for all manuals
      "base": "$HOME/.emulationstation/downloaded_media/{system}/manuals",

      // Path for manuals pulled from the official retrokit archives
      "archive": "{base}/.download/{name} ({languages}) (archive).pdf",

      // Path for the original downloaded source
      "download": "{base}/.download/{name} ({languages}).{extension}",

      // Path for manuals after postprocessing them
      "postprocess": "{base}/.files/{name} ({languages}).pdf",

      // Path to install (symlink) the postprocessed manaul
      "install": "{base}/{rom_name}.pdf"
    },

    // Whether to keep the original downloaded files (only applicable if
    // you're customizing the postprocessing configuration)
    "keep_downloads": false,

    // The postprocessing section refers to additional modifications to make
    // to a PDF from its original format
    "postprocess": {
      // Run the mupdf clean process?
      "clean": {
        "enabled": true
      },

      // Run character recognition on the text so the PDF is searcahble?
      "ocr": {
        "enabled": true
      },

      // Slice / rotate the images according to the manual's metadata?
      "mutate": {
        "enabled": true
      },

      // Compress the resulting images?
      "compress": {
        "enabled": true,

        // Convert the ICC-based color profiles to RGB?
        "color": {
          "icc": false
        },
        // Downsample settings
        "downsample": {
          "enabled": true,
          // Threshold ratio for downsampling images
          "threshold": 1.05,
          // Downsample if pages are larger than this width
          "width": 1920,
          // Downsample if pages are larger than this height
          "height": 1440,
          // Don't downsample beyond this resolution
          "min_resolution": 72,
          // Downsample if resolution is higher than this
          "max_resolution": 300
        },

        // QFactor PDF settings
        "quality_factor": {
          // The QFactor color setting to use when page_width/downsample_width or page_height/downsample_height is >= highres_threshold
          "highres_color": 0.9,
          "highres_gray": 0.9,
          "highres_threshold": 0.66,
          // The QFactor color setting to use when page_width/downsample_width or page_height/downsample_height is < highres_threshold
          "lowres_color": 0.4,
          "lowres_gray": 0.76,
          // Re-compress jpeg images?
          "pass_through_jpeg": false
        },

        // Image encoding settings
        "encode": {
          // Encode uncompressed images to jpeg?
          "uncompressed": true,
          // Re-encode jpeg2000 images to jpeg?
          "jpeg2000": true
        },

        // Filesize threshold settings
        "filesize": {
          // Only compress images that at least this many bytes (filesize)
          "minimum_bytes_threshold": 0,
          // Only compress images if the filesize was reduce by this % threshold (10%)
          // 
          // Compression is forced regardless of this value if uncompressed / jpeg2000 / icc
          // conversions are enabled and those settings are discovered in the pdf.
          "reduction_percent_threshold": 0.1
        }
      }
    },

    // How to integrate manualkit -- via emulationstation or runcommand
    "integration": "emulationstation"
  }
}
```

## retropie

The `retropie` setting is used for configuration various components of RetroPie
and how it behaves on the system.  Currently, this is limited to how RetroPie
is visible within EmulationStation.

For example:

```json
{
  "retropie": {
    "show_menu": true,
    "menus": [
      "Bluetooth",
      "RetroArch Net Play",
      "WiFi"
    ]
  }
}
```

The settings here control:

* Should RetroPie be visible as a menu in EmulationStation?
* If so, which sub-menus should be visible?

The above example restricts the RetroPie menu to just a handful of sub-menus.

## hardware

The `hardware` setting enables you to a few different aspects about how different
parts of your hardware are configured on the system.  Specifically it handles:

* Auto-configuration of controllers
* Hotkey selection
* Supplemental configscript integrations
* IR mappings

For example:

```jsonc
{
  "hardware": {
    "controllers": {
      "inputs": [
        // Set up keyboard as a controller input
        {
          "name": "Keyboard"
        },

        // Enable the 8BitDo Arcade stick (2.4ghz and bluetooth)
        {
          "name": "Microsoft X-Box 360 pad",
          "id": "030000005e0400008e02000014010000",
          "description": "8Bitdo X-Input, Wired, Triggers to Buttons, Xbox layout (Arcade Stick)",
          // Should a/b and x/y be swapped?
          "swap_buttons": false
        },
        {
          "name": "8BitDo Arcade Stick",
          "id": "050000005e040000fd02000030110000",
          "description": "8Bitdo X-Input, Bluetooth, Triggers to Buttons, Xbox layout (Arcade Stick)",
          "swap_buttons": false
        },

        // Enable the 8Bitdo SN30 Pro in D-Input mode
        {
          "name": "8Bitdo SN30 Pro",
          "id": "05000000c82d00000161000000010000",
          "description": "8Bitdo D-Input, Bluetooth, Nintendo Layout",
          "swap_buttons": true,
          "axis": {
            "ABS_X": 128,
            "ABS_Y": 128,
            "ABS_Z": 128,
            "ABS_RZ": 128
          }
        }
      ],

      // Use the "select" button as our hotkey across all controllers for RetroArch
      // emulators
      "hotkey": "select",

      // Enable these additional input configscripts.  This will help automatically
      // set up inputs for the associated emulators.
      "configscripts": [
        "advmame",
        "drastic",
        "hypseus",
        "ir",
        "ppsspp",
        "redream",
        "retrokit-mupen64plus",
        "retrokit-overrides"
      ]
    },

    // Configure a dtoverlay for IR hooked up via the given GPIO pin.  Additionally,
    // the signals will be mapped using the given keytable.
    "ir": {
      "gpio_pin": 23,
      "keymap": "/lib/udev/rc_keymaps/tivo.toml"
    }
  }
}
```

### Controllers

For information on how to identify your controller id, you can look at the
[controls](/manual/controls.md) documentation.  There are a few interesting
pieces to call out in the example provided above.

* The `swap_buttons` flag allows you to tell retrokit that your controller has
  a/b and x/y swapped when compared to what's described in the [gamecontrollerdb](https://github.com/gabomdq/SDL_GameControllerDB)
  database.  For example, 8BitDo controllers often report as xbox controllers,
  but they're buttons use an SNES layout.

* In some cases, the axis values for a controller aren't known until an initialization
  sequence has been activated.  This causes the menus to jump erratically when
  you press a button the first time after turning on the controller.  The
  `axis` setting on a controller allows you to pre-calibrate the settings for that
  controller.  The source for this automatic fix is outlined [here](https://retropie.org.uk/forum/topic/28693/a-workaround-for-the-northwest-drift-issue).

### configscripts

RetroPie has various configscripts in place to automatically set up your controller
in a variety of different emulators.  However, this isn't the case for *all* emulators.
In order to improve the user experience, retrokit integrates a variety of other
configscripts so that all emulators utilized by retrokit are automatically set up
when a new controller is registered.

The additional systems that are supported by retrokit include:

* advmame
* drastic
* hypseus
* ppsspp
* redream
* mupen64plus (adds keyboard overrides, axis reconfigurations)

Additionally, there are 2 configscripts which extend general functionality in
the system.  That includes:

* ir - Use your IR remote as a controller
* retrokit-overrides - Allow certain RetroArch controller hotkey combos to be disabled

## systems

The `systems` setting allows you to define which gaming systems you want to include
in your setup.  Any system listed here *must* be explicitly supported by retrokit.

Note that the order in which systems are defined in this configuration determines the
order in which (a) they are set up and (b) they appear in EmulationStation.

Example:

```json
{
  "systems": [
    "arcade",
    "atari2600",
    "atari5200",
    // ...
  ]
}
```

## setup

The `setup` setting allows you to control which modules to install when running
retrokit.  The default setup includes modules that would be applicable to most
installations.

For example, the default setup is defined like so:

```json
{
  "setup": {
    "modules": [
      "network-wifi",
      "deps",
      "ssh",
      "boot",
      // ...
    ]
  }
}
```

If you want to add/remove certain modules from a [profile](/manual/profiles.md), you
can adjust the configuration like so:

```json
{
  "setup": {
    "modules|case": {
      "add": [
        "hardware/argon1"
      ],
      "before": "powerkit"
    },

    "modules|overlays": {
      "remove": [
        "system-overlays",
        "system-roms-overlays"
      ]
    }
  }
}
```

Note that the key format here is always `modules|<identifier>`.  These settings will
be merged by retrokit into the base `setup` modules defined in `config/settings.json`.

You could, of course, always just explicitly override the `"modules"` settup, but
that will be harder to maintain over time.
