#!/usr/bin/env bash
set -euo pipefail

source ../../utils.sh

MODE="${1:-swap-on}"
CGROUP_NAME="demo-mem"
CGROUP_PATH="/sys/fs/cgroup/${CGROUP_NAME}"
MEM_LIMIT_MB=50
MEM_LIMIT_BYTES=$((MEM_LIMIT_MB * 1024 * 1024))
ALLOC_MB=1024
SLEEP_BEFORE_CHECK=5
TOTAL=7
PY_PID=""

usage() {
  echo "Usage: $0 [swap-on|swap-off]"
}

cleanup() {
  echo
  echo "$SEP"
  echo "  ${DIM}cleanup${RST}"
  echo "$SEP"

  if [[ -n "${PY_PID}" ]]; then
    kill "${PY_PID}" 2>/dev/null || true
    wait "${PY_PID}" 2>/dev/null || true
  fi

  if [[ -d "${CGROUP_PATH}" ]]; then
    echo "  trying cgroup.kill ..."
    echo 1 | sudo tee "${CGROUP_PATH}/cgroup.kill" >/dev/null 2>&1 || true
    sudo rmdir "${CGROUP_PATH}" 2>/dev/null || true
  fi

  echo "  ${DIM}done${RST}"
}

trap cleanup EXIT

if [[ "${MODE}" != "swap-on" && "${MODE}" != "swap-off" ]]; then
  usage
  exit 1
fi

if [[ ! -f /sys/fs/cgroup/cgroup.controllers ]]; then
  echo "This lab expects cgroup v2 (/sys/fs/cgroup/cgroup.controllers was not found)."
  exit 1
fi

if ! grep -qw memory /sys/fs/cgroup/cgroup.controllers; then
  echo "This system does not expose the memory controller in cgroup v2."
  exit 1
fi

banner "cgroup v2: memory limit lab"

step 1 "$TOTAL" "what this lab is about"
echo "  we will create a ${GREEN}new cgroup${RST} and put one process inside it."
echo "  then we will limit how much ${GREEN}memory${RST} that process may use."
echo
if [[ "${MODE}" == "swap-off" ]]; then
  echo "  mode: ${YELLOW}${MODE}${RST}  → RAM limit only, swap is blocked"
else
  echo "  mode: ${YELLOW}${MODE}${RST}  → RAM limit applies, swap may still be used"
fi
echo
printf "  memory controller available at root: ${PURPLE}"
cat /sys/fs/cgroup/cgroup.controllers
printf "${RST}"
echo
tip "open a second terminal if you want to watch the cgroup while this runs"
echo "  ${GRAY}\$ watch -n 1 cat ${CGROUP_PATH}/memory.current${RST}"
echo "  ${GRAY}\$ watch -n 1 cat ${CGROUP_PATH}/memory.swap.current${RST}"
echo "  ${GRAY}\$ watch -n 1 cat ${CGROUP_PATH}/memory.events${RST}"

pause_lab

step 2 "$TOTAL" "create a child cgroup"
echo "  creating ${GREEN}${CGROUP_PATH}${RST}"
sudo mkdir -p "${CGROUP_PATH}"
echo "  cgroup exists: ${GREEN}yes${RST}"
echo
echo "  current cgroup.procs content:"
cat "${CGROUP_PATH}/cgroup.procs" 2>/dev/null || true

pause_lab

step 3 "$TOTAL" "set memory limits"
echo "  setting ${GREEN}memory.max${RST} to ${YELLOW}${MEM_LIMIT_MB} MiB${RST}"
echo "${MEM_LIMIT_BYTES}" | sudo tee "${CGROUP_PATH}/memory.max" >/dev/null

if [[ "${MODE}" == "swap-off" ]]; then
  echo "  setting ${GREEN}memory.swap.max${RST} to ${YELLOW}0${RST}"
  echo 0 | sudo tee "${CGROUP_PATH}/memory.swap.max" >/dev/null
else
  echo "  leaving ${GREEN}memory.swap.max${RST} unchanged"
fi

echo
echo "  effective limits now:"
echo "  memory.max      : $(cat "${CGROUP_PATH}/memory.max")"
echo "  memory.swap.max : $(cat "${CGROUP_PATH}/memory.swap.max")"
echo
echo "  note: memory.max limits RAM usage inside this cgroup."
echo "  if swap is allowed, the process may survive longer by pushing pages to swap."

pause_lab

step 4 "$TOTAL" "start a memory-hungry process in stopped state"
echo "  starting a Python process..."
echo "  target allocation attempt: ${YELLOW}${ALLOC_MB} MiB${RST}"

python3 ./memalloc.py &
PY_PID="$!"
kill -STOP "${PY_PID}"

echo "  python pid on host: ${YELLOW}${PY_PID}${RST}"
echo "  process was immediately stopped so it cannot allocate yet"

pause_lab

step 5 "$TOTAL" "move the process into the cgroup"
echo "  adding PID ${YELLOW}${PY_PID}${RST} to ${GREEN}${CGROUP_NAME}${RST}"
echo "${PY_PID}" | sudo tee "${CGROUP_PATH}/cgroup.procs" >/dev/null

echo
echo "  cgroup.procs now contains:"
sed 's/^/  /' "${CGROUP_PATH}/cgroup.procs"

pause_lab

step 6 "$TOTAL" "resume the process and wait for the result"
echo "  resuming the process now"
kill -CONT "${PY_PID}"

echo
echo "  waiting for the Python process to finish..."
PY_RC=0
wait "${PY_PID}" || PY_RC=$?

echo "  python exit code: ${YELLOW}${PY_RC}${RST}"

pause_lab

step 7 "$TOTAL" "check the result"
echo "  memory.events:"
sed 's/^/  /' "${CGROUP_PATH}/memory.events"

if [[ -f "${CGROUP_PATH}/memory.peak" ]]; then
  echo
  echo "  memory.peak:"
  sed 's/^/  /' "${CGROUP_PATH}/memory.peak"
fi

if [[ -f "${CGROUP_PATH}/memory.swap.peak" ]]; then
  echo
  echo "  memory.swap.peak:"
  sed 's/^/  /' "${CGROUP_PATH}/memory.swap.peak"
fi

echo
echo "  interpretation:"
if [[ "${MODE}" == "swap-off" ]]; then
  echo "  - RAM was capped at ${MEM_LIMIT_MB} MiB and swap was blocked."
  echo "  - once the process could not stay within that RAM budget, the kernel had little room to rescue it."
  echo "  - in this mode you often see ${YELLOW}oom${RST} / ${YELLOW}oom_kill${RST} counters increase."
else
  echo "  - RAM was capped at ${MEM_LIMIT_MB} MiB, but swap was still available."
  echo "  - the process may stay alive longer because some memory can be pushed to swap."
  echo "  - that usually shows up as non-zero ${YELLOW}memory.swap.current${RST}."
fi

echo "  - the important idea is that cgroups do not create a new process tree or hostname view."
echo "  - they control ${GREEN}resource usage${RST} of ordinary processes that still live in the same Linux system."

echo
echo "$SEP"
echo "  ${DIM}lab finished${RST}"
echo "$SEP"
