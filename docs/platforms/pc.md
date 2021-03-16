# DOS

## Emulators

Preferred:

* [DOSBox](https://github.com/libretro/docs/blob/master/docs/library/dosbox.md)

## Controls

Keys:

* Ctrl + F9: Exit

## ROMs

Primary Sources:

* https://***REMOVED***

Secondary Sources:

* https://***REMOVED***
* https://***REMOVED***

Top:

* https://www.dosgamesarchive.com/downloads/
* https://playclassic.games/the-best-dos-games/

## Instructions

Reference instructions:

* https://dosonthepi.blogspot.com/2015/01/run-dos-games-in-retropie_15.html#add-dosgames
* https://digimoot.wordpress.com/2018/08/05/retropie-dosbox-setup-guide/

Copy (unzipped):

```
scp -r platforms/dos/roms/* pi@***REMOVED***:/home/pi/RetroPie/roms/pc/.games/
```

Create conf file per game, e.g.:

```
[autoexec]
mount c "/home/pi/RetroPie/roms/pc/.games/oregont"
c:
OREGON.EXE
EXIT
```

## Installed Games


## Issues

### Carmageddon

https://retropie.org.uk/forum/topic/25041/dosbox-official-thread/40

Vertical lines

Possible fixes:

* dosbox-pure
* dosbox-staging
* dosbox-svn
* dosbox-x
