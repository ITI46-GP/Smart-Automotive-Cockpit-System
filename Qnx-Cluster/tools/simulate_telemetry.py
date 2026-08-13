#!/usr/bin/env python3
"""
Push simulated live telemetry to the NXP board over SFTP, on a loop, so the
production backend (VehicleDataProvider + BottomBarDataProvider, see
src/Backend/) has something real to read instead of sitting at its
hardcoded defaults.

WHY THIS EXISTS
----------------
VehicleDataProvider polls a telemetry file for speed/rpm/gear; nothing was
writing it, so the gauges sat at their hardcoded defaults forever. (First
version of this path was the reference's bare relative "telemetry.json" —
resolved against the app's cwd, /home/qnxuser, which turned out NOT to be
writable on this board despite `ls` succeeding on it; `touch` there fails
with ENOENT. Fixed in VehicleDataProvider.cpp to an absolute /tmp/telemetry.
json instead, consistent with the four /tmp/ivi/*.txt bottom-bar files,
which were already there and already proven writable. Needs a rebuild to
take effect.)

This script is the "someone" that writes those files. It is NOT part of the
app or the build — it stands in for whatever real telemetry source (CARLA,
a real ECU/CAN bridge, etc.) eventually replaces it. Run it from your own
machine, pointed at the board, while the cluster app runs on target.

WRITE SAFETY
------------
VehicleDataProvider does a plain QFile::open + readAll on its 50ms timer,
with no locking. Writing the JSON directly in place risks the reader seeing
a half-written file. Every write here goes to a temp name on the board,
then SFTP `posix_rename`s it over the real name — POSIX rename is atomic,
so the reader only ever sees a complete old or new file, never a partial
one. Same treatment for the plain-text /tmp/ivi files.

USAGE
-----
    pip install paramiko --break-system-packages   # if not already present
    python3 tools/simulate_telemetry.py
    python3 tools/simulate_telemetry.py --host 192.168.1.51 --interval 0.2
    python3 tools/simulate_telemetry.py --no-bottombar   # telemetry.json only
    python3 tools/simulate_telemetry.py --once            # write one sample, exit

Ctrl-C to stop. Prints every sample it sends.
"""

import argparse
import json
import math
import posixpath
import sys
import time

try:
    import paramiko
except ImportError:
    sys.exit("paramiko not installed: pip install paramiko --break-system-packages")

HOST = "192.168.1.51"
USER = "qnxuser"
PASSWORD = "qnxuser"

# Matches VehicleDataProvider.cpp's hardcoded path (see the note there).
TELEMETRY_REMOTE = "/tmp/telemetry.json"
IVI_DIR = "/tmp/ivi"
IVI_FILES = {
    "fuel": posixpath.join(IVI_DIR, "fuel.txt"),
    "engine_temp": posixpath.join(IVI_DIR, "engine_temp.txt"),
    "env_temp": posixpath.join(IVI_DIR, "env_temp.txt"),
    "total_kms": posixpath.join(IVI_DIR, "total_kms.txt"),
}

GEARS = ["P", "R", "N", "D"]


def connect(host):
    c = paramiko.SSHClient()
    c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    c.connect(host, username=USER, password=PASSWORD, timeout=15)
    return c


def atomic_write(sftp, remote_path, text):
    """Write `text` directly to remote_path.

    The original plan here was temp-file-then-rename, so a reader mid-poll
    could never see a half-written file. Tried both `posix_rename` (an
    OpenSSH SFTP extension) and plain SFTP `rename` against this board --
    both come back "Operation unsupported". This QNX target's SFTP server
    doesn't implement rename at all, not just the atomic-overwrite variant,
    so that approach isn't available here.

    Falling back to a single direct write instead. Two things make this an
    acceptable trade rather than a real risk: the payload is under ~200
    bytes, well within one write(2) call and one filesystem block, so a
    torn read is very unlikely in practice; and VehicleDataProvider already
    treats a failed/incomplete read as "keep the last known value" (a
    QFile::open or JSON-parse failure is silently skipped, not a crash), so
    even in the rare case a reader catches this file mid-write, the worst
    outcome is one stale poll cycle, not a bad value reaching the gauges."""
    with sftp.open(remote_path, "w") as f:
        f.write(text)
        f.flush()


