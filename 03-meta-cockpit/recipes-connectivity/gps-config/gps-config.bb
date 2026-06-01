SUMMARY = "GPS configuration for IVI image"
DESCRIPTION = "Installs gpsd tools and a systemd service for UART GPS module."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://gpsd-ivi.service"

inherit systemd

RDEPENDS:${PN} += " \
    gpsd \
    gps-utils \
"

SYSTEMD_SERVICE:${PN} = "gpsd-ivi.service"
SYSTEMD_AUTO_ENABLE:${PN} = "disable"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/gpsd-ivi.service ${D}${systemd_system_unitdir}/gpsd-ivi.service
}

FILES:${PN} += " \
    ${systemd_system_unitdir}/gpsd-ivi.service \
"
