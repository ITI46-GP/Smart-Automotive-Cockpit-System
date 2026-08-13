#!/bin/ksh
# QNX guest launcher for the CARLA telemetry SOME/IP client.
# Install to /opt/someip/run_client.sh (root-owned; needs su to replace).
#
# ---------------------------------------------------------------------------
# THE FIX: the output path argument.
#
# The previous version of this script ended with a bare
#
#     cd /var
#     exec /opt/someip/bin/SomeIPBlClient
#
# With no argument and no $CARLA_CLIENT_OUTPUT, the client falls back to its
# built-in default "received_firmware.bin", resolved against the working
# directory -- so it wrote /var/received_firmware.bin while the cluster reads
# /tmp/telemetry.json. The two never met.
#
# Nothing reported an error: the client logged verified checksums for every
# transfer, and the cluster's read is a plain `if (file.open(...))` that simply
# keeps the last value when the file is absent. Healthy logs on both sides,
# frozen gauges, no clue as to why.
#
# The path below MUST match VehicleDataProvider's hardcoded telemetry path in
# Qnx-Cluster (currently /tmp/telemetry.json -- /home/qnxuser is not writable on
# this board). If one changes, change the other.
# ---------------------------------------------------------------------------

CLUSTER_TELEMETRY=${CLUSTER_TELEMETRY:-/tmp/telemetry.json}

export LD_LIBRARY_PATH=/opt/someip/libs:$LD_LIBRARY_PATH
export VSOMEIP_CONFIGURATION=/opt/someip/config/vsomeip.json
export VSOMEIP_APPLICATION_NAME=abdelfattah.examples.SomeIPBl

# Per-transfer logging is off by default -- at 20-50 Hz it costs more than the
# transfer it describes. SOMEIP_VERBOSE=1 ./run_client.sh to debug.
# export SOMEIP_VERBOSE=1

# /var only to keep any incidental relative-path output off /tmp; the telemetry
# file itself is written to the absolute path above regardless of cwd.
cd /var

echo "[run_client] writing telemetry to: $CLUSTER_TELEMETRY"
exec /opt/someip/bin/SomeIPBlClient "$CLUSTER_TELEMETRY"
