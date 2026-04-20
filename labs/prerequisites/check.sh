#!/usr/bin/env bash
set -euo pipefail

echo "[tools]"
missing=0

for cmd in unshare nsenter ip ps mount lsns readlink sudo; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf "%-10s %s\n" "$cmd" "$(command -v "$cmd")"
  else
    printf "%-10s %s\n" "$cmd" "MISSING"
    ((missing++))
  fi
done

echo
echo "[sudo check]"
if sudo -n true 2>/dev/null; then
  printf "%-10s %s\n" "sudo" "passwordless OK"
else
  printf "%-10s %s\n" "sudo" "will likely ask for password during labs"
fi

echo 
echo "[cgroup v2 check]"
if [ -f /sys/fs/cgroup/cgroup.controllers ]; then 
  printf "%-10s %s\n" "cgroup v2" "mounted OK"
  printf "%-10s controllers: %s\n" "" "$(cat /sys/fs/cgroup/cgroup.controllers)"
else
  printf "%-10s %s\n" "cgroup v2" "not mounted (labs require cgroup v2)"
  ((missing++))
fi

echo
echo "[current shell namespaces]"
for ns in cgroup ipc mnt net pid time user uts; do
  if [[ -e "/proc/$$/ns/$ns" ]]; then
    printf "%-10s %s\n" "$ns" "$(readlink "/proc/$$/ns/$ns")"
  fi
done

echo
if [[ "$missing" -eq 0 ]]; then
  echo "Environment looks OK for the namespace labs."
else
  echo "Some required tools are missing."
  exit 1
fi


