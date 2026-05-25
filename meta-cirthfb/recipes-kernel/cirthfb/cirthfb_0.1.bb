SUMMARY = "cirthfb e-ink framebuffer driver"
DESCRIPTION = "Out-of-tree Linux kernel module for the Waveshare 2.13inch e-ink HAT V4"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=b234ee4d69f5fce4486a80fdaf4a4263"

inherit module

SRC_URI = "git://github.com/reboot-required/cirthfb;branch=main;protocol=https"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git/driver"

RPROVIDES:${PN} += "kernel-module-cirthfb"
KERNEL_MODULE_AUTOLOAD += "cirthfb"