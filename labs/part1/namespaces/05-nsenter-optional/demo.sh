#!/usr/bin/env bash

set -euo pipefail

source ../../utils.sh

TOTAL=4

banner "nsenter"

step 1 "$TOTAL" "start an isolated process"
sudo unshare --fork --pid --uts --mount --net --mount-proc bash -c '
  set -euo pipefail
  hostname box1
  ip link set lo up
  echo "[inside isolated shell] hostname: $(hostname)"
  echo "[inside isolated shell] PID: $$"
  exec sleep 600
' &
UNSHARE_PID=$!

sleep 1

step 2 "$TOTAL" "find the target host PID"
PID="$(pgrep -P "$UNSHARE_PID" sleep | tail -n 1 || true)"
if [[ -z "${PID:-}" ]]; then
  echo "  could not find the test process"
  exit 1
fi
echo "  host PID: ${YELLOW}${PID}${RST}"

pause_lab

step 3 "$TOTAL" "inspect namespace links from the host"
sudo readlink /proc/"$PID"/ns/* | sed 's/^/  /'

echo
tip "this is still the host looking at another process"

pause_lab

step 4 "$TOTAL" "enter its namespaces with nsenter"
echo "  type ${GREEN}exit${RST} when finished exploring"
echo
sudo nsenter -t "$PID" -p -u -m -n bash