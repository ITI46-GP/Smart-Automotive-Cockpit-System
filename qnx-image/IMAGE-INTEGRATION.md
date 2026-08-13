# QNX image integration — cluster telemetry

For whoever builds the QNX guest image. Everything here is about getting **live CARLA telemetry
into the digital cluster**. Scope is the cluster path only; the TC397 gateway service is a separate,
later step (see "Not in this round" at the bottom).

Verified against the running guest on 2026-08-13, not inferred from docs.

---

## TL;DR — one file changes

Replace **`/opt/someip/run_client.sh`** in the image with [`run_client.sh`](run_client.sh) from this
directory. That is the whole required change.

Nothing else in `/opt/someip` needs touching: the binary, `vsomeip.json`, and `libs/` are all fine.

---

## The bug

The image currently ships this:

```sh
#!/bin/ksh
export LD_LIBRARY_PATH=/opt/someip/libs:$LD_LIBRARY_PATH
export VSOMEIP_CONFIGURATION=/opt/someip/config/vsomeip.json
export VSOMEIP_APPLICATION_NAME=abdelfattah.examples.SomeIPBl
cd /var
exec /opt/someip/bin/SomeIPBlClient          # <-- no output path
```

`SomeIPBlClient` resolves its output path as:

```
argv[1]  →  $CARLA_CLIENT_OUTPUT  →  "received_firmware.bin"   (built-in fallback, relative to cwd)
```

With no argument and no env var it takes the fallback, and `cd /var` puts it at
**`/var/received_firmware.bin`**.

The cluster reads a hardcoded absolute path, **`/tmp/telemetry.json`**
(`Qnx-Cluster/src/Backend/VehicleDataProvider.cpp`). So the two halves write and read different
files and never meet.

**Why this was hard to spot:** neither side reports an error. The client logs a verified checksum
for every transfer, and the cluster's read is a plain `if (file.open(...))` that just keeps the last
value when the file is missing. You get healthy logs on both sides and frozen gauges, with nothing
anywhere pointing at the cause.

The replacement passes the path explicitly and keeps it overridable via `$CLUSTER_TELEMETRY`.

---

## Where the cluster binary lives

The image has two cluster builds. Make sure the image starts the right one:

| Path | What it is |
|---|---|
| `/opt/cluster/bin/Digital_Cluster_DesignStudioApp` | old Qt Design Studio build — 10 MB, measured at **24 fps / 32 ms polish** |
| `/tmp/QnxClusterApp` | the `Qnx-Cluster` rebuild — 4.3 MB, current, built for 60 fps |

`/tmp` does not survive a reboot, so **the rebuild should be installed to a permanent location in
the image** (e.g. `/opt/cluster/bin/QnxClusterApp`) rather than left in `/tmp`.

Launch it **without** `--simulate` — that flag switches the UI to a synthetic sweep used only for
performance measurement. A plain launch reads the real files.

Required environment (from `Qnx-Cluster/BUILD.md`):

```sh
export LD_LIBRARY_PATH=/qt/lib:/proc/boot:/lib:/usr/lib:/lib/dll:/lib/dll/pci:/opt/someip/libs:/usr/lib/graphics/iMX8QM
export QT_PLUGIN_PATH=/qt/plugins QML_IMPORT_PATH=/qt/qml QT_QUICK_CONTROLS_STYLE=Basic
export QQNX_PHYSICAL_SCREEN_SIZE=154,87
export QT_FORCE_STDERR_LOGGING=1      # mandatory over ssh, else Qt logs to slog2 and you see nothing
```

---

## Writable paths

`/tmp` and `/var` are writable by `qnxuser`; `/opt` is root-owned. `/home/qnxuser` is **not**
writable at all — `touch` there fails with ENOENT even though `ls` on the directory succeeds. That
is why the cluster's telemetry path is `/tmp/telemetry.json` and not something under the user's
home.

If the image gives the cluster a different writable location, change **both**:
`VehicleDataProvider.cpp`'s hardcoded path and `run_client.sh`'s `CLUSTER_TELEMETRY`. They must
match.

---

## Verify after flashing

```sh
# 1. the launcher passes a path
grep SomeIPBlClient /opt/someip/run_client.sh        # must show a path argument

# 2. start it, then drive in CARLA on the laptop
/opt/someip/run_client.sh &

# 3. the telemetry file must change repeatedly, several times per second
ls -l /tmp/telemetry.json; sleep 1; ls -l /tmp/telemetry.json

# 4. and it must NOT be going to the old fallback location
ls -l /var/received_firmware.bin      # should NOT exist / not be growing
```

Gauges should sweep smoothly. If they step once per second, the laptop-side server is stale — that
fix is in `Carla-someip-telemetry` (`someip/src/ServerStubImpl.hpp`) and runs on the **laptop**, not
in this image.

---

## Optional: rebuild `SomeIPBlClient`

Not required. The shipped client works correctly once `run_client.sh` passes it a path.

An updated client exists in `Carla-someip-telemetry` that saves one SOME/IP round trip per update
(terminates on a short read instead of spending an extra call on the empty-array completion
indicator) and moves per-transfer logging behind `SOMEIP_VERBOSE=1`, which matters at 20–50 Hz. It
also needs three QNX portability fixes that are in that repo's CMake:

1. CommonAPI's `OutputStream.hpp` tests `__BYTE_ORDER == __LITTLE_ENDIAN`; QNX has no `<endian.h>`
   and spells them without underscores in `<sys/param.h>`.
2. `-std=c++17` (strict ISO) hides POSIX behind `__EXT_POSIX1_198808` — needs
   `_POSIX_C_SOURCE=200809L`.
3. Sockets live in `libsocket` on QNX, not libc.

Build (QNX SDP 8.0 + a cross-built CommonAPI/vsomeip/Boost sysroot):

```bash
source ~/qnx800/qnxsdp-env.sh
cd carla-someip-telemetry/someip
cmake -S . -B build-qnx \
      -DCMAKE_TOOLCHAIN_FILE=$PWD/cross-compile/qnx-aarch64le.toolchain.cmake \
      -DCROSS_SYSROOT=$HOME/qnx-deps/aarch64le/usr -DCMAKE_BUILD_TYPE=Release
cmake --build build-qnx --target SomeIPBlClient -j
```

Note the guest's `/opt/someip/libs` were built against **Boost 1.74** while that sysroot has
**1.84**. `SomeIPBlClient` does not link Boost directly, so this should be fine — but suspect it
first if a rebuilt client misbehaves at runtime rather than failing to load.

---

## Not in this round

The TC397 gateway service (`hypernova-qnx-gateway`) publishes `/tmp/ivi/fuel.txt` and
`/tmp/ivi/env_temp.txt` for the cluster's bottom bar. That work is done but lives in the
`Android-Apps` repo and is deliberately **not** part of this image round. Until then the bottom bar
shows its provider defaults.

`engine_temp.txt` and `total_kms.txt` have no TC397 signal behind them at all — its sensor frame
carries exactly temperature, humidity and fuel — so those two will keep showing defaults regardless.

---

## Related

- `Qnx-Cluster/BUILD.md` — building the cluster for QNX
- `Qnx-Cluster/PLAN.md` — the perf ladder and every measured finding
- Vault: `01-Nodes/Gateway-NXP/QNX-Cluster-Integration.md` — the full bench runbook
