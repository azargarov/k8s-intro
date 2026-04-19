#!/usr/bin/env bash
set -euo pipefail

TARGET=/tmp/ns-demo

source ../../utils.sh
st=1
total=5

cleanup() {
  mountpoint -q "$TARGET" && umount "$TARGET" || true
  rmdir "$TARGET" 2>/dev/null || true
}
trap cleanup EXIT

# ── step 1 ────────────────────────────────────────────
step "$st" "$total" "namespace identity"
echo "  this shell is running inside a NEW mount namespace"
echo "  compare the NS inode with your host:"
echo "  ${GRAY}\$ lsns -t mnt -p 1${RST}  ${DIM}# host root namespace${RST}"
echo
lsns -t mnt -p $$ | awk '
  NR==1 { printf "  %s\n", $0; next }
  {
    ns=$1; type=$2; pid=$4
    printf "  \033[38;5;141m%s\033[0m \033[38;5;80m%s\033[0m %s \033[38;5;180m(pid %s)\033[0m\n", ns, type, substr($0, index($0,$3)), pid
  }'


# ── step 2 ────────────────────────────────────────────
step "$st" "$total" "mount a private tmpfs at ${YELLOW}${TARGET}${RST}"
echo "  mounts created here are invisible to the host"
echo
mkdir -p "$TARGET"
mount -t tmpfs tmpfs "$TARGET"
echo "  ${RST} mounted  ${GREEN}${TARGET}${RST}  ${DIM}(type: tmpfs, memory-backed)${RST}"

echo
echo "  ${DIM}tip: open a second terminal and run:${RST}"
echo "  ${GRAY}\$ mount | grep ns-demo${RST}  ${DIM}← should print nothing on the host${RST}"
echo
read -n 1 -srp "  press any key to continue..."
echo

# ── step 3 ────────────────────────────────────────────
step "$st" "$total" "mount table entry (inside namespace only)"
echo "  ${DIM}running: mount | grep ns-demo${RST}"
echo
mount | grep -F -- "$TARGET" | sed "s|$TARGET|${GREEN}&${RST}|g" | sed 's/^/  /'

echo
read -n 1 -srp "  press any key to continue..."
echo

# ── step 4 ────────────────────────────────────────────
step "$st" "$total" "write a file + confirm namespace symlink"
echo "  writing to the private tmpfs..."
echo
echo "hello from mount namespace" > "$TARGET/inside.txt"
ls -lh "$TARGET" | sed 's/^/  /'
echo
printf "  ${GRAY}ns symlink →${RST} ${PURPLE}"
readlink /proc/$$/ns/mnt
printf "${RST}"

# ── summary ───────────────────────────────────────────
echo
echo "$SEP"
echo "  ${DIM}namespace exits after this script returns${RST}"
echo "  ${DIM}tmpfs and its contents vanish with it${RST}"
echo "$SEP"
echo