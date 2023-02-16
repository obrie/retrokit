# Profiles

To override any configuration settings, you have two options:

1. Modify the settings directly in retrokit's `config/` directory
2. Create a profile that defines overrides which will be merged into
   or overwrite retrokit's `config/` settings.

Profiles are a way of overlaying retrokit's default configuration settings with
your own custom settings.  It does this by either merging your settings on top
of the default settings or completely overwriting the default settings, depending
on what makes most sense.

The default profile is called `mykit` as defined in the `PROFILES` environment
variable in [`.env.template`](.env.template).

The profile directory is structured like so:

```
profiles/
profiles/{profile_name}
profiles/{profile_name}/{config_file}
profiles/{profile_name}/{config_dir}/{config_file}
```

The directory structure is meant to mirror that of the folder at the
root of this project.  For example, suppose you wanted to change which systems
were installed.  To do so, you would define a `settings.json` override:

profiles/mykit/config/settings.json:

```json
{
  "systems": [
    "nes",
    "snes"
  ]
}
```

These settings will be merged into [`config/settings.json`](config/settings.json)
and then used throughout the project.

You can even define multiple profiles.  For example, support you wanted to define
a "base" profile and then layer customizations for different systems on top of that.
To do that, add something like this to your `.env`:

```
PROFILES=mykit/base,mykit/crt
# PROFILES=mykit/base,mykit/hd
```

In the examples above, a `mykit/base` profile defines overrides that you want to use for
all of your profiles.  A `mykit/crt` or `mykit/hd` profile then defines overrides that you want
to use for specific hardware configurations.

## Overrides

In general, anything under `config/` can be overridden by a profile.  The following
types of files will be *merged* into the defaults provided by retrokit:

* env
* ini
* json

The following specific configurations will be overwritten entirely by profiles:

* `config/controllers/inputs/*.cfg`
* `config/localization/locale`
* `config/localization/locale.gen`
* `config/localization/timezone`
* `config/skyscraper/videoconvert.sh`
* `config/systems/mame/default.cfg`
* `config/systems/mame2016/default.cfg`
* `config/themes/*`
* `config/vnc/*`
* `config/wifi/*`

## Binary overrides

In addition to overriding configuration settings, you can also override binaries
that are related to configuration settings.  This includes:

* Retrokit setup scripts
* Custom RetroPie scriptmodules
* RetroPie controller autoconfig scripts
* Sinden controller scripts

These scripts are expected to be located in a `bin/` path under your profile's
directory with the same structure as retrokit's.  For example, to add a new setup
script for your profile, you can configure it like so:

profiles/mykit/config/settings.json:

```json
{
   "setup": {
      "add": [
         "mycustomscript"
      ]
   }
}
```

You would then create your setup script under `profiles/mykit/bin/setup/mycustomscript.sh`
to match the same structure as retrokit's `bin/` folder.

### Environment variables

Environment variables can be defined in 3 places:

* Current shell environment
* .env at the root of this project
* .env at the root of profiles/{name}/

Which environment variables take priority largely depends on how you've defined
your environment variables.  If your `.env` is configured like so:

```sh
export PROFILES=filter-demo
```

...then `PROFILES` will always be `"filter-demo"` regardless of the current shell
environment.  To instead respect the current environment, you can change the format
to:

```sh
export PROFILES=${PROFILES:-filter-demo}
```

## Use cases

Beyond building profiles for your own personalized systems, profiles could also
pave the path for adapting retrokit to systems beyond the Raspberry Pi 4.  If you
have a profile that you'd like to share for others to use, please let me know and
I'd be happy to add it to the documentation in this repo.
