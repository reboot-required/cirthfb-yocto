SUMMARY = "Minimal headless image for the cirthfb e-ink display on Raspberry Pi Zero 2W"
DESCRIPTION = "Boots systemd, auto-loads the cirthfb kernel module via the SPI DT overlay, and starts cirthfbd"
LICENSE = "MIT"

inherit core-image

# devicetree.bbclass deploys to devicetree/ subdirectory; WIC only picks up
# flat .dtbo files automatically. Map explicitly into the boot partition overlays/.
IMAGE_BOOT_FILES:append = " devicetree/cirthfb-overlay.dtbo;overlays/cirthfb-overlay.dtbo"

IMAGE_INSTALL = " \
    packagegroup-core-boot \
    ${CORE_IMAGE_EXTRA_INSTALL} \
    kernel-module-cirthfb \
    cirthfb-overlay \
    cirthfbd \
"
