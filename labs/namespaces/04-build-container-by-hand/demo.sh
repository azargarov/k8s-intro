#!/usr/bin/env bash
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Please run with sudo"; exit 1; }

source ../../utils.sh

TOTAL=5

banner "build container by hand"

step 1 "$TOTAL" "host state before entering isolated namespaces"
echo "  current host hostname : ${GREEN}$(hostname)${RST}"
echo "  current shell PID     : ${YELLOW}$$${RST}"
echo
echo "  namespace links of this host shell:"
printf "  uts   -> ${PURPLE}"
readlink /proc/$$/ns/uts
printf "${RST}"
printf "  pid   -> ${PURPLE}"
readlink /proc/$$/ns/pid
printf "${RST}"
printf "  mnt   -> ${PURPLE}"
readlink /proc/$$/ns/mnt
printf "${RST}"
printf "  net   -> ${PURPLE}"
readlink /proc/$$/ns/net
printf "${RST}"

pause_lab

step 2 "$TOTAL" "what this lab is about"
echo "  we will combine several isolation mechanisms at once:"
echo "  - ${GREEN}UTS namespace${RST}   → private hostname"
echo "  - ${GREEN}PID namespace${RST}   → private process numbering"
echo "  - ${GREEN}mount namespace${RST} → private mount table"
echo "  - ${GREEN}network namespace${RST} → private network stack"
echo
echo "  this already starts to feel like a container."
echo "  but it is ${YELLOW}not yet a full container runtime${RST}."
echo
echo "  why not?"
echo "  - we are not switching to a separate root filesystem"
echo "  - we are not using cgroups here"
echo "  - there is no image, no runtime, no orchestration"
echo
tip "this is the core idea: a container is still just a Linux process with extra isolation"

pause_lab

#step 3 "$TOTAL" "enter the isolated environment"
#echo "  running:"
#echo "  ${GRAY}\$ sudo unshare --fork --pid --uts --mount --net --mount-proc ./handmade_container.sh${RST}"
#echo
#echo "  ${DIM}inside, the script will pause so you can inspect what changed${RST}"
#echo

#sudo unshare --fork --pid --uts --mount --net --mount-proc ./handmade_container.sh

step 3 "$TOTAL" "enter the isolated environment"
echo "  running:"
echo "  ${GRAY}\$ unshare --fork --pid --uts --mount --net --mount-proc ./handmade_container.sh${RST}"
echo
echo "  ${DIM}inside, the script will pause so you can inspect what changed${RST}"
echo

unshare --fork --pid --uts --mount --net --mount-proc ./handmade_container.sh 
#UNSHARE_PID=$!
#
#sleep 0.2
#
#HOST_CHILD_PID="$(ps -o pid= --ppid "$UNSHARE_PID" | awk 'NR==1 {print $1}')"
#
#echo "  unshare helper PID on host : ${YELLOW}${UNSHARE_PID}${RST}"
#if [[ -n "${HOST_CHILD_PID:-}" ]]; then
#  echo "  isolated shell PID on host : ${YELLOW}${HOST_CHILD_PID}${RST}"
#else
#  echo "  isolated shell PID on host : ${RED}<not found>${RST}"
#fi
#echo
#
#wait "$UNSHARE_PID"


step 4 "$TOTAL" "back on the host after the isolated process exits"
echo "  host hostname now     : ${GREEN}$(hostname)${RST}"
echo "  host shell PID        : ${YELLOW}$$${RST}"
echo
echo "  result:"
echo "  - the host hostname never changed"
echo "  - the private PID namespace disappeared when PID 1 exited"
echo "  - the private mount table disappeared with the namespace"
echo "  - the private network namespace disappeared too"
echo

pause_lab

step 5 "$TOTAL" "mental model"
echo "  what we built is not production container technology."
echo "  but the core ingredients are already visible:"
echo "  - process isolation"
echo "  - hostname isolation"
echo "  - network isolation"
echo "  - mount isolation"
echo
echo "  add a separate root filesystem, cgroups, and a runtime layer..."
echo "  and now you are much closer to what Docker or containerd actually do."
echo
echo "$SEP"
echo "  ${DIM}done${RST}"
echo "$SEP"
