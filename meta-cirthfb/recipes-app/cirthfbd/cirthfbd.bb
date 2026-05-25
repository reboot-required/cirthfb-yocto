SUMMARY = "Cirthfb e-ink display daemon"
DESCRIPTION = "Reads CPU%, RAM%, temperature, and uptime; renders them to the cirthfb e-ink framebuffer"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://../LICENSE;md5=b234ee4d69f5fce4486a80fdaf4a4263"

inherit systemd

SRC_URI = "git://github.com/reboot-required/cirthfb;branch=main;protocol=https"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git/daemon"

SYSTEMD_SERVICE:${PN} = "cirthfbd.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

B = "${S}"

do_compile() {
    oe_runmake CC="${CC}" CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}"
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/cirthfbd ${D}${bindir}/cirthfbd
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${S}/cirthfbd.service ${D}${systemd_system_unitdir}/cirthfbd.service
}

FILES:${PN} += "${systemd_system_unitdir}/cirthfbd.service"
