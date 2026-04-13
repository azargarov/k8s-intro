#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-swap-on}"         
CGROUP_NAME="demo-mem"
CGROUP_PATH="/sys/fs/cgroup/${CGROUP_NAME}"
MEM_LIMIT_MB=50
MEM_LIMIT_BYTES=$((MEM_LIMIT_MB * 1024 * 1024))
ALLOC_MB=1024                 
SLEEP_BEFORE_CHECK=5
TOTAL=7


PY_PID=""

cleanup() {
  echo
  echo "[cleanup]"
  if [[ -d "${CGROUP_PATH}" ]]; then
    echo 1 | sudo tee "${CGROUP_PATH}/cgroup.kill" > /dev/null 2>&1
    sudo rmdir "${CGROUP_PATH}" 2>/dev/null && echo "done" 
  fi
}

trap cleanup EXIT

if [[ "${MODE}" != "swap-on" && "${MODE}" != "swap-off" ]]; then
  echo "Usage: $0 [swap-on|swap-off]"
  exit 1
fi

echo "[1/${TOTAL}] creating custom control group: ${CGROUP_NAME}"
sudo mkdir -p "${CGROUP_PATH}"

echo "[2/${TOTAL}] setting memory.max to ${MEM_LIMIT_MB} MiB (${MEM_LIMIT_BYTES} bytes)"
echo "${MEM_LIMIT_BYTES}" | sudo tee "${CGROUP_PATH}/memory.max" >/dev/null
echo "memory.max: $(cat "${CGROUP_PATH}/memory.max")"

if [[ "${MODE}" == "swap-off" ]]; then
  echo "[3/${TOTAL}] setting memory.swap.max to 0"
  echo 0 | sudo tee "${CGROUP_PATH}/memory.swap.max" >/dev/null
else
  echo "[3/${TOTAL}] leaving swap enabled"
fi

echo "memory.swap.max not contains: $(cat "${CGROUP_PATH}/memory.swap.max")"

echo
echo "[4/${TOTAL}] starting memory hungry process..."

python3 memalloc.py &

PY_PID=$!
echo "python pid: ${PY_PID}"

echo "[5/${TOTAL}] adding PID ${PY_PID} to cgroup ${CGROUP_NAME}"
echo "${PY_PID}" | sudo tee "${CGROUP_PATH}/cgroup.procs" >/dev/null

echo
echo "cgroup.procs:"
cat "${CGROUP_PATH}/cgroup.procs"

echo
echo "[6/${TOTAL}] waiting ${SLEEP_BEFORE_CHECK} sec..."
sleep "${SLEEP_BEFORE_CHECK}"

echo
echo "[7/${TOTAL}] checking results"
echo "process state:"
ps -o pid,ppid,stat,%mem,%cpu,cmd -p "${PY_PID}" || true

echo
echo "memory.current:"
cat "${CGROUP_PATH}/memory.current"

echo
echo "memory.swap.current:"
cat "${CGROUP_PATH}/memory.swap.current"

echo
echo "memory.events:"
while read -r line; do
      echo "  ${line}"
done < "${CGROUP_PATH}/memory.events"