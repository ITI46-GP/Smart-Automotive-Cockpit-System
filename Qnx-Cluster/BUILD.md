# Building & measuring Qnx-Cluster

## Open in Qt Creator (pure CMake, no Design Studio)
Open `CMakeLists.txt` directly with Qt Creator's "Open Project" — no
`.qmlproject` is used. Select the QNX aarch64 6.10.2 kit for the build
configuration.

## Command-line build (matches the Qt Creator kit)
```
source ~/qnx800/qnxsdp-env.sh
echo $QNX_HOST
echo $QNX_TARGET

cd Qnx-Cluster
rm -rf build-qnx
mkdir build-qnx
cd build-qnx

~/Qt/6.10.2/qnx_aarch64/bin/qt-cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --parallel 8
```

Deploy `build-qnx/QnxClusterApp` (and the Qt QNX runtime libs, same as the old
app) to the board the same way you deploy the current cluster app.

## Measure on the guest
```
export LD_LIBRARY_PATH=/qt/lib:/proc/boot:/lib:/usr/lib:/lib/dll:/lib/dll/pci:/opt/someip/libs:/usr/lib/graphics/iMX8QM
export QT_PLUGIN_PATH=/qt/plugins QML_IMPORT_PATH=/qt/qml QT_QUICK_CONTROLS_STYLE=Basic
export QQNX_PHYSICAL_SCREEN_SIZE=154,87
export QSG_RENDER_TIMING=1
export QT_FORCE_STDERR_LOGGING=1
./QnxClusterApp >/tmp/x.log 2>&1 &
sleep 14; A=$(grep -c "frame rendered" /tmp/x.log)
sleep 15; B=$(grep -c "frame rendered" /tmp/x.log)
slay QnxClusterApp; echo "fps=$(( (B-A)/15 ))"
grep "Frame prepared" /tmp/x.log | tail -5
```

## S0 gate
`polish <= 2 ms`, `render <= 4 ms`, `fps >= 55`. Report the numbers back and
we add S1 (BazelFrame).
