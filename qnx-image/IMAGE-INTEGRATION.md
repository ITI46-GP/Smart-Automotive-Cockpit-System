# QNX cluster — telemetry path

**Decision: nothing on the QNX guest is touched. Only the Qt cluster changes.**

`Qnx-Cluster` now reads **`/var/received_firmware.bin`** — exactly where the SOME/IP client already
installed on the guest writes. Rebuild `QnxClusterApp` and deploy it; that is the whole change.

Overridable without a rebuild: `HNC_TELEMETRY_PATH=/some/path ./QnxClusterApp`

---

## Why that path

The client and the cluster were reading and writing different files, so telemetry never reached the
gauges — and neither side reported an error. The client logs verified checksums for every transfer;
the cluster's read is a plain `if (file.open(...))` that keeps the last value when the file is
missing. Healthy logs on both sides, frozen gauges.

Verified on the guest 2026-08-13:

- `/opt/someip/bin/SomeIPBlClient` **predates output-path support**. Its bytes contain neither
  `CARLA_CLIENT_OUTPUT` nor the `argv[1]` handling, so it ignores both and always writes its
  built-in `received_firmware.bin` relative to cwd. (Compiled 2026-07-18, but from a checkout older
  than the commit that added those.)
- `/opt/someip/run_client.sh` does `cd /var` → the file lands at `/var/received_firmware.bin`.
- Linking the two paths instead is impossible here: this filesystem implements neither symlink nor
  hard link (`ln` / `ln -s` both fail with *"Function not implemented"*).

So the cluster reads where the client writes. No `/opt` change, no image rebuild for SOME/IP.

---

## ⚠️ The client must run as ROOT

Not caused by this change, but it will stop the demo if the client is started the wrong way.

Started as `qnxuser`, the client dies before doing anything:

```
[error] is_routing_manager: Could not open /var/vsomeip.lck: Permission denied
[CAPI][ERROR] Failed to build proxy!
terminate called after throwing an instance of 'std::__2::system_error'
```

`/var/vsomeip.lck` is root-owned, mode `0200`, created by a boot-time run. `VSOMEIP_BASE_PATH` does
not move it — `/var/` is compiled into `libvsomeip3.so.3`. If the client is already started as root
at boot, nothing to do.

---

## Known limitation

The deployed client does **not** write atomically (no `.tmp` + rename — that came in the same later
commit it is missing). The cluster polls at 20 Hz, so it will occasionally catch a partially written
file. That degrades gracefully: `QJsonDocument::fromJson` fails, the update is skipped, and the last
good values stay on screen. An occasional dropped frame, not a visible fault.

---

## Streaming rate — already fixed, laptop side only

The gauges stepping once per second was a **laptop-side** bug: the SOME/IP server detected file
changes with `st_mtime` (whole-second granularity), capping the whole pipeline at ~1 Hz regardless
of any setting. Fixed in `Carla-someip-telemetry` (`someip/src/ServerStubImpl.hpp`, now `st_mtim`
nanoseconds + size + checksum). Measured end to end over loopback:

| producer | before | after |
|---|---|---|
| 20 Hz | 1.1 Hz | **19.8 Hz** (198/198, no drops) |
| 50 Hz | ~1 Hz | **48.6 Hz** (486/486, no drops) |

Nothing on the guest needed to change for this.

---

## Verify after deploying

```sh
# client must be running (as root) and CARLA driving on the laptop
ls -l /var/received_firmware.bin; sleep 1; ls -l /var/received_firmware.bin
```

Size/timestamp must change repeatedly. Then the gauges should sweep smoothly.
