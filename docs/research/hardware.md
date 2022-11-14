# Hardware

The hardware configurations below are based on my experiences for what I found
worked well and are recommended as a starting point for building your own
customized experience.

## Configurations

Some notes about the choices below:

* 4GB is more than enough for what RetroPie requires; you can probably get away with 2GB
* 2.4ghz controllers / keyboards are faster and easier to use than Bluetooth, so I generally
  prefer those
* SSD drives are preferred over SD cards due to their available capacity and durability
* A 3.5A power supply is recommended for stable USB power needs
* 8Bitdo has the only wireless arcade stick I've found and supports 2.4ghz

Keep in mind that the costs below are for the entire configuration as-is.  There are many areas
you can cut costs, such as using different controllers or reducing the number of controllers you
purchase.

### The Minimalist

This represents a minimal configuration that I would be comfortable with running.

| Component         | Description                     | Cost  | URL |
| - | - | - | - |
| Computer          | Raspberry Pi 4 2GB              | $45   | https://www.canakit.com/raspberry-pi-4-2gb.html |
| Case              | Argon ONE M.2 Case              | $25   | https://www.amazon.com/dp/B07WP8WC3V |
| TV Cable          | HDMI Cable                      | $7    | https://www.amazon.com/dp/B01GCGKI3O |
| Power Supply      | CanaKit 3.5A Power Supply       | $10   | https://www.amazon.com/dp/B07TYQRXTK |
| Hard Drive        | Samsung EVO Plus 64GB MicroSD   | $14   | https://www.samsung.com/us/computing/memory-storage/memory-cards/evo-plus---adapter-microsdxc-64gb-mb-mc64ka-am/ |

This includes no controllers but gets you a running system for $100 that you can always upgrade
in the future.

### The Old Timer

This configuration is intended to look like an old NES.

| Component         | Description                     | Cost  | URL |
| - | - | - | - |
| Computer          | Raspberry Pi 4 4GB              | $55   | https://www.canakit.com/raspberry-pi-4-4gb.html |
| Case              | Retroflag NESPi4 Case           | $40   | https://www.amazon.com/dp/B08CRDKX6T |
| TV Cable          | CanaKit Micro HDMI Cable        | $15   | https://www.amazon.com/dp/B07TTKD38N |
| Heatsink          | GeekPi Heatsink + Fan           | $8    | https://www.amazon.com/dp/B07PCMTZHF |
| Power Supply      | CanaKit 3.5A Power Supply       | $10   | https://www.amazon.com/dp/B07TYQRXTK |
| Hard Drive        | Western Digital 1TB 2.5" SSD    | $90   | https://www.amazon.com/dp/B073SBQMCX |
| HD Enclosure      | Retroflag SATA Enclosure        | $25   | https://www.amazon.com/dp/B08XJYR1S5 |
| USB Hub           | Sabrent 4-Port USB 2.0 Hub      | $7    | https://www.amazon.com/dp/B00L2442H0 |
| Arcade Stick      | 8Bitdo Arcade Stick (2)         | $90   | https://www.amazon.com/dp/B08GJC5WSS |
| Controller        | 8Bitdo SN30 Pro (2)             | $40   | https://www.amazon.com/dp/B08Y9QLCKM |
| Keyboard + Mouse  | Arteck 2.4ghz Keyboard + Mouse  | $30   | https://www.amazon.com/dp/B07MCTZ3LZ |

Total cost: $250 ($540 with controllers)

Important notes:

* When setting up the NESPi4 case, it's important that you connect the USB wire for the SATA
  drive to a USB 2.0 port.  The wires end up a little snug, but it's easy to do.  The reason to
  do this is to avoid the wireless interference caused by USB 3.0 when connected to the hard
  drive.
* The 8Bitdo Arcade Stick must be set to X-Input mode, D-Pad when using 2.4ghz
* The 8Bitdo SN30 Gamepad should be set to D-Input mode, though I don't think it's required

### The Speed Runner

This configuration is intended to give you a modern-looking solution that will allow
your Raspberry Pi to run at a cool temperature so that you can effectively overclock.

| Component         | Description                     | Cost  | URL |
| - | - | - | - |
| Computer          | Raspberry Pi 4 4GB              | $55   | https://www.canakit.com/raspberry-pi-4-4gb.html |
| Case              | Argon ONE M.2 Case              | $47   | https://www.amazon.com/dp/B08MJ3CSW7 |
| TV Cable          | HDMI Cable                      | $7    | https://www.amazon.com/dp/B01GCGKI3O |
| Power Supply      | CanaKit 3.5A Power Supply       | $10   | https://www.amazon.com/dp/B07TYQRXTK |
| Hard Drive        | Western Digital 1TB M.2 SSD     | $90   | https://www.westerndigital.com/products/internal-drives/wd-blue-sata-m-2-ssd#WDS100T2B0B |
| USB Cable         | USB 2.0 Male to Male A Cable    | $9    | https://www.amazon.com/dp/B07BZ2M3WM |
| HD Enclosure      | SSK M.2 Enclsoure               | $13   | https://www.amazon.com/dp/B07MKCG5ZG |
| Arcade Stick      | 8Bitdo Arcade Stick (2)         | $90   | https://www.amazon.com/dp/B08GJC5WSS |
| Controller        | 8Bitdo SN30 Pro (2)             | $40   | https://www.amazon.com/dp/B08Y9QLCKM |
| Keyboard + Mouse  | Arteck 2.4ghz Keyboard + Mouse  | $30   | https://www.amazon.com/dp/B07MCTZ3LZ |

