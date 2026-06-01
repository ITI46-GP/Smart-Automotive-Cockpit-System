SUMMARY = "Qt EGLFS runtime configuration for IVI image"
DESCRIPTION = "Installs Qt runtime dependencies and EGLFS environment configuration."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://qt-eglfs-env"

RDEPENDS:${PN} += " \
    qtbase \
    qtbase-plugins \
    qtdeclarative \
    qtdeclarative-qmlplugins \
    qtimageformats \
    qtsvg \
    ttf-dejavu-sans \
    qtlocation \
    qtpositioning \
    qtlocation-qmlplugins \
    qtpositioning-qmlplugins \
"

do_install() {
    install -d ${D}${sysconfdir}/default
    install -m 0644 ${WORKDIR}/qt-eglfs-env ${D}${sysconfdir}/default/qt-eglfs
}

FILES:${PN} += " \
    ${sysconfdir}/default/qt-eglfs \
"
