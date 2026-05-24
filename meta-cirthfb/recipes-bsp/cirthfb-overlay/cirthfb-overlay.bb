SUMMARY = "Device tree overlay for the cirthfb e-ink display on SPI0/CS0"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://cirthfb-overlay.dts;beginline=1;endline=1;md5=fcab174c20ea2e2bc0be64b493708266"

inherit devicetree

SRC_URI = "file://cirthfb-overlay.dts"

COMPATIBLE_MACHINE = "raspberrypi.*"