Total cost: $231 ($521 with controllers)

Important notes:

* The USB 2.0 Male to Male cable is needed to connect your M.2 drive to a USB 2.0 port.
  This is important if you have wireless controllers because USB 3.0 creates enough interference
  that your controllers may no longer work when the M.2 drive is connected.
* The 8Bitdo Arcade Stick must be set to X-Input mode, D-Pad when using 2.4ghz
* The 8Bitdo SN30 Gamepad should be set to D-Input mode

Additional benefits:

* Case comes with IR for TV Remote control and full-size HDMI ports

### The Monster

I don't know what this configuration looks like yet, but it involves the use of Intel NUC
in order to support Playstation 2 / Wii.

### The Traveler

This represents a portable configuration that you can take anywhere.

| Component         | Description                         | Cost  | URL |
| - | - | - | - |
| Computer          | Raspberry Pi CM4 Lite 4GB, Wireless | $80   | https://www.pishop.us/product/raspberry-pi-compute-module-4-wireless-4gb-lite-cm4104000/ |
| Case              | Retroflag GPi Case 2 w/ Dock        | $90   | https://www.amazon.com/dp/B09DPM2GSF |
| TV Cable          | HDMI Cable                          | $7    | https://www.amazon.com/dp/B01GCGKI3O |
| Power Supply      | CanaKit 3.5A Power Supply           | $10   | https://www.amazon.com/dp/B07TYQRXTK |
| Hard Drive        | Samsung EVO Plus+ 512GB microSDXC   | $65   | https://www.samsung.com/us/computing/memory-storage/memory-cards/evo-plus---adapter-microsdxc-512gb-mb-mc512ka-am/ |
| Keyboard + Mouse  | Arteck 2.4ghz Keyboard + Mouse      | $30   | https://www.amazon.com/dp/B07MCTZ3LZ |
| Heatsink          | Aluminum Heatsink for CM4           | $9    | https://www.amazon.com/dp/B093FSS6XX |

Total cost: $261 ($291 with keyboard)

Important notes:

