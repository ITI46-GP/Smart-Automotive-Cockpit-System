#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Deploy the QNX cluster integration artifacts to the guest.
#
#   ./deploy-to-qnx.sh              # deploy everything that is built
#   GUEST=192.168.1.51 ./deploy-to-qnx.sh
#   DEST=/opt/hypernova ./deploy-to-qnx.sh
#
# Copies only what actually exists, verifies each file's size after transfer,
# and prints the exact run commands. Does NOT start anything on the guest.
#
# Full context: Claude-Obsidian-Vault-Docs/01-Nodes/Gateway-NXP/QNX-Cluster-Integration.md
# ---------------------------------------------------------------------------
set -uo pipefail

GUEST="${GUEST:-192.168.1.51}"
USER_NAME="${USER_NAME:-qnxuser}"
# /tmp is the location proven writable on this board; /home/qnxuser is NOT
# (touch fails with ENOENT). Override DEST if the image owner has since chosen
# permanent install locations.
DEST="${DEST:-/tmp}"

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATEWAY_REPO="${GATEWAY_REPO:-$REPO/../../Android-Apps/HyperNova_VehicleGateway_Task_10}"

log()  { printf '\033[1;34m[*]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[ERR]\033[0m %s\n' "$*" >&2; }

# label : local path
#
# Staged into $DEST (writable as qnxuser); the final install into /opt requires
# root, so this script prints the su commands rather than pretending it can do
# it. Verified on the guest 2026-08-13:
#   /opt/someip/bin, /opt/someip/config, /opt/cluster/bin  -> root-owned
#   /tmp, /var                                             -> qnxuser-writable
#
# NOT deployed, deliberately:
#   vsomeip.json  - the guest's /opt/someip/config/vsomeip.json already has the
#                   correct "unicast": "192.168.1.51". The repo copy was the
#                   stale one; it has been corrected to match the board.
#   QnxClusterApp - the build at /tmp/QnxClusterApp already contains both the
#                   /tmp/telemetry.json path and the UDP bind fix.
ARTIFACTS=(
  "SomeIPBlClient|$REPO/carla-someip-telemetry/someip/build-qnx/SomeIPBlClient"
  "run_client.sh|$REPO/carla-someip-telemetry/someip/config/run_client.sh"
  "hypernova-qnx-gateway|$GATEWAY_REPO/qnx-service/build-qnx/hypernova-qnx-gateway"
)

log "Target: ${USER_NAME}@${GUEST}:${DEST}"
if ! ping -c1 -W2 "$GUEST" >/dev/null 2>&1; then
  err "$GUEST is not reachable. Bring the bench link up first:"
  err "  sudo ip addr add 192.168.1.10/24 dev <eth> && sudo ip link set <eth> up"
  exit 1
fi

# Confirm the reply actually came from the bench segment and not from some
# unrelated host reachable via the default route. A stray 192.168.1.51 upstream
# would otherwise happily accept a scp of our binaries.
route_dev=$(ip route get "$GUEST" 2>/dev/null | sed -n 's/.* dev \([^ ]*\).*/\1/p' | head -1)
if [ -z "$route_dev" ]; then
  err "no route to $GUEST"; exit 1
fi
log "reachable via $route_dev"

# Host-key changes are routine here (the guest image gets rebuilt, and QNX
# regenerates its keys), but ssh/scp report them as a bare "lost connection"
# which is genuinely misleading. Detect it and say what actually happened.
if ! ssh_probe=$(timeout 10 ssh -o BatchMode=yes -o ConnectTimeout=5 \
                   "${USER_NAME}@${GUEST}" 'uname -s' 2>&1); then
  case "$ssh_probe" in
    *"REMOTE HOST IDENTIFICATION HAS CHANGED"*|*"HOST KEY VERIFICATION FAILED"*|*"Host key verification failed"*)
      err "The guest's SSH host key changed since it was last recorded."
      err "Expected on this bench after the guest image is rebuilt/reset."
      err "Verify it is really your board, then clear the old key and retry:"
      err "    ssh-keygen -R ${GUEST}"
      exit 1
      ;;
    *"Permission denied"*)
      warn "key-based auth unavailable; scp/ssh will prompt for the password"
      ;;
    *)
      warn "ssh probe inconclusive: $(printf '%s' "$ssh_probe" | head -1)"
      ;;
  esac
