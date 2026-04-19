#!/usr/bin/env bash
set -euo pipefail

source ../../utils.sh

MODE="${1:-limit}"
CGROUP_NAME="demo-cpu"
CGROUP_PATH="/sys/fs/cgroup/${CGROUP_NAME}"
CPU_MAX="20000 100000"   # 20 ms every 100 ms ≈ 20% of one CPU
OBSERVE_SECONDS=2
TOTAL=7
PID=""
PY_RC=0

usage() {
  echo "Usage: $0 [limit|no-limits]"
}

cleanup() {
  echo
  echo "$SEP"
  echo "  ${DIM}cleanup${RST}"
  echo "$SEP"

  if [[ -n "${PID}" ]]; then
    kill "${PID}" 2>/dev/null || true
    wait "${PID}" 2>/dev/null || true
  fi

  if [[ -d "${CGROUP_PATH}" ]]; then
    echo "  trying cgroup.kill ..."
    echo 1 | sudo tee "${CGROUP_PATH}/cgroup.kill" >/dev/null 2>&1 || true
    sudo rmdir "${CGROUP_PATH}" 2>/dev/null || true
  fi

  echo "  ${DIM}done${RST}"
}

trap cleanup EXIT

if [[ "${MODE}" != "limit" && "${MODE}" != "no-limits" ]]; then
  usage
  exit 1
fi

if [[ ! -f /sys/fs/cgroup/cgroup.controllers ]]; then
  echo "This lab expects cgroup v2 (/sys/fs/cgroup/cgroup.controllers was not found)."
  exit 1
fi

if ! grep -qw cpu /sys/fs/cgroup/cgroup.controllers; then
  echo "This system does not expose the cpu controller in cgroup v2."
  exit 1
fi

banner "cgroup v2: cpu throttling lab"

step 1 "$TOTAL" "what this lab is about"
echo "  we will create a ${GREEN}new cgroup${RST} and place one CPU-hungry process inside it."
echo "  then we will observe how the kernel ${GREEN}throttles CPU time${RST} when a limit is set."
echo
if [[ "${MODE}" == "limit" ]]; then
  echo "  mode: ${YELLOW}${MODE}${RST}  → apply cpu.max = ${YELLOW}${CPU_MAX}${RST}"
else
  echo "  mode: ${YELLOW}${MODE}${RST}  → run the same workload without a CPU quota"
fi
echo
printf "  controllers available at root: ${PURPLE}"
cat /sys/fs/cgroup/cgroup.controllers
printf "${RST}"
echo
tip "open a second terminal if you want to watch throttling counters live"
echo "  ${GRAY}\$ watch -n 1 cat ${CGROUP_PATH}/cpu.stat${RST}"
echo "  ${GRAY}\$ watch -n 1 ps -o pid,ppid,stat,%cpu,cmd -p <PID>${RST}"

pause_lab

step 2 "$TOTAL" "create a child cgroup"
echo "  creating ${GREEN}${CGROUP_PATH}${RST}"
sudo mkdir -p "${CGROUP_PATH}"
echo "  cgroup exists: ${GREEN}yes${RST}"
echo
printf "  cpu.max currently: ${PURPLE}"
cat "${CGROUP_PATH}/cpu.max"
printf "${RST}"

pause_lab

step 3 "$TOTAL" "set the CPU policy"
if [[ "${MODE}" == "limit" ]]; then
  echo "  setting ${GREEN}cpu.max${RST} to ${YELLOW}${CPU_MAX}${RST}"
  echo "${CPU_MAX}" | sudo tee "${CGROUP_PATH}/cpu.max" >/dev/null
else
  echo "  leaving ${GREEN}cpu.max${RST} at the default value"
  echo "  this means the workload may use CPU freely if the system has spare time"
fi

echo
echo "  effective cpu.max now: $(cat "${CGROUP_PATH}/cpu.max")"
echo
echo "  note: cpu.max is ${DIM}<quota> <period>${RST}."
echo "  ${YELLOW}20000 100000${RST} means ${YELLOW}20 ms${RST} of CPU time in each ${YELLOW}100 ms${RST} window."
echo "  that is roughly ${YELLOW}20% of one CPU core${RST}."

pause_lab

step 4 "$TOTAL" "start a CPU-hungry process in stopped state"
echo "  starting a shell that will exec ${GREEN}yes > /dev/null${RST} ..."
echo "  it will stop itself immediately so it cannot burn CPU yet"

bash -c 'kill -STOP $$; exec yes > /dev/null' &
PID="$!"

echo "  workload pid on host: ${YELLOW}${PID}${RST}"
echo
printf "  current state: ${PURPLE}"
ps -o pid,ppid,stat,%cpu,cmd -p "${PID}" --no-headers || true
printf "${RST}"

pause_lab
sleep 1

echo
echo "Process info:"
ps -o pid,ppid,stat,%mem,%cpu,cmd -p "$PID" || true

echo
step 5 "$TOTAL" "move the process into the cgroup"
echo "  adding PID ${YELLOW}${PID}${RST} to ${GREEN}${CGROUP_NAME}${RST}"
echo "${PID}" | sudo tee "${CGROUP_PATH}/cgroup.procs" >/dev/null

echo
echo "  cgroup.procs now contains:"
sed 's/^/  /' "${CGROUP_PATH}/cgroup.procs"
echo
tip "from a second terminal, you can inspect the process before it starts running"
echo "  ${GRAY}\$ ps -fp ${PID}${RST}"
echo "  ${GRAY}\$ cat /proc/${PID}/cgroup${RST}"

pause_lab

step 6 "$TOTAL" "resume the process and let counters accumulate"
echo "  resuming the workload now"
kill -CONT "${PID}"
echo
if [[ "${MODE}" == "limit" ]]; then
  echo "  with the quota active, cpu.stat should start showing throttling"
else
  echo "  with no quota, cpu.stat should show usage but little or no throttling"
fi
echo "  observing for ${YELLOW}${OBSERVE_SECONDS}${RST} seconds ..."
sleep "${OBSERVE_SECONDS}"

echo
echo "  process state:"
ps -o pid,ppid,stat,%mem,%cpu,cmd -p "${PID}" | sed 's/^/  /' || true

pause_lab

step 7 "$TOTAL" "check the result"
echo "  cpu.max:"
sed 's/^/  /' "${CGROUP_PATH}/cpu.max"

echo
echo "  cpu.stat:"
sed 's/^/  /' "${CGROUP_PATH}/cpu.stat"

echo
echo "  interpretation:"
if [[ "${MODE}" == "limit" ]]; then
  echo "  - the process tried to consume CPU continuously."
  echo "  - ${YELLOW}nr_periods${RST} shows how many quota periods elapsed."
  echo "  - ${YELLOW}nr_throttled${RST} shows how often the kernel had to hold the process back."
  echo "  - ${YELLOW}throttled_usec${RST} shows how much time was denied because of the quota."
  echo "  - this is the key idea: cgroups do not isolate a new hostname or process tree."
  echo "  - they control ${GREEN}resource usage${RST} of ordinary Linux processes."
else
  echo "  - the same CPU-hungry process ran without an explicit quota."
  echo "  - you should still see usage counters increase."
  echo "  - but ${YELLOW}nr_throttled${RST} should stay at zero or much lower than in limited mode."
  echo "  - this gives you a baseline to compare against the throttled run."
fi

echo
echo "$SEP"
echo "  ${DIM}lab finished${RST}"
echo "$SEP"
