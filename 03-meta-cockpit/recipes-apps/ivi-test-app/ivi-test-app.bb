SUMMARY = "Simple QML test application for IVI image"
DESCRIPTION = "A small QML test app used to validate Qt EGLFS, HDMI display, and touch input."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://main.qml \
    file://run-ivi-test \
"

RDEPENDS:${PN} += " \
    qt-eglfs-config \
    qtdeclarative-tools \
"

do_install() {
    install -d ${D}/opt/ivi-test
    install -m 0644 ${WORKDIR}/main.qml ${D}/opt/ivi-test/main.qml

    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/run-ivi-test ${D}${bindir}/run-ivi-test
}

FILES:${PN} += " \
    /opt/ivi-test/main.qml \
    ${bindir}/run-ivi-test \
"
