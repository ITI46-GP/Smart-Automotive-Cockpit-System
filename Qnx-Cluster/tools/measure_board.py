#!/usr/bin/env python3
"""
Run an already-deployed QnxClusterApp on the QNX guest, capture a
QSG_RENDER_TIMING log, pull it back, and hand it to analyze_frames.py.

This exists so a measurement is one reproducible command instead of a dozen
hand-typed ssh lines -- and so nobody re-types the harness from memory and
re-introduces one of the traps that have already cost this project hours.

FRESHNESS IS ENFORCED, DELIBERATELY
-----------------------------------
The first version of this script wrote to a fixed /tmp/x.log. A previous
root-shell session had left a root-owned /tmp/x.log on the board; running as
qnxuser, the `rm -f` failed silently, the shell redirect was permission-denied,
and the script pulled the *stale* file and printed a confident "STAGE PASSES"
for a binary that had never run. That is the same class of error as the S3
misdiagnosis this whole toolchain exists to prevent: a number that looked
authoritative and described something other than what was being measured.

So this script now: writes to a unique per-run filename that cannot collide
with anything left behind; refuses to continue if that file already exists;
surfaces the launch command's stderr instead of discarding it; confirms the
app is actually running and the log is actually growing before it starts
timing; and verifies the log grew across the measurement window. Every one of
those checks is cheap, and each one corresponds to a way this already failed
or could have failed silently.

Usage:
    python3 tools/measure_board.py                  # 30 s on /tmp/TrialClusterS3
    python3 tools/measure_board.py --remote /tmp/TrialClusterS4 --seconds 45
    python3 tools/measure_board.py --deploy build-qnx/QnxClusterApp

Needs paramiko:  pip install paramiko
"""

import argparse
import os
import posixpath
import subprocess
import sys
import time
import uuid

try:
    import paramiko
except ImportError:
    sys.exit("paramiko not installed:  pip install paramiko")

HOST = "192.168.1.51"
USER = "qnxuser"
PASSWORD = "qnxuser"

# Kept verbatim from the proven harness. QT_FORCE_STDERR_LOGGING is mandatory
# over ssh -- without it Qt logs to slog2 and the log file comes back empty.
# QT_LOGGING_TO_CONSOLE is deprecated in Qt 6.10; do not substitute it.
ENV = (
    "export LD_LIBRARY_PATH=/qt/lib:/proc/boot:/lib:/usr/lib:/lib/dll:"
    "/lib/dll/pci:/opt/someip/libs:/usr/lib/graphics/iMX8QM; "
    "export QT_PLUGIN_PATH=/qt/plugins QML_IMPORT_PATH=/qt/qml "
    "QT_QUICK_CONTROLS_STYLE=Basic; "
    "export QQNX_PHYSICAL_SCREEN_SIZE=154,87; "
    "export QSG_RENDER_TIMING=1; "
    "export QT_FORCE_STDERR_LOGGING=1; "
    "export FONTCONFIG_FILE=/tmp/fonts.conf; "
)


def connect():
    c = paramiko.SSHClient()
    c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    c.connect(HOST, username=USER, password=PASSWORD, timeout=15)
    return c


def run(c, cmd, timeout=60):
    """Run a command, returning (stdout, stderr). Never discard stderr at the
    call site -- a silent permission error there is what caused the stale-log
    incident described above."""
    _, out, err = c.exec_command(cmd, timeout=timeout)
    return out.read().decode(errors="replace"), err.read().decode(errors="replace")