* You must get the CM4 Lite (no eMMC) in order to use an SD card
* Strongly recommend getting a CM4 with wireless to simplify setup and configuration
* To install the heatsink, follow [these instructions](https://www.reddit.com/r/retroflag_gpi/comments/xudus6/just_another_heatsinkmod_without_batteryremoval/)

## Upgrades

There are a lot of upgrades you can consider that I've used and am happy with.

### Additional Controllers

The system configurations above cover basics like arcade sticks and controllers.  However, there
are additional controller types for arcade systems that will provide a much better experience.
Those controllers are covered below and I've confirmed work with retrokit.

| Component         | Description                     | Cost  | URL |
| - | - | - | - |
| Arcade Trackball  | Kensington Orbit Wireless Trackball | $53   | https://www.amazon.com/dp/B09DGMYVPP |
| Lightgun          | Sinden Lightgun                     | $103  | https://www.sindenlightgun.com/ |

For even more controllers, I strongly suggest any of the wired or bluetooth controllers from
[8Bitdo](https://www.8bitdo.com/#Products), particularly either of these:

* [8Bitdo SN30 Pro](https://www.8bitdo.com/sn30-pro-g-classic-or-sn30-pro-sn/)
* [8Bitdo Pro 2](https://www.8bitdo.com/pro2/)

Some notes:

* The Sinden Lightgun can also come with recoil for an additional $60

### Better Bluetooth

The Raspbery Pi 4B has decent Bluetooth performance / range.  However, you can get even better
performance by using an external adapter.

| Component         | Description                     | Cost  | URL |
| - | - | - | - |
| Bluetooth Adapter | 8Bitdo Wireless USB Adapter     | $18   | https://www.amazon.com/dp/B09M8CVMYF |

### Better Arcade Stick

The 8Bitdo arcade stick comes with a SANWA-like joystick that uses a square restrictor plate.  This
works great for games like Street Fighter but is less than ideal for older arcade games like Pac-Man
since it's difficult to hit the correct 4-way directionals.  An octagonal restrictor plate with a
premium SANWA joystick provides a better experience.

| Component         | Description                     | Cost  | URL |
| - | - | - | - |
| Joystick          | SANWA JLF-TP-8YT Joystick       | $25   | https://www.amazon.com/dp/B005BIC9QE |
| Restrictor Gate   | SANWA GT-Y Octagonal Restrictor | $8    | https://www.amazon.com/dp/B06VVG936T |
| USB Encoder       | Hikig 5-Pin USB Encoder Cable   | $7    | https://www.amazon.com/dp/B07BK12QBG |

It's *very* easy to replace the components of the 8Bitdo Arcade Stick.  You can see instructions for
doing this here: https://www.youtube.com/watch?v=_iJi8pONMkA

### Powered USB Hub

Depending on which system configuration you go with, you'll end up with 2 or 3 spare USB ports.  For
general gaming and bluetooth controllers, this is good enough.  However, if you're introducing
wireless trackball, lightguns, keyboards, bluetooth adapters, etc. you're going to run out of USB
ports quickly.

Additionally, you're limited to 1.2A *combined* for USB usage.  Since an SSD drive will consume up to
400mA typically, you have to be careful that you don't overload the USB otherwise you risk data
corruption.

To handle more controllers and limit amp usage from your Raspberry Pi, I suggest a powered USB Hub.

| Component         | Description                     | Cost  | URL |
| - | - | - | - |
| 7-Port Hub        | Anker 7-Port USB 3.0 Data Hub   | $50   | https://www.amazon.com/dp/B014ZQ07NE |

### Tool-Free Hard Drive Enclosures

| Component         | Description                     | Cost  | URL |
| - | - | - | - |
| M.2 Enclosure     | Sabrent M.2 NVMe / SATA USB     |  $29   | https://www.amazon.com/dp/B08RVC6F9Y |

USB Hard Drive enclosures are notorious for being problematic on the Raspberry Pi.  This is covered in
great detail here:

* https://jamesachambers.com/raspberry-pi-4-usb-boot-config-guide-for-ssd-flash-drives/
* https://jamesachambers.com/fixing-storage-adapters-for-raspberry-pi-via-firmware-updates/

I really like the Sabrent enclosure, but it is critical that you update to the most recent
firmware in order to avoid hard drive corruption problems (this **WILL** happen very quickly).
The instructions I followed came from the websites above and are covered here:

1. Download the latest [Sabrent firmware](https://downloads.sabrent.com/product/ec-snve-firmware-update/), unzip, and keep only the SA8307.cfg config file.
2. Download the latest firmware for the [ICY BOX IB-1817MC-C31 or ICY BOX IB-1817MCT-C31](https://raidsonic-static-content.s3.eu-central-1.amazonaws.com/IcyBox/Files/ICY%20BOX%20IB-1817MC-C31%20Firmware%20Update.zip), they are the same.
3. Unzip the ICY BOX firmware, and replace the `configure/IB-1817MC-C31.cfg` file with the Sabrent `SA8307.cfg`.
4. Plug in the Sabrent, open `UTHSB_MPtool_Lite.exe` in Windows, and you should see MPtool has picked the `SA8307.cfg` file.
5. Click the Upload Device button and enjoy the latest, fastest and most stable firmware for your Sabrent.

If you don't want to deal with this (I don't blame you) here are additional enclosures whose hardware
appears to be compatible with the Raspberry Pi without a firmware upgrade:

| Component         | Description                     | Cost  | URL |
| - | - | - | - |
| M.2 Enclosure     | ORICO M.2 SATA USB              | $14   | https://www.amazon.com/dp/B08JV3HZ9S |

## Downgrades

Some of the above configurations may be more than what you need.  Below are some options for
downgrading your system.

### Smaller Drive

A 1TB hard drive is only necessary for the default configuration.  You can easily install fewer systems or
fewer games and reduce the required hard drive size.  Additionally, you can switch to a simple SD card
setup:

| Component         | Description                     | Cost  | URL |
| - | - | - | - |
| 128GB SD Card     | Samsung EVO Plus 128GB MicroSD   | $24   | https://www.samsung.com/us/computing/memory-storage/memory-cards/evo-plus---adapter-microsdxc-128gb-mb-mc128ka-am/ |

Samsung EVO+ is the most common, well-rounded SD card.  Recommend buying direct from Samsung to avoid
fake cards.

### External Enclosure Only

If you're using the Argon ONE case, you can save some money by not using the M.2 variant:
https://www.amazon.com/dp/B07WP8WC3V

## References

* [Input latency spreadsheet](https://docs.google.com/spreadsheets/d/1KlRObr3Be4zLch7Zyqg6qCJzGuhyGmXaOIUrpfncXIM/edit)
* [Tom's Hardware: Raspberry Pi MicroSD Cards](https://www.tomshardware.com/best-picks/raspberry-pi-microsd-cards)
* [Android Central: Raspbery Pi MicroSD Cards](https://www.androidcentral.com/best-sd-cards-raspberry-pi-4)
