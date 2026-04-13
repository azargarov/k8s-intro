#!/usr/bin/env bash
set -euo pipefail

source ../../utils.sh

if [[ "$$" -ne 1 ]]; then
  echo "Refusing to run: not PID 1 in a PID namespace."
  exit 1
fi

ROOT=/tmp/container-root

cleanup() {
  mountpoint -q "$ROOT" && umount "$ROOT" || true
  rmdir "$ROOT" 2>/dev/null || true
}
trap cleanup EXIT

TOTAL=7

INNER_PID="$(awk '/^NSpid:/ {print $NF}' /proc/self/status)"

banner "inside: handmade container"

step 1 "$TOTAL" "namespace identity"
echo "  this process is running inside new namespaces:"
echo "  - ${GREEN}UTS${RST}"
echo "  - ${GREEN}PID${RST}"
echo "  - ${GREEN}mount${RST}"
echo "  - ${GREEN}network${RST}"
echo
echo "  same process, different views:"
echo "  inside this namespace it is PID     : ${YELLOW}${INNER_PID}${RST}"
echo
echo "  namespace links for this shell:"
printf "  uts -> ${PURPLE}"
readlink /proc/$$/ns/uts
printf "${RST}"
printf "  pid -> ${PURPLE}"
readlink /proc/$$/ns/pid
printf "${RST}"
printf "  mnt -> ${PURPLE}"
readlink /proc/$$/ns/mnt
printf "${RST}"
printf "  net -> ${PURPLE}"
readlink /proc/$$/ns/net
printf "${RST}"

echo
tip "from another host terminal:"
echo "  ${GRAY}\$ pgrep -af handmade_container.sh${RST}"
echo "  ${GRAY}\$ ps -fp HOST_PID${RST}"
echo "  ${GRAY}\$ sudo lsns -p HOST_PID${RST}"
echo "  ${GRAY}\$ hostname${RST}"

pause_lab

step 2 "$TOTAL" "private hostname"
echo "  hostname before change: ${GREEN}$(hostname)${RST}"
echo "  changing hostname to ${GREEN}handmade-container${RST} ..."
hostname handmade-container
echo "  hostname inside namespace is now: ${GREEN}$(hostname)${RST}"
echo
tip "on the host, ${GRAY}hostname${RST} should still show the real host name"

pause_lab

step 3 "$TOTAL" "private network namespace"
echo "  a new network namespace starts with very little in it."
echo "  usually, only loopback exists and it starts ${YELLOW}down${RST}."
echo
echo "  bringing loopback up ..."
ip link set lo up

echo
echo "  interfaces inside this namespace:"
ip addr | sed 's/^/  /'

echo
tip "notice there is no normal host interface here"
tip "real containers usually get a veth, bridge, or overlay connection from a runtime or CNI"

pause_lab

step 4 "$TOTAL" "private mount table"
echo "  creating ${GREEN}${ROOT}${RST} on /tmp and mounting a private tmpfs on it ..."
mkdir -p "$ROOT"
mount -t tmpfs tmpfs "$ROOT"
echo "hello from handmade container" > "$ROOT/hello.txt"

echo
echo "  mount entry visible inside this namespace:"
mount | grep -F -- "$ROOT" | sed "s|$ROOT|${GREEN}&${RST}|g" | sed 's/^/  /'

echo
echo "  files in that isolated mount:"
ls -l "$ROOT" | sed 's/^/  /'
echo
echo "  file contents:"
sed 's/^/  /' "$ROOT/hello.txt"

echo
tip "the tmpfs mount is private to this mount namespace"
tip "but this is still not a separate root filesystem"

pause_lab

step 5 "$TOTAL" "process view inside the handmade container"
echo "  running: ${DIM}ps -ef${RST}"
echo
ps -ef | sed 's/^/  /'

echo
echo "  this shell is PID ${YELLOW}1${RST} here, which is typical for a container main process."

pause_lab

step 6 "$TOTAL" "first mounts inside this environment"
echo "  first 20 mount lines:"
mount | head -20 | sed 's/^/  /'

echo
echo "  note:"
echo "  - mount view is private"
echo "  - but most of the filesystem is still the host filesystem"
echo "  - we did not chroot or pivot_root into a new root"

pause_lab

step 7 "$TOTAL" "what this does and does not prove"
echo "  what we already have:"
echo "  - private hostname"
echo "  - private PID space"
echo "  - private mount table"
echo "  - private network stack"
echo
echo "  what is still missing for a real container experience:"
echo "  - separate root filesystem"
echo "  - cgroup limits"
echo "  - image packaging"
echo "  - runtime lifecycle management"
echo
echo "$SEP"
echo "  ${DIM}when PID 1 exits, these namespaces go away${RST}"
echo "$SEP"
echo