def remote_size(c, path):
    """Byte size of a remote file, or None if it doesn't exist. Uses `ls -l`
    because this board's shell is minimal (no stat, no awk)."""
    out, _ = run(c, f"ls -l {path} 2>/dev/null")
    parts = out.split()
    if len(parts) >= 5 and parts[4].isdigit():
        return int(parts[4])
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--remote", default="/tmp/TrialClusterS3",
                    help="path of the app on the board (default %(default)s)")
    ap.add_argument("--seconds", type=int, default=30,
                    help="measurement window (default %(default)s)")
    ap.add_argument("--deploy", metavar="LOCAL_BINARY",
                    help="scp this binary to --remote before running")
    ap.add_argument("--out", default="x.log", help="local log path (default %(default)s)")
    # NOTE: pass this with an '=' -- `--app-args=--no-ticks`, not
    # `--app-args --no-ticks`. argparse sees a value that begins with '--' as
    # another option and errors with "expected one argument".
    ap.add_argument("--app-args", default="",
                    help="arguments passed to the app on target. Use the '=' form: "
                         "--app-args=--no-ticks")
    ap.add_argument("--keep-remote-log", action="store_true",
                    help="don't delete the log from the board afterwards")
    ap.add_argument("--no-analyze", action="store_true")
    args = ap.parse_args()

    app_name = posixpath.basename(args.remote)
    # Unique per run: a leftover file from any earlier session -- possibly owned
    # by root and therefore neither removable nor writable by us -- can never be
    # mistaken for this run's output.
    remote_log = f"/tmp/qnxmeasure-{app_name}-{uuid.uuid4().hex[:8]}.log"

    c = connect()

    if remote_size(c, remote_log) is not None:
        sys.exit(f"{remote_log} already exists -- refusing to run. "
                 "This should be impossible; investigate before trusting any number.")

    # Never leave a previous instance running: it competes for the display and
    # silently skews the numbers.
    run(c, f"slay {app_name} 2>/dev/null; true")
    time.sleep(1)

    if args.deploy:
        local_size = os.path.getsize(args.deploy)
        print(f"deploying {args.deploy} ({local_size} bytes) -> {args.remote}")
        sftp = c.open_sftp()
        sftp.put(args.deploy, args.remote)
        sftp.chmod(args.remote, 0o755)
        sftp.close()
        deployed = remote_size(c, args.remote)
        if deployed != local_size:
            sys.exit(f"deploy verification failed: local {local_size} bytes, "
                     f"remote {deployed}. Aborting rather than measuring the wrong binary.")
        print(f"deploy verified: {deployed} bytes on target")

    # The harness exports FONTCONFIG_FILE=/tmp/fonts.conf to skip a slow
    # fontconfig fallback search, but nothing was ever putting that file on the
    # board -- it was silently pointing at a missing path. Ship it every run.
    fonts_conf = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fonts.conf")
    if os.path.exists(fonts_conf):
        sftp = c.open_sftp()
        sftp.put(fonts_conf, "/tmp/fonts.conf")
        sftp.close()
    else:
        print("warning: tools/fonts.conf missing; FONTCONFIG_FILE will dangle")

    launch = f"{args.remote} {args.app_args}".strip()
    print(f"launching {launch}, logging to {remote_log}")
    _, launch_err = run(c, f"{ENV} {launch} >{remote_log} 2>&1 &")
    if launch_err.strip():
        sys.exit(f"launch command wrote to stderr, refusing to continue:\n{launch_err}")

    # Confirm the app really started and is really writing before we start the
    # clock. Without this, a crash-on-start produces an empty log and a
    # meaningless analysis several minutes later.
    first = None
    for _ in range(10):
        time.sleep(1)
        first = remote_size(c, remote_log)
        if first:
            break
    if not first:
        out, _ = run(c, f"cat {remote_log} 2>/dev/null | head -40")
        ps, _ = run(c, f"pidin ar 2>/dev/null | grep {app_name}")
        sys.exit("log never started growing -- the app probably failed to launch.\n"
                 f"log head:\n{out}\nmatching processes:\n{ps or '(none)'}")

    print(f"running for {args.seconds}s ...")
    time.sleep(args.seconds)

    last = remote_size(c, remote_log)
    run(c, f"slay {app_name} 2>/dev/null; true")
    time.sleep(1)

    if last is None or last <= first:
        sys.exit(f"log did not grow during the measurement window "
                 f"({first} -> {last} bytes). The app died early; do not trust "
                 "any analysis of this file.")

    sftp = c.open_sftp()
    sftp.get(remote_log, args.out)
    sftp.close()
    if not args.keep_remote_log:
        run(c, f"rm -f {remote_log}")
    c.close()

    size = os.path.getsize(args.out)
    if size != last:
        print(f"warning: pulled {size} bytes but remote reported {last}")
    print(f"pulled {remote_log} -> {args.out} ({size} bytes)\n")

    if not args.no_analyze:
        here = os.path.dirname(os.path.abspath(__file__))
        r = subprocess.run([sys.executable, os.path.join(here, "analyze_frames.py"),
                            args.out])
        return r.returncode
    return 0


if __name__ == "__main__":
    sys.exit(main())
