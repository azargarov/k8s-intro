#!/usr/bin/env bash
set -euo pipefail

CGROUP="demo-cpu"
CGROUP_PATH="/sys/fs/cgroup/${CGROUP}"
CPU_MAX="20000 100000"   # 20ms every 100ms = ~20% of one CPU
STRESS_CMD=(yes)

PID=""

cleanup() {
    echo
    echo "[cleanup]"

    if [[ -d "${CGROUP_PATH}" ]]; then
        echo 1 | sudo tee "${CGROUP_PATH}/cgroup.kill" > /dev/null 2>&1
        sudo rmdir "${CGROUP_PATH}" 2> /dev/null && echo "done"
    fi
}

trap cleanup EXIT

echo "[1/7] Creating cgroup: ${CGROUP}"
sudo mkdir "${CGROUP_PATH}"

echo "[2/7] Setting CPU limit: ${CPU_MAX}"
echo "${CPU_MAX}" | sudo tee "${CGROUP_PATH}/cpu.max" >/dev/null

echo "cpu.max now contains:"
cat "${CGROUP_PATH}/cpu.max"

echo
echo "[3/7] Starting CPU-hungry process: ${STRESS_CMD[*]} > /dev/null"
"${STRESS_CMD[@]}" > /dev/null &
PID=$!

echo "Workload PID: ${PID}"

echo
echo "[4/7] Moving PID ${PID} into cgroup ${CGROUP}"
echo "${PID}" | sudo tee "${CGROUP_PATH}/cgroup.procs" >/dev/null

echo
echo "[5/7] Waiting 2 seconds so throttling counters can accumulate..."
sleep 2

echo
echo "[6/7] Process state:"
ps -o pid,ppid,stat,%mem,%cpu,cmd -p "${PID}" || true

echo
echo "cpu.max:"
cat "${CGROUP_PATH}/cpu.max"

echo
echo "cpu.stat:"
while read -r line; do
    echo "  ${line}"
done < "${CGROUP_PATH}/cpu.stat"

echo
echo "cgroup.procs:"
cat "${CGROUP_PATH}/cgroup.procs"

echo
echo "[7/7] Interpretation:"
echo "  - cpu.max = ${CPU_MAX}"
echo "  - This means the process may run for 20ms in every 100ms period."
echo "  - That is roughly 20% of one CPU core."
echo "  - If nr_throttled increases, the kernel is actively limiting the process."