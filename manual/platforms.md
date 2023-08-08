# Platforms

retrokit is developed for and tested on a subset of platforms that RetroPie
supports.  The reasons for this are:

* Limits on platform access
* Limits on development time / focus

It would be amazing to continue to officially support more platforms, but
those will either have to be external contributions or added when there's
a personal need for them.

## Raspberry Pi OS

### Debian 10 / Buster

Raspberry Pi OS Buster (Debian 10) is currently the default version and has
pre-made images provided by RetroPie.  This is also the same version that
retrokit provides images for.

Sources:

* [Download image](https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-legacy)

### Debian 11 / Bullseye

Raspbery Pi OS Bullseye (Debian 11) support is currently in beta by RetroPie.
Bullseye is officially supported by the retrokit project, with the following
exceptions:

* Nintendo 64 / mupen64plus-GLideN64 does not work
* Only the 32-bit image has been tested

Sources:

* [Download image](https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-32-bit)

Since a pre-made image isn't yet provided by RetroPie, you can build by downloading
the image above and running the following commands:

```bash
# Enable SSH (if you're going to run these commands over SSH)
sudo systemctl enable ssh
sudo systemctl start ssh

# Install RetroPie-Setup
sudo apt-get install git
git clone https://github.com/RetroPie/RetroPie-Setup.git
sudo apt-get update
sudo apt-get -y dist-upgrade
cd RetroPie-Setup
chmod +x retropie_setup.sh

# Install required modules
modules=(
    'raspbiantools apt_upgrade'
    'setup basic_install'
    'bluetooth depends'
    'raspbiantools enable_modules'
    'autostart enable'
    'usbromservice'
    'samba depends'
    'samba install_shares'
    'splashscreen default'
    'splashscreen enable'
    'bashwelcometweak'
    'xpad'
)
for module in "${modules[@]}"; do
  sudo ./retropie_packages.sh $module
done

# Start fresh
sudo reboot

# Install retrokit
cd $HOME
git clone git@github.com:obrie/retrokit.git
cd retrokit
echo 'export PROFILES=${PROFILES:-platform-rpi-bullseye,filter-demo}' > .env

# Set up retrokit
bin/setup.sh install
```

That *should* be it!
