#!/usr/bin/env bash
set -euo pipefail

source ../../utils.sh

if [[ "$$" -ne 1 ]]; then
  echo "Refusing to run: not PID 1 in a PID namespace."
  exit 1
fi

TOTAL=6
HOST_PID="$(awk '/^NSpid:/ {print $2}' /proc/self/status)"
INNER_PID="$(awk '/^NSpid:/ {print $NF}' /proc/self/status)"

banner "inside: uts + pid namespace"

step 1 "$TOTAL" "namespace identity"
echo "  this shell is running inside:"
echo "  - a ${GREEN}new UTS namespace${RST}"
echo "  - a ${GREEN}new PID namespace${RST}"
echo
echo "  same process, different views:"
echo "  host sees this shell as PID         : ${YELLOW}${HOST_PID}${RST}"
echo "  inside this namespace it is PID     : ${YELLOW}${INNER_PID}${RST}"
echo
echo "  namespace links for this shell:"
printf "  uts -> ${PURPLE}"
readlink /proc/$$/ns/uts
printf "${RST}"
printf "  pid -> ${PURPLE}"
readlink /proc/$$/ns/pid
printf "${RST}"

echo
tip "from a second host terminal, compare with:"
echo "  ${GRAY}\$ ps -fp ${HOST_PID}${RST}"
echo "  ${GRAY}\$ sudo lsns -p ${HOST_PID} -t uts,pid${RST}"
echo "  ${GRAY}\$ hostname${RST}"

pause_lab

step 2 "$TOTAL" "hostname before change"
echo "  current hostname inside namespace: ${GREEN}$(hostname)${RST}"
echo "  current shell PID inside namespace: ${YELLOW}$$${RST}"
echo
echo "  in a PID namespace, the first process usually appears as PID 1."
echo "  in a UTS namespace, hostname can be changed without touching the host view."

pause_lab

step 3 "$TOTAL" "change hostname only inside this UTS namespace"
echo "  changing hostname to ${GREEN}demo-box${RST} ..."
hostname demo-box
echo "  hostname inside namespace is now: ${GREEN}$(hostname)${RST}"
echo
tip "check the host terminal now"
echo "  ${GRAY}\$ hostname${RST}  ${DIM}# should still show the real host name${RST}"

pause_lab

step 4 "$TOTAL" "process table before starting a background job"
echo "  ${DIM}running: ps -ef${RST}"
echo
ps -ef | sed 's/^/  /'

pause_lab

step 5 "$TOTAL" "start a background process inside this PID namespace"
echo "  starting ${GREEN}sleep 300${RST} ..."
sleep 300 &
SLEEP_PID="$!"

HOST_SLEEP_PID="$(awk '/^NSpid:/ {print $2}' /proc/${SLEEP_PID}/status)"
INNER_SLEEP_PID="$(awk '/^NSpid:/ {print $NF}' /proc/${SLEEP_PID}/status)"

echo
echo "  same sleep process, different views:"
echo "  host sees sleep as PID              : ${YELLOW}${HOST_SLEEP_PID}${RST}"
echo "  inside namespace it is PID          : ${YELLOW}${INNER_SLEEP_PID}${RST}"
echo
echo "  process table now:"
ps -ef | sed 's/^/  /'

echo
tip "from the host terminal, inspect both processes:"
echo "  ${GRAY}\$ ps -fp ${HOST_PID},${HOST_SLEEP_PID}${RST}"

pause_lab

step 6 "$TOTAL" "what happens when PID 1 exits"
echo "  this script is PID ${YELLOW}1${RST} inside the new PID namespace."
echo "  when PID 1 exits:"
echo "  - the private PID namespace goes away"
echo "  - remaining processes in that namespace are terminated"
echo "  - the host keeps running normally"
echo
echo "$SEP"
echo "  ${DIM}leaving namespace now...${RST}"
echo "$SEP"
echo
