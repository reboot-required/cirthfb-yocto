# cirthfb-yocto

[Project Overview](https://github.com/reboot-required/cirthfb-yocto/wiki/Project-Overview)

[Project Plan](https://github.com/users/reboot-required/projects/1/views/1)

[Project Schedule](https://github.com/reboot-required/cirthfb-yocto/wiki/Schedule)

Yocto layer and image recipe for [cirthfb](https://github.com/reboot-required/cirthfb) — a Linux framebuffer driver for the Waveshare 2.13" e-ink display HAT (V4) on the Raspberry Pi Zero 2W.

---

## Hardware Wiring

The display connects to the Raspberry Pi Zero 2W via SPI0. The device tree overlay configures the following GPIO assignments:

| Display Pin | Function | RPi GPIO | Physical Pin |
|-------------|----------|----------|--------------|
| VCC         | Power    | 3.3 V    | Pin 1        |
| GND         | Ground   | GND      | Pin 6        |
| DIN         | MOSI     | GPIO 10  | Pin 19       |
| CLK         | SCLK     | GPIO 11  | Pin 23       |
| CS          | CE0      | GPIO 8   | Pin 24       |
| DC          | Data/Cmd | GPIO 25  | Pin 22       |
| RST         | Reset    | GPIO 17  | Pin 11       |
| BUSY        | Busy     | GPIO 24  | Pin 18       |

The overlay disables the default `spidev0` userspace device and registers the display as `waveshare,epd2in13v4` at SPI0/CS0, 4 MHz.

---

## Repository Structure

```text
cirthfb-yocto/
├── meta-cirthfb/               # custom Yocto layer
│   ├── conf/
│   │   └── layer.conf          # BBPATH, BBFILES, layer priority
│   ├── recipes-app/
│   │   └── cirthfbd/           # systemd daemon recipe
│   ├── recipes-bsp/
│   │   ├── bootfiles/          # rpi-config bbappend (dtoverlay in config.txt)
│   │   └── cirthfb-overlay/    # device tree overlay recipe + DTS source
│   ├── recipes-image/
│   │   └── images/
│   │       └── cirthfb-image.bb
│   └── recipes-kernel/
│       ├── cirthfb/            # out-of-tree kernel module recipe
│       └── linux/              # kernel config fragment (SPI, framebuffer)
├── layers/                     # external layers cloned by setup.sh (not tracked)
│   ├── poky/
│   ├── meta-raspberrypi/
│   └── meta-openembedded/
├── build/                      # BitBake build directory (not tracked)
│   └── conf/
│       ├── bblayers.conf       # managed by setup.sh
│       └── local.conf          # managed by setup.sh
└── setup.sh                    # environment bootstrap script
```

---

## Dependencies

- [Poky](https://git.yoctoproject.org/poky) — pinned to `scarthgap-5.0.16`
- [meta-raspberrypi](https://git.yoctoproject.org/meta-raspberrypi) — `scarthgap` branch
- [meta-openembedded](https://github.com/openembedded/meta-openembedded) — `scarthgap` branch (`meta-oe` sublayer)

---

## Setup

Run `setup.sh` once from the repository root:

```sh
./setup.sh
```

This script:

1. Clones Poky, meta-raspberrypi, and meta-openembedded into `layers/` (skips any already present)
2. Generates `build/conf/bblayers.conf` wiring up all layers including `meta-cirthfb`
3. Generates `build/conf/local.conf` configured for `MACHINE = raspberrypi0-2w-64` with systemd, SPI enabled, and shared download/sstate caches under `~/.yocto/`

> **Note:** `build/conf/bblayers.conf` and `build/conf/local.conf` are managed by `setup.sh` — do not edit them by hand.

---

## Build

After running setup, initialise the BitBake environment and build the image:

```sh
source layers/poky/oe-init-build-env build
bitbake cirthfb-image
```

On success, the flashable image is written to:

```
build/tmp/deploy/images/raspberrypi0-2w-64/cirthfb-image-raspberrypi0-2w-64.rootfs.wic.bz2
```

Shared caches are stored at:

- Downloads: `~/.yocto/downloads`
- sstate: `~/.yocto/sstate-cache`

---

## Flash

Identify the target SD card device (e.g. `/dev/sdX` on Linux, `/dev/diskN` on macOS) and write the image.

**With bmaptool (recommended — faster, verifies blocks):**

```sh
cd build/tmp/deploy/images/raspberrypi0-2w-64
sudo bmaptool copy cirthfb-image-raspberrypi0-2w-64.rootfs.wic.bz2 /dev/sdX
```

**With dd:**

```sh
cd build/tmp/deploy/images/raspberrypi0-2w-64
bzip2 -d -c cirthfb-image-raspberrypi0-2w-64.rootfs.wic.bz2 | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
```

Insert the SD card into the Raspberry Pi Zero 2W, apply power, and the display will show live metrics within 30 seconds.

---

## Yocto Experience

Notes from building this project:

- **Out-of-tree kernel modules** are straightforward with `inherit module` — BitBake handles `depmod` and packaging of the `.ko` automatically. `KERNEL_MODULE_AUTOLOAD` generates the correct `modules-load.d` entry without needing a custom `do_install`.

- **Device tree overlays** use `inherit devicetree` from OE-Core, which compiles the DTS and stages the `.dtbo` under `devicetree/` in the deploy directory. For Raspberry Pi, this path does not match the firmware's expected `overlays/` directory — `IMAGE_BOOT_FILES` must explicitly remap it: `devicetree/cirthfb-overlay.dtbo;overlays/cirthfb-overlay.dtbo`.

- **Systemd service ordering** for driver-dependent daemons is tricky. Using `After=dev-fb1.device` alone causes a race on slow SPI init. A robust alternative is an `ExecStartPre` busy-wait loop that polls for the device node before handing off to `ExecStart`.

- **sstate cache** dramatically cuts rebuild times after the first full build (which takes 2–3 hours on a modern laptop). Storing sstate outside `build/` (e.g. `~/.yocto/sstate-cache`) means it survives a `rm -rf build/`.

- **`LAYERSERIES_COMPAT`** must match the Poky release codename exactly (`scarthgap`). Omitting it causes a parse warning that blocks the build if `BB_WARN_INVALID_RECIPE` is set.
