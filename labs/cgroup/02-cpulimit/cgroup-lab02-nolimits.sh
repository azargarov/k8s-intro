#!/usr/bin/env bash

sudo mkdir /sys/fs/cgroup/demo-cpu

echo "run a process with no computation limits" 

yes > /dev/null &
PID=$!

echo "stress PID: $PID"
sleep 1

echo
echo "Process info:"
ps -o pid,ppid,stat,%mem,%cpu,cmd -p "$PID" || true

echo
echo "killing PID: $PID"
kill "$PID"
wait "$PID" 2>/dev/null

echo "done"