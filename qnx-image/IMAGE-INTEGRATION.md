# QNX image integration — cluster telemetry

For whoever builds the QNX guest image. Everything here is about getting **live CARLA telemetry
into the digital cluster**. Scope is the cluster path only; the TC397 gateway service is a separate,
later step (see "Not in this round" at the bottom).

Verified against the running guest on 2026-08-13, not inferred from docs.

---

## TL;DR — the clean `/opt` update

Four changes in the image and the whole thing resolves:

| # | Change | Fixes |
|---|---|---|
| 1 | `/opt/someip/bin/SomeIPBlClient` — **rebuild** | no output-path support, no atomic write, extra round trip |
| 2 | `/opt/someip/run_client.sh` — **replace** | passes the telemetry path explicitly |
| 3 | `/opt/cluster/bin/QnxClusterApp` — **install** | currently only in `/tmp`, lost on reboot |
| 4 | Start the client **as root** at boot | `/var/vsomeip.lck` is root-owned; as `qnxuser` the client crashes on startup |

Afterwards the data path is simply: client writes `/tmp/telemetry.json` → cluster reads
`/tmp/telemetry.json`. No `/var`, no `received_firmware.bin`, no env-var override needed.

**Unchanged:** `/opt/someip/config/vsomeip.json` (already correct — `unicast: 192.168.1.51`) and
`/opt/someip/libs/` (correct versions: vsomeip 3.5.5, CommonAPI 3.2.4).

> **Interim, before that image lands:** the shipped client ignores the path argument, so launch the
> cluster with `HNC_TELEMETRY_PATH=/var/received_firmware.bin ./QnxClusterApp` — and start the
> client as root, or it will not start at all.

### ★ Item 1 needs AbdelFattah's build environment

The client **cannot** be rebuilt from the cross-sysroot on Mostafa's laptop. The guest image links
**`libc++.so.2`** (LLVM) and has no libstdc++ at all; that sysroot was built against **libstdc++**
(and Boost 1.84 vs the guest's 1.74). A binary built from it dies immediately on target with
`ldd:FATAL: Could not load library libstdc++.so.6` — confirmed by running it on the board.

The deployed binary's RPATH names the machine that can do it:

```
/home/abdo/build-qnx/lib:/home/abdo/build-qnx/install/lib:
/home/abdo/build-qnx/commonapi/lib:/home/abdo/build-qnx/vsomeip/lib:
/home/abdo/Workspace/vsomeip-for-qnx/qnx_final_package/libs
```

So either AbdelFattah rebuilds `SomeIPBlClient` from the updated `someip/src/client.cpp`, or he
shares that libc++ QNX sysroot so anyone can. **The updated `client.cpp` lives in the
`Carla-someip-telemetry` repo and must reach him** — it is not in this repo.

### ★ Item 4 is the one nobody had hit yet

Running the client as `qnxuser` fails before it does anything:

```
[error] is_routing_manager: Could not open /var/vsomeip.lck: Permission denied
[error] configured as routing but other routing manager present
[CAPI][ERROR] Failed to build proxy!
terminate called after throwing an instance of 'std::__2::system_error'
```

`/var/vsomeip.lck` is mode `0200`, root-owned, left by a boot-time run. `VSOMEIP_BASE_PATH` does
not help — `/var/` is compiled into `libvsomeip3.so.3`. `clusterStreaming` does **not** use vsomeip,
so those files are stale leftovers rather than something in use. Either start the client as root
(recommended — that is evidently the original intent) or make sure the image does not leave a
root-owned lock behind when the client runs as `qnxuser`.

---

## The bug, and why the obvious fix does not work

The image ships this launcher:

```sh
cd /var
exec /opt/someip/bin/SomeIPBlClient          # <-- no output path argument
```

while the cluster used to read `/tmp/telemetry.json`. Two different files; they never met.

**Neither side reports an error.** The client logs a verified checksum for every transfer, and the
cluster's read is a plain `if (file.open(...))` that keeps the last value when the file is missing.
Healthy logs on both sides, frozen gauges, nothing pointing at the cause.

The obvious fix — pass the path in `run_client.sh` — **does not work on this image.** Verified on
the guest: the deployed `/opt/someip/bin/SomeIPBlClient` predates output-path support entirely.
Its strings contain neither `CARLA_CLIENT_OUTPUT` nor the `Saving received files to` message, so it
ignores both `argv[1]` and the env var and always writes its built-in `received_firmware.bin`
relative to cwd:

| marker in the deployed binary | |
|---|---|
| `received_firmware.bin` | present |
| `CARLA_CLIENT_OUTPUT` | **absent** |
| `Saving received files to` | **absent** |

Three other routes were tested on the target and rejected:

1. **Rebuild the client** — the guest image links **`libc++.so.2`** (LLVM) and has no libstdc++ at
   all, while the cross-sysroot available to us was built against **libstdc++** (and Boost 1.84 vs
   the guest's 1.74). A binary built from it dies immediately with
   `ldd:FATAL: Could not load library libstdc++.so.6`. Confirmed by running it on the board.
2. **Symlink** `/tmp/telemetry.json` → the client's output — `ln -s` fails with
   *"Function not implemented"*; this filesystem has no symlinks.
3. **Hard link** — same, `ln` fails with *"Function not implemented"*.

So the cluster reads where the client already writes. That is the one piece we can rebuild.

`run_client.sh` in this directory is kept for the day the client **is** rebuilt against a matching
libc++ sysroot: it passes the path explicitly and honours `$CLUSTER_TELEMETRY`. It is a no-op
against the currently shipped binary.

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
