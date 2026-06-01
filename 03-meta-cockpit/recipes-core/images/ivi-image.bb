SUMMARY = "Minimal IVI image for Raspberry Pi 3B+"

DESCRIPTION = "Base bootable image for the IVI project. Hardware features will be added step by step."

LICENSE = "MIT"

inherit core-image

IMAGE_FEATURES:append = " ssh-server-openssh debug-tweaks"


IMAGE_INSTALL:append = " kernel-modules bash iproute2 procps util-linux"

IMAGE_INSTALL:append = " python3 tcpdump wifi-config touch-config audio-config gps-config  qt-eglfs-config ivi-test-app ivi-app"