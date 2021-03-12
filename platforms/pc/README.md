# DOS

## Emulators

Preferred:

* DosBox

## Installation

Install dependencies:

```
sudo apt install fluid-soundfont-gm
```

Set up [Gravis Ultrasound](https://retropie.org.uk/docs/PC/#install-gravis-ultrasound-gus):

```

```

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

* [Carmageddon](https://***REMOVED***Carmageddon%20Max%20Pack%20%281998%29.zip)
* [Contra](https://***REMOVED***Contra%20%281988%29.zip)
* [Epic Pinball](https://***REMOVED***Epic%20Pinball%20-%20The%20Complete%20Collection%20%281995%29.zip)
* [Family Feud](https://***REMOVED***Family%20Feud%20%281987%29.zip)
* [Karateka](https://***REMOVED***Karateka%20%281986%29.zip)
* [Number Munchers](https://***REMOVED***Number%20Munchers%20%281990%29.zip)
* [Oregon Trail](https://***REMOVED***Oregon%20Trail%2C%20The%20%281990%29.zip)
* [Oregon Trail Deluxe](https://***REMOVED***Oregon%20Trail%20Deluxe%2C%20The%20%281992%29.zip)
* [Worms](https://***REMOVED***Worms%20-%20Reinforcements%20%281995%29.zip)

## Issues

### Carmageddon

https://retropie.org.uk/forum/topic/25041/dosbox-official-thread/40

Vertical lines

Possible fixes:

* dosbox-pure
* dosbox-staging
* dosbox-svn
* dosbox-x
