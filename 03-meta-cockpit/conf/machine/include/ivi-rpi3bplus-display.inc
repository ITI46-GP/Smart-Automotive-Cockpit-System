# IVI Raspberry Pi 3B+ HDMI LCD 1024x600 configuration

HDMI_FORCE_HOTPLUG = "1"
HDMI_GROUP = "2"
HDMI_MODE = "87"
HDMI_CVT = "1024 600 60 6 0 0 0"
DISABLE_OVERSCAN = "1"
HDMI_DRIVE = "2"

# GPU memory for Qt EGLFS/OpenGL rendering
GPU_MEM = "128"

# Enable Raspberry Pi VC4 graphics support
MACHINE_FEATURES:append = " vc4graphics"
