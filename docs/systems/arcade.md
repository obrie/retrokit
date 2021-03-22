# Arcade

## Emulators

Preferred:

* lr-fbneo
* lr-mame2003plus

references:

* [Compatibility List](https://docs.google.com/spreadsheets/d/1Rq4shU1RUSdcc7cTVWeORMD-mcO6BwXwQ7TGw8f5_zw/edit#gid=0)

## ROMs

* Split sets are okay if you're only using parents
* Split sets are also okay so long as you're including all the parents
* Non-merged sets waste space but are all standalone
* Merged sets include all clones in one file (unnecessary)
* https://***REMOVED*** is based on latest emulator
* I think each time we update the fbneo emulator, we need to use the ***REMOVED***?
* How do we use lr-mame 0.222?

## Filters

* [Category Filters](https://www.progettosnaps.net/catver/)
* [Languages](https://www.progettosnaps.net/languages/)

### FBNeo

Files:

* [Nightly ROM Set](https://***REMOVED***)
* [Stable ROM Set](https://***REMOVED***)
* [DAT](https://github.com/libretro/FBNeo/raw/v1.0.0.0/dats/FinalBurn%20Neo%20(ClrMame%20Pro%20XML%2C%20Arcade%20only).dat)

### MAME

Files:

* [2003 Plus ROM Set](https://***REMOVED***)
* [2003 ROM Set](https://***REMOVED***)
* [DAT](https://github.com/libretro/mame2003-plus-libretro/raw/master/metadata/mame2003-plus.xml)

References:

* Mame 2003 Plus DAT: https://www.progettosnaps.net/dats/MAME/

### Non-merged Sets

Reference: https://retropie.org.uk/docs/Validating%2C-Rebuilding%2C-and-Filtering-ROM-Collections/

Setup:

1. Download ClrMamePro: http://mamedev.emulab.it/clrmamepro/#downloads
2. Install Wine
3. Install wine mono from https://dl.winehq.org/wine/wine-mono/6.0.0/
4. Configure wine (winecfg)
5. Install app (wine cmp4041_64.exe)
6. Follow instructions here: https://www.youtube.com/watch?v=_lssz2pAba8

Run clrmamepro:

```
cd ~/.wine/drive_c/Program\ Files/clrmamepro
wine cmpro64.exe
```

TorrentZip ROMs:

```
wget https://www.romvault.com/trrntzip/download/TrrntZip.NET106.zip
ls *.zip | parallel -j 5 wine ~/Downloads/TrrntZip.NET.exe  {}
```