def drive_state(t, gear_hold_s=6.0):
    """One smooth, continuously-varying sample as a function of elapsed
    seconds `t` — same spirit as the app's old synthetic `drive` sweep
    (S3's lesson: keep it continuous, not intermittent), just written to
    disk instead of animated in QML. Speed/RPM breathe in a slow sine;
    gear cycles P -> R -> N -> D -> (hold D, varying speed) on a longer
    timer so it looks like an actual drive-off, not random flicker."""
    cycle = t % (gear_hold_s * 4 + 40)
    if cycle < gear_hold_s:
        gear = "P"
        speed, rpm = 0.0, 750.0
    elif cycle < gear_hold_s * 2:
        gear = "R"
        speed, rpm = 8.0 * math.sin(t), 900.0
    elif cycle < gear_hold_s * 3:
        gear = "N"
        speed, rpm = 0.0, 800.0
    else:
        gear = "D"
        drive_t = cycle - gear_hold_s * 3
        speed = max(0.0, 90 + 70 * math.sin(drive_t / 6.0))
        rpm = 900 + speed * 28 + 300 * math.sin(drive_t / 1.3)

    return {
        "speed_kph": round(max(0.0, speed), 1),
        "rpm": round(max(700.0, rpm), 0),
        "gear": gear,
        # Extra CARLA-style fields the schema allows; not read by
        # VehicleDataProvider today but harmless to include.
        "throttle": round(min(1.0, max(0.0, speed / 160.0)), 2),
        "steer": round(0.15 * math.sin(t / 4.0), 3),
        "controller": "simulate_telemetry.py",
    }, speed


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                  formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--host", default=HOST)
    ap.add_argument("--interval", type=float, default=0.2,
                     help="seconds between writes (default 0.2; the app polls every 50ms "
                          "regardless, this just controls how often new values land)")
    ap.add_argument("--once", action="store_true", help="write a single sample and exit")
    ap.add_argument("--duration", type=float, default=0.0,
                     help="stop after this many seconds (default: run until Ctrl-C)")
    ap.add_argument("--no-bottombar", action="store_true",
                     help="only write telemetry.json, skip the /tmp/ivi/*.txt files")
    args = ap.parse_args()

    print(f"connecting to {args.host} ...")
    c = connect(args.host)
    sftp = c.open_sftp()

    if not args.no_bottombar:
        c.exec_command(f"mkdir -p {IVI_DIR}")
        time.sleep(0.3)  # mkdir over a separate channel; give it a beat before sftp writes there

    print(f"writing telemetry to {TELEMETRY_REMOTE}"
          + ("" if args.no_bottombar else f" and {IVI_DIR}/*.txt"))
    print("Ctrl-C to stop\n")

    t0 = time.time()
    fuel = 92.0
    kms = 33560.5
    try:
        while True:
            t = time.time() - t0
            sample, speed = drive_state(t)
            atomic_write(sftp, TELEMETRY_REMOTE, json.dumps(sample))

            if not args.no_bottombar:
                # Fuel drains slowly while moving, engine temp tracks load,
                # env temp is near-static, odometer only goes up.
                fuel = max(0.0, fuel - speed * args.interval / 4000.0)
                engine_temp = 82 + min(28.0, speed / 5.5)
                env_temp = 21.0 + 2.0 * math.sin(t / 40.0)
                kms += speed * args.interval / 3600.0

                atomic_write(sftp, IVI_FILES["fuel"], f"{fuel:.1f}\n")
                atomic_write(sftp, IVI_FILES["engine_temp"], f"{engine_temp:.1f}\n")
                atomic_write(sftp, IVI_FILES["env_temp"], f"{env_temp:.1f}\n")
                atomic_write(sftp, IVI_FILES["total_kms"], f"{kms:.1f}\n")

            print(f"t={t:6.1f}s  speed={sample['speed_kph']:6.1f} kph  "
                  f"rpm={sample['rpm']:6.0f}  gear={sample['gear']}"
                  + ("" if args.no_bottombar else f"  fuel={fuel:5.1f}%  km={kms:9.1f}"))

            if args.once:
                break
            if args.duration and t >= args.duration:
                break
            time.sleep(args.interval)
    except KeyboardInterrupt:
        print("\nstopped.")
    finally:
        sftp.close()
        c.close()


if __name__ == "__main__":
    main()
