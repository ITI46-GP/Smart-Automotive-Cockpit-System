SUMMARY = "Touch input configuration for IVI image"
DESCRIPTION = "Installs input test tools and udev permissions for touchscreen devices."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://99-ivi-input.rules"

RDEPENDS:${PN} += " \
    evtest \
    libinput \
    libinput-bin \
"

do_install() {
    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${WORKDIR}/99-ivi-input.rules ${D}${sysconfdir}/udev/rules.d/99-ivi-input.rules
}

FILES:${PN} += " \
    ${sysconfdir}/udev/rules.d/99-ivi-input.rules \
"
