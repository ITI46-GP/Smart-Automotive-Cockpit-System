#!/usr/bin/env bash
# Build for QNX, deploy to the board, run the fps measurement harness, and
# print a burst-aware verdict — one command per stage of the S0..S10 ladder.
#
# Usage:
#   ./tools/deploy_and_measure.sh S5
#   ./tools/deploy_and_measure.sh S5 45              # 45s measurement window
#   ./tools/deploy_and_measure.sh S4 30 --no-text    # pass args to the app
#
# The third argument goes to the app itself. S5 uses it to switch its text
# layers off (`--no-text`), so one build measures both S4 and S5 and the delta
# is attributable to the text alone.
#
# Requires: ~/qnx800/qnxsdp-env.sh, the QNX Qt kit at ~/Qt/6.10.2/qnx_aarch64,
# ssh access to the board, and `pip install paramiko` for the measure step.
#
# NOTE: read the verdict from analyze_frames.py, not a raw fps average. A UI
# that animates intermittently is idle by design between animations and will
# average out to a tiny fps number while actually holding a locked 60 during
# every burst. That misreading is what stalled S3 for a full session.

set -euo pipefail

STAGE="${1:?Usage: deploy_and_measure.sh <stage e.g. S0, S1, S2...> [seconds] [app-args]}"
SECONDS_WINDOW="${2:-30}"
APP_ARGS="${3:-}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REMOTE_HOST="qnxuser@192.168.1.51"
REMOTE_DIR="/tmp/TrialCluster${STAGE}"
APP="QnxClusterApp"

echo "== [$STAGE] build =="
# shellcheck disable=SC1090
source ~/qnx800/qnxsdp-env.sh
cd "$PROJECT_DIR"
# Full reconfigure: incremental builds do NOT reliably pick up a new file in
# QML_FILES / SOURCES, or a changed include path.
rm -rf build-qnx
mkdir build-qnx
cd build-qnx
~/Qt/6.10.2/qnx_aarch64/bin/qt-cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --parallel 8

echo
echo "== [$STAGE] deploy + measure (${SECONDS_WINDOW}s) =="
cd "$PROJECT_DIR"
python3 tools/measure_board.py \
    --deploy "build-qnx/${APP}" \
    --remote "${REMOTE_DIR}" \
    --seconds "${SECONDS_WINDOW}" \
    --app-args="${APP_ARGS}" \
    --out "build-qnx/${STAGE}.log"

echo
echo "log kept at build-qnx/${STAGE}.log — re-analyse any time with:"
echo "  python3 tools/analyze_frames.py build-qnx/${STAGE}.log"