else
  ok "ssh OK — guest reports: $ssh_probe"
fi

MISSING=0
SENT=0
for entry in "${ARTIFACTS[@]}"; do
  label="${entry%%|*}"
  path="${entry#*|}"

  if [ ! -f "$path" ]; then
    warn "SKIP $label — not built ($path)"
    MISSING=$((MISSING + 1))
    continue
  fi

  local_size=$(stat -c%s "$path")
  log "sending $label ($local_size bytes)"
  # No -q: it suppresses the reason for a failure, which is how a host-key
  # mismatch ends up looking like an unexplained "lost connection".
  if ! scp "$path" "${USER_NAME}@${GUEST}:${DEST}/"; then
    err "scp failed for $label"
    exit 1
  fi

  # Verify the far side actually has the bytes. A truncated or silently failed
  # copy is the kind of fault that presents later as "the fix didn't work".
  remote_size=$(ssh "${USER_NAME}@${GUEST}" "stat -c%s ${DEST}/$(basename "$path")" 2>/dev/null)
  if [ "$remote_size" != "$local_size" ]; then
    err "$label size mismatch: local $local_size, remote ${remote_size:-<none>}"
    exit 1
  fi
  ok "$label verified on guest"
  SENT=$((SENT + 1))
done

echo
ok "$SENT artifact(s) deployed and size-verified"
[ "$MISSING" -gt 0 ] && warn "$MISSING artifact(s) skipped — see above"

cat <<EOF

--------------------------------------------------------------------------
STAGED to ${DEST}. /opt is root-owned, so finish the install AS ROOT on the
guest (su, then):

  cp ${DEST}/SomeIPBlClient  /opt/someip/bin/SomeIPBlClient
  cp ${DEST}/run_client.sh   /opt/someip/run_client.sh
  chmod +x /opt/someip/bin/SomeIPBlClient /opt/someip/run_client.sh

Then run, in this order:

  # 1. SOME/IP client -- run_client.sh now passes /tmp/telemetry.json.
  #    The old script had NO path argument, so the client wrote
  #    /var/received_firmware.bin while the cluster read /tmp/telemetry.json.
  /opt/someip/run_client.sh &

  # 2. TC397 gateway -> publishes /tmp/ivi/fuel.txt + env_temp.txt
  ${DEST}/hypernova-qnx-gateway &

  # 3. Cluster. Do NOT pass --simulate (that is the synthetic perf sweep).
  export LD_LIBRARY_PATH=/qt/lib:/proc/boot:/lib:/usr/lib:/lib/dll:/lib/dll/pci:/opt/someip/libs:/usr/lib/graphics/iMX8QM
  export QT_PLUGIN_PATH=/qt/plugins QML_IMPORT_PATH=/qt/qml QT_QUICK_CONTROLS_STYLE=Basic
  export QQNX_PHYSICAL_SCREEN_SIZE=154,87 QT_FORCE_STDERR_LOGGING=1
  /tmp/QnxClusterApp

  # Stop tools/simulate_telemetry.py first -- it writes the same file and the
  # two will fight over it.

Then on the laptop: ./06_run_server.sh, ./03_run_carla.sh, ./04_run_telemetry.sh

Confirm data is flowing (size/mtime must change repeatedly while driving):
  ssh ${USER_NAME}@${GUEST} 'ls -l /tmp/telemetry.json; sleep 1; ls -l /tmp/telemetry.json'
--------------------------------------------------------------------------
EOF
