# Environment

retrokit's configuration utilizes environment variables for 2 primary purposes:

* Define the list of profiles to active
* Define sensitive information (such as usernames, passwords, game archive urls, etc.)

Environment variables make it easier to switch behavior without having to modify
configuration files.

## Usage

To define your environment, either set the appropriate environment variables in your
terminal or create a `.env` file, using [.env.template](.env.template) as a starting
point.

Here is a simple example:

```bash
# Profile-based configuration overrides (can also be pulled in from a remote url)
export PROFILES=${PROFILES:-filter-1g1r}

# SSH Authentication
export LOGIN_USER=pi
export LOGIN_PASSWORD=MySecretP@ssword
```

Since this file contains sensitive information, it will be ignored in git by
default.  Be sure to not accidentally commit this anywhere!

## Variables

Below you can find detailed descriptions of all of the environment variables that
may be referenced by retrokit.  Of course, keep in mind that you can always add new
environment variables if your custom profile uses them.

### Profiles

```bash
# Profiles-based configuration overrides (can also be pulled in from a remote url)
export PROFILES=${PROFILES:-filter-demo,https://github.com/<username>/retrokit-profile-<name>.git}

# Whether to enable dependencies between profiles (via #include directives)
export PROFILE_DEPENDS=true
```

### ROM Restore

The environment variables used for restoring your ROMs from available archives are
only used if you've enabled the functionality.  Note that you must provide these
URLs -- retrokit does not provide any default values.

By default, retrokit assumes certain archives are being used.  You can search for
these environment variables in the repo to find out what the expectations are for
the archive.

```bash
# BIOS URLs
export BIOS_URL=https://github.com/<user>/<repo>/raw

# ROM Set URLs
export ROMSET_3DO_REDUMP_URL=https://<domain>/download/<name>
export ROMSET_DREAMCAST_REDUMP_URL=https://<domain>/download/<name>
export ROMSET_LASERDISC_URL=https://<domain>/download/<name>
export ROMSET_LASERDISC_SINGE_V1_URL=https://<domain>/download/<name>
export ROMSET_LASERDISC_SINGE_V2_URL=https://<domain>/download/<name>
export ROMSET_MAME_FBNEO_URL=https://<domain>/download/<name>
export ROMSET_MAME_2003_URL=https://<domain>/download/<name>
export ROMSET_MAME_2003_PLUS_URL=https://<domain>/download/<name>
export ROMSET_MAME_2010_URL=https://<domain>/download/<name>
export ROMSET_MAME_2010_EXTRAS_URL=https://<domain>/download/<name>
export ROMSET_MAME_2015_URL=https://<domain>/download/<name>
export ROMSET_MAME_2016_URL=https://<domain>/download/<name>
export ROMSET_MAME_0222_URL=https://<domain>/download/<name>
export ROMSET_MAME_0245_URL=https://<domain>/download/<name>
export ROMSET_MAME_LATEST_URL=https://<domain>/download/<name>
export ROMSET_NDS_NOINTRO_URL=https://<domain>/download/<name>
export ROMSET_NEOGEO_REDUMP_URL=https://<domain>/download/<name>
export ROMSET_NOINTRO_URL=https://<domain>/download/<name>
export ROMSET_PC_EXODOS_V5_URL=https://<domain>/<path>
export ROMSET_PCENGINE_REDUMP_URL=https://<domain>/download/<name>
export ROMSET_PSP_DLC_URL=https://<domain>/download/<name>
export ROMSET_PSP_PSN_URL=https://<domain>/download/<name>
export ROMSET_PSP_REDUMP_URL=https://<domain>/download/<name>
export ROMSET_PSX_USA_REDUMP_URL=https://<domain>/download/<name>
export ROMSET_PSX_EUR_REDUMP_URL=https://<domain>/download/<name>
export ROMSET_PSX_JAP_REDUMP_URL=https://<domain>/download/<name>
export ROMSET_PSX_MISC_REDUMP_URL=https://<domain>/download/<name>
export ROMSET_SATURN_REDUMP_URL=https://<domain>/download/<name>
export ROMSET_SEGACD_REDUMP_URL=https://<domain>/download/<name>
```

### Authentication

There are multiple ways in which a user might need to authenticate with your
system, including:

* SSH: Remote terminal-based system management
* VNC: Remote UI-based system management
* RetroArch Netplay: To allow users to join your game

Example:

```bash
# SSH Authentication
export LOGIN_USER=pi
export LOGIN_PASSWORD=MySecretP@ssword

# VNC Authentication
export VNC_PASSWORD=MySecretP@ssword

# Retroarch Netplay Authentication
export RETROARCH_PASSWORD=MySecretP@ssword
```

### Scraping

Certain scraping websites (such as [screenscraper](https://www.screenscraper.fr/))
require an account in order to perform a large number of daily requests.  If you
want to ensure you don't encounter a limit, you can provide the necessary
authentication details here.

```bash
# Screenscraper authentication (via SkyScraper)
#
# If not registered, API limit is 20,000 requests / day (~4,000 games)
export SCREENSCRAPER_USERNAME=
export SCREENSCRAPER_PASSWORD=
```

### Github

The Github API is primarily used for discovering overlays in [The Bezel Project's repos](https://github.com/thebezelproject?tab=repositories).
When not authenticated to Github, you're limited to how many API calls can be made in an hour.
If you expect to be running retrokit setup scripts that use more than 30 overlay repos in an
hour, then providing Github authentication keys are your best bet to avoid being rate limited.

See the [Github docs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
for instructions on generating a personal access token which can be used as an API key.

```bash
export GITHUB_API_KEY=
```

### Internet Archive

The Internet Archive is used primarily for downloading manuals and MAME support files.
In some cases, anonymous downloads may be blocked if the archive being used is too
popular.  To avoid this potential limitation, you can provide your InternetArchive
username / password:

```bash
export IA_USERNAME=
export IA_PASSWORD=
```

retrokit will authenticate with Internet Archive and store a session key that'll be
used for downloads.

### Wifi

If your hardware setup expect to utilize wifi, you can provide the SSID and password
to retrokit, which will automatically set up the authentication for you via the
`wifi` setupmodule.

```bash
export WIFI_SSID=mywifiname
export WIFI_PASSWORD=mywifipassword
```

### Tumblr

If you're a developer for retrokit and are building manual archives, then you may
need to provide Tumblr credentials in order to generate manuals from Tumblr posts.

```bash
export TUMBLR_API_KEY=...
export TUMBLR_API_SECRET=...
```

## Profiles

Like other functionality in retrokit, you can also define environment variables
at the profile-level so that your own profiles can introduce overrides.

As discussed in the [profiles](profiles.md) documentation, the `.env`
file is also where you can instruct retrokit to integrate other profiles.

For example:

```bash
#include 8bitdo-xinput
#include lightgun
#include kiosk
#include filter-1tb
```
