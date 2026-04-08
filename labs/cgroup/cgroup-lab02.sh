#!/usr/bin/env bash

sudo mkdir /sys/fs/cgroup/demo-cpu

echo "20000 100000" | sudo tee /sys/fs/cgroup/demo-cpu/cpu.max >/dev/null
echo "demo-cpu/cpu.max = $(cat /sys/fs/cgroup/demo-cpu/cpu.max)"
echo "This means: 20 ms of CPU time every 100 ms (~20% of one CPU)"

yes > /dev/null &
PID=$!

echo "stress PID: $PID"

echo "$PID" | sudo tee /sys/fs/cgroup/demo-cpu/cgroup.procs >/dev/null

sleep 1

echo
echo "Process info:"
ps -o pid,ppid,stat,%mem,%cpu,cmd -p "$PID" || true

echo
echo "demo-cpu/cpu.stat:"
while read -r line; do
    echo "  $line"
done < /sys/fs/cgroup/demo-cpu/cpu.stat

echo
echo "demo-cpu/cgroup.procs:"
cat /sys/fs/cgroup/demo-cpu/cgroup.procs

echo
echo "killing PID: $PID"
kill "$PID"
wait "$PID" 2>/dev/null

echo "deleting demo-cpu cgroup"
sudo rmdir /sys/fs/cgroup/demo-cpu

echo "done"