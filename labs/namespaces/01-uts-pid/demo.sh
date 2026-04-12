#!/usr/bin/env bash
set -euo pipefail

source ../../utils.sh

TOTAL=4

banner "uts + pid namespace"

step 1 "$TOTAL" "host state before entering namespaces"
echo "  current host hostname : ${GREEN}$(hostname)${RST}"
echo "  current shell PID     : ${YELLOW}$$${RST}"
echo
echo "  namespace links of this host shell:"
printf "  uts -> ${PURPLE}"
readlink /proc/$$/ns/uts
printf "${RST}"
printf "  pid -> ${PURPLE}"
readlink /proc/$$/ns/pid
printf "${RST}"

pause_lab

step 2 "$TOTAL" "what this lab is about"
echo "  we will create:"
echo "  - a ${GREEN}new UTS namespace${RST}   → private hostname view"
echo "  - a ${GREEN}new PID namespace${RST}   → private process numbering"
echo
echo "  inside that shell, PID numbering starts fresh."
echo "  from the host, the same processes still exist as ordinary host processes."
echo
tip "open a second terminal on the host during the lab"
echo "  useful commands from that second terminal:"
echo "  ${GRAY}\$ hostname${RST}"
echo "  ${GRAY}\$ ps -ef | grep 'uts_pid_lab.sh'${RST}"
echo "  ${GRAY}\$ sudo lsns -t uts,pid${RST}"

pause_lab

step 3 "$TOTAL" "enter the new namespaces"
echo "  running:"
echo "  ${GRAY}\$ sudo unshare --fork --pid --uts --mount-proc ./uts_pid_lab.sh${RST}"
echo
echo "  ${DIM}inside the namespace, the script will pause a few times so people can observe${RST}"
echo

sudo unshare --fork --pid --uts --mount-proc ./uts_pid_lab.sh

step 4 "$TOTAL" "back on the host after namespace exit"
echo "  host hostname now     : ${GREEN}$(hostname)${RST}"
echo "  host shell PID        : ${YELLOW}$$${RST}"
echo
echo "  result:"
echo "  - the host hostname never changed"
echo "  - the private PID namespace disappeared when PID 1 exited"
echo "  - any processes started only inside that namespace were cleaned up with it"
echo
echo "$SEP"
echo "  ${DIM}done${RST}"
echo "$SEP"
