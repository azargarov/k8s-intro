#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ $EUID -ne 0 ]]; then
  exec sudo -E "$0" "$@"
fi
source "$SCRIPT_DIR/../../utils.sh"


NAME="web1"
IMAGE="nginx:alpine"
HOST_PORT="8080"
CONTAINER_PORT="80"

st=1
total=7
PID=""
IP=""

cleanup() {
  docker rm -f "$NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# ── step 1 ────────────────────────────────────────────
step "$st" "$total" "start a container"
((st++))

echo "  we need a running container to inspect"
echo "  starting ${GREEN}${NAME}${RST} from ${GREEN}${IMAGE}${RST}"
echo

docker rm -f "$NAME" >/dev/null 2>&1 || true
docker run -d --name "$NAME" -p "${HOST_PORT}:${CONTAINER_PORT}" "$IMAGE" >/dev/null

docker ps --filter "name=^/${NAME}$" | sed 's/^/  /'

pause_lab

# ── step 2 ────────────────────────────────────────────
step "$st" "$total" "inspect basic metadata"
((st++))

echo "  Docker keeps metadata about the running container"
echo
PID="$(docker inspect -f '{{.State.Pid}}' "$NAME")"
IP="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$NAME")"

echo "  container name:   ${GREEN}${NAME}${RST}"
echo "  image:            ${GREEN}${IMAGE}${RST}"
echo "  host PID:         ${YELLOW}${PID}${RST}"
echo "  container IP:     ${YELLOW}${IP}${RST}"

echo
echo "  ${DIM}tip: the full metadata is available with:${RST}"
echo "  ${GRAY}\$ docker inspect ${NAME}${RST}"

pause_lab

# ── step 3 ────────────────────────────────────────────
step "$st" "$total" "look at the process on the host"
((st++))

echo "  this is the container workload as seen from the host"
echo "  it is a regular Linux process"
echo
ps -fp "$PID" | sed 's/^/  /'

pause_lab

# ── step 4 ────────────────────────────────────────────
step "$st" "$total" "compare namespaces"
((st++))

echo "  current shell namespace links:"
readlink /proc/$$/ns/* | sed 's/^/  /'

echo
echo "  container process namespace entries:"
ls -l /proc/"$PID"/ns | sed 's/^/  /'

echo
echo "  container process namespace links:"
bash -c "readlink /proc/$PID/ns/*" | sed 's/^/  /'

echo
echo "  namespace table for PID ${YELLOW}${PID}${RST}:"
lsns -p "$PID" | sed 's/^/  /'

echo
echo "  compare the inode values above with your current shell"

echo "  ${DIM}same kernel, different namespace identities${RST}"

pause_lab

# ── step 5 ────────────────────────────────────────────
step "$st" "$total" "check cgroup membership"
((st++))

echo "  namespaces isolate the view"
echo "  cgroups control resources"
echo
echo "  ${DIM}running: cat /proc/${PID}/cgroup${RST}"
echo
cat /proc/"$PID"/cgroup | sed 's/^/  /'

echo
if [[ -d "/proc/${PID}/root/sys/fs/cgroup" ]]; then
  echo "  cgroup files visible from the container root:"
  ls /proc/"$PID"/root/sys/fs/cgroup | head -n 20 | sed 's/^/  /'
fi

pause_lab

# ── step 6 ────────────────────────────────────────────
step "$st" "$total" "look inside the running container"
((st++))

echo "  docker exec enters the environment of the running container"
echo
docker exec "$NAME" sh -c '
echo "hostname:" 
hostname

echo
printf "process list:\n"
ps

echo
printf "root filesystem:\n"
ls /

echo
printf "network view:\n"
if command -v ip >/dev/null 2>&1; then
  ip addr
else
  cat /proc/net/dev
fi
' | sed 's/^/  /'

pause_lab

# ── step 7 ────────────────────────────────────────────
step "$st" "$total" "clean up"
((st++))

echo "  stopping and removing ${GREEN}${NAME}${RST}"
docker stop "$NAME" >/dev/null
docker rm "$NAME" >/dev/null

echo
echo "  ${DIM}what you just confirmed:${RST}"
echo "  ${DIM}- Docker tracks a real host PID${RST}"
echo "  ${DIM}- the container process lives in its own namespaces${RST}"
echo "  ${DIM}- the process also belongs to a cgroup${RST}"
echo "  ${DIM}- docker exec enters that running environment${RST}"

echo
echo "$SEP"
echo "  ${DIM}Docker adds convenience around Linux primitives${RST}"
echo "$SEP"
echo
