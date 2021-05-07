#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  sudo apt install raspberrypi-kernel-headers build-essential bc git wget bison flex libssl-dev make libncurses-dev
  mkdir "$tmp_dir/kernel"
  pushd "$tmp_dir/kernel"

  # Clone the latest kernel sources (5.10)
  git clone --depth=1 --branch rpi-5.10.y https://github.com/raspberrypi/linux
  pushd linux

  # Setup the kernel configuration for compiling
  KERNEL=kernel7l
  make bcm2711_defconfig

  # Make any changes you want to the kernel configuration and append a friendly local version name by using make menuconfig.
  # To change the friendly name, navigate to “General Setup” and select/modify “Local Version – append to kernel release”.
  # (-v7lstephen) Local version - append to kernel release
  make menuconfig

  # Compile the kernel, modules, and device tree blobs.
  make -j4 zImage modules dtbs

  # Install compiled modules.
  make modules_install

  # Copy the kernel, modules, and other files to the boot filesystem.
  cp arch/arm/boot/dts/*.dtb /boot/
  cp arch/arm/boot/dts/overlays/*.dtb* /boot/overlays/
  cp arch/arm/boot/dts/overlays/README /boot/overlays/
  cp arch/arm/boot/zImage /boot/kernel-stephen.img

  # Reboot
  echo 'Reboot to use the new kernel'
}

uninstall() {
}

"${@}"
