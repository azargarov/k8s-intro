#!/usr/bin/env bash
set -euo pipefail

echo "creating custom control group: /sys/fs/cgroup/demo-mem"
sudo mkdir -p "/sys/fs/cgroup/demo-mem"

echo "setting memory.max to 50 MiB"
echo "52428800" | sudo tee "/sys/fs/cgroup/demo-mem/memory.max" >/dev/null
echo "memory.max: $(cat "/sys/fs/cgroup/demo-mem/memory.max")"

echo "starting memory hungry process..."

python3 memalloc.py &

PY_PID=$!
echo "python pid: ${PY_PID}"

echo "adding PID ${PY_PID} to cgroup demo-mem"
echo "${PY_PID}" | sudo tee "/sys/fs/cgroup/demo-mem/cgroup.procs" >/dev/null

echo "cgroup.procs:"
cat "/sys/fs/cgroup/demo-mem/cgroup.procs"

echo "waiting 5 sec..."
sleep 5

echo && echo "process state:"
ps -o pid,ppid,stat,%mem,%cpu,cmd -p "${PY_PID}" || true

echo && echo "memory.current:"
cat "/sys/fs/cgroup/demo-mem/memory.current"

echo && echo "memory.swap.current:"
cat "/sys/fs/cgroup/demo-mem/memory.swap.current"

echo && echo "memory.events:"
cat "/sys/fs/cgroup/demo-mem/memory.events"

echo "done"

kill "${PY_PID}" 2>/dev/null || true
wait "${PY_PID}" 2>/dev/null || true

sudo rmdir "/sys/fs/cgroup/demo-mem" 2>/dev/null || true
