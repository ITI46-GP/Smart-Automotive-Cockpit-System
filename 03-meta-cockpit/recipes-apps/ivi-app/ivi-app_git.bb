# Recipe created by recipetool
# This is the basis of a recipe and may need further editing in order to be fully functional.
# (Feel free to remove these comments when editing.)

# Unable to find any files that looked like license statements. Check the accompanying
# documentation and source headers and set LICENSE and LIC_FILES_CHKSUM accordingly.
#
# NOTE: LICENSE is being set to "CLOSED" to allow you to at least start building - if
# this is not accurate with respect to the licensing of the software being built (it
# will not be in most cases) you must specify the correct value before using this
# recipe for anything other than initial testing/development!
SUMMARY = "GP IVI Qt/QML application"
DESCRIPTION = "Qt/QML IVI application with C++ backend for Raspberry Pi 3B+."
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

SRC_URI = "git://github.com/ITI46-GP/In-vehicle-Infotainment-IVI-System.git;protocol=https;branch=abdelfattah"

# Modify these as desired
PV = "1.0+git"
SRCREV = "6a7f2c227a4bec84452225b5d292fcacf58942e1"

S = "${WORKDIR}/git"

# NOTE: unable to map the following CMake package dependencies: Qt6
inherit qt6-cmake
DEPENDS += " \
    qtbase \
    qtdeclarative \
    qtdeclarative-native \
    qtlocation \
    qtpositioning \
"
RDEPENDS:${PN} += " \
    qt-eglfs-config \
    qtlocation-qmlplugins \
    qtpositioning-qmlplugins \
"

EXTRA_OECMAKE += " \
    -DCMAKE_BUILD_TYPE=Release \
"
