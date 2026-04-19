#!/usr/bin/env bash
set -euo pipefail

source ../../utils.sh

cleanup() {
  sudo ip netns del red 2>/dev/null || true
  sudo ip netns del blue 2>/dev/null || true
  sudo ip link del veth-red 2>/dev/null || true
  sudo ip link del veth-blue 2>/dev/null || true
}

trap cleanup EXIT

TOTAL=8

banner "net namespace"

step 1 "$TOTAL" "what this lab is about"
echo "  we will create two isolated network namespaces:"
echo "  - ${GREEN}red${RST}"
echo "  - ${GREEN}blue${RST}"
echo
echo "  each namespace will get its own:"
echo "  - network interface"
echo "  - IP address"
echo "  - loopback device"
echo
echo "  then we will connect them with a ${YELLOW}veth pair${RST}."
echo "  a veth pair is like a virtual patch cable:"
echo "  whatever enters one end comes out of the other."
echo
tip "this is one of the key building blocks behind container networking"

pause_lab

step 2 "$TOTAL" "create two network namespaces"
echo "  creating namespaces ${GREEN}red${RST} and ${GREEN}blue${RST} ..."
sudo ip netns add red
sudo ip netns add blue

echo
echo "  current network namespaces:"
sudo ip netns list | sed 's/^/  /'

echo
tip "from another terminal, you can also run:"
echo "  ${GRAY}\$ sudo ip netns list${RST}"

pause_lab

step 3 "$TOTAL" "create a virtual ethernet pair"
echo "  creating:"
echo "  - ${GREEN}veth-red${RST}"
echo "  - ${GREEN}veth-blue${RST}"
echo
echo "  these two interfaces are connected back-to-back."
sudo ip link add veth-red type veth peer name veth-blue

echo
echo "  host sees them before we move them:"
ip link show veth-red | sed 's/^/  /'
ip link show veth-blue | sed 's/^/  /'

pause_lab

step 4 "$TOTAL" "move each interface into its own namespace"
echo "  moving ${GREEN}veth-red${RST}  -> namespace ${GREEN}red${RST}"
echo "  moving ${GREEN}veth-blue${RST} -> namespace ${GREEN}blue${RST}"
sudo ip link set veth-red netns red
sudo ip link set veth-blue netns blue

echo
echo "  interfaces are now private to their namespaces."
tip "after this, the host no longer manages them directly"

pause_lab

step 5 "$TOTAL" "assign IP addresses"
echo "  assigning:"
echo "  - ${GREEN}10.10.1.1/24${RST} to ${GREEN}red${RST}"
echo "  - ${GREEN}10.10.1.2/24${RST} to ${GREEN}blue${RST}"
sudo ip -n red addr add 10.10.1.1/24 dev veth-red
sudo ip -n blue addr add 10.10.1.2/24 dev veth-blue

echo
echo "  current addresses:"
echo "  ${CYAN}red${RST}:"
sudo ip -n red addr show veth-red | sed 's/^/  /'
echo
echo "  ${CYAN}blue${RST}:"
sudo ip -n blue addr show veth-blue | sed 's/^/  /'

pause_lab

step 6 "$TOTAL" "bring loopback and interfaces up"
echo "  enabling loopback inside each namespace ..."
sudo ip -n red link set lo up
sudo ip -n blue link set lo up

echo "  enabling veth interfaces ..."
sudo ip -n red link set veth-red up
sudo ip -n blue link set veth-blue up

echo
echo "  interface state in ${CYAN}red${RST}:"
sudo ip -n red link show | sed 's/^/  /'
echo
echo "  interface state in ${CYAN}blue${RST}:"
sudo ip -n blue link show | sed 's/^/  /'

echo
tip "loopback is separate per namespace, so it must be brought up inside each one"

pause_lab

step 7 "$TOTAL" "test connectivity between namespaces"
echo "  ping from ${GREEN}red${RST} -> ${GREEN}blue${RST}"
sudo ip netns exec red ping -c 2 10.10.1.2

echo
echo "  ping from ${GREEN}blue${RST} -> ${GREEN}red${RST}"
sudo ip netns exec blue ping -c 2 10.10.1.1

echo
echo "  result:"
echo "  - red and blue are isolated from the host network"
echo "  - but they can talk to each other over the veth link"

pause_lab

step 8 "$TOTAL" "optional exploration before cleanup"
echo "  while this script is still running, try these from another terminal:"
echo
echo "  ${GRAY}\$ sudo ip netns exec red python3 -m http.server 8080${RST}"
echo "  ${GRAY}\$ sudo ip netns exec blue curl http://10.10.1.1:8080${RST}"
echo
echo "  more useful commands:"
echo "  ${GRAY}\$ sudo ip -n red addr${RST}"
echo "  ${GRAY}\$ sudo ip -n blue addr${RST}"
echo "  ${GRAY}\$ sudo ip netns exec red ping 10.10.1.2${RST}"
echo "  ${GRAY}\$ sudo ip netns exec blue bash${RST}"
echo
echo "  when you continue, the script exits and cleanup removes both namespaces."
pause_lab

echo
echo "$SEP"
echo "  ${DIM}leaving lab... cleanup will now remove red, blue, and the veth pair${RST}"
echo "$SEP"