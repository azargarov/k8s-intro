#!/usr/bin/env bash
set -euo pipefail

source ../../utils.sh

NAME="web1"
IMAGE="nginx:alpine"
HOST_PORT="8080"
CONTAINER_PORT="80"

st=1
total=6
PID=""
IP=""

cleanup() {
  docker rm -f "$NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# ── step 1 ────────────────────────────────────────────
step "$st" "$total" "pull an image"
((st++))

echo "  docker works with ${GREEN}images${RST} and ${CYAN}containers${RST}"
echo "  an image is a packaged filesystem + metadata"
echo "  a container is a running instance of that image"
echo

command -v docker >/dev/null 2>&1 || {
  echo "  ${YELLOW}docker command not found${RST}"
  exit 1
}

echo "  pulling ${GREEN}${IMAGE}${RST} ..."
docker pull "$IMAGE"

echo
echo "  local images:"
docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}' | {
  read -r header
  printf "  %s\n" "$header"
  grep -E '^nginx[[:space:]]+alpine' || true
}

pause_lab

# ── step 2 ────────────────────────────────────────────
step "$st" "$total" "run a real container"
((st++))

echo "  starting ${GREEN}${NAME}${RST} from ${GREEN}${IMAGE}${RST}"
echo "  publishing host port ${YELLOW}${HOST_PORT}${RST} to container port ${YELLOW}${CONTAINER_PORT}${RST}"
echo
docker run -d --name "$NAME" -p "${HOST_PORT}:${CONTAINER_PORT}" "$IMAGE" >/dev/null

docker ps --filter "name=^/${NAME}$" --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' | sed 's/^/  /'

echo
echo "  open in a browser:"
echo "  ${CYAN}http://localhost:${HOST_PORT}${RST}"

pause_lab

# ── step 3 ────────────────────────────────────────────
step "$st" "$total" "reach the service and check logs"
((st++))

echo "  requesting the nginx page from the host..."
echo
curl -I "http://localhost:${HOST_PORT}" | sed 's/^/  /'

echo
echo "  recent container logs:"
docker logs "$NAME" 2>&1 | tail -n 10 | sed 's/^/  /'

echo
echo "  refresh the page in a browser or run:"
echo "  ${GRAY}\$ curl http://localhost:${HOST_PORT}${RST}"
echo "  then inspect logs again"

pause_lab

# ── step 4 ────────────────────────────────────────────
step "$st" "$total" "inspect metadata from the host"
((st++))

PID="$(docker inspect -f '{{.State.Pid}}' "$NAME")"
IP="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$NAME")"

echo "  Docker created a regular Linux process on the host"
echo
echo "  container name:   ${GREEN}${NAME}${RST}"
echo "  image:            ${GREEN}${IMAGE}${RST}"
echo "  host PID:         ${YELLOW}${PID}${RST}"
echo "  container IP:     ${YELLOW}${IP}${RST}"

echo
echo "  host process view:"
ps -fp "$PID" | sed 's/^/  /'

pause_lab

# ── step 5 ────────────────────────────────────────────
step "$st" "$total" "compare namespaces"
((st++))

echo "  this shell namespaces:"
readlink /proc/$$/ns/* | sed 's/^/  /'

echo
echo "  container process namespaces:"
readlink /proc/"$PID"/ns/* | sed 's/^/  /'

echo
echo "  namespace table for the container process:"
lsns -p "$PID" | sed 's/^/  /'

echo
echo "  same kernel, different namespace inodes"
echo "  this is the bridge back to your earlier labs"

pause_lab

# ── step 6 ────────────────────────────────────────────
step "$st" "$total" "look inside the container"
((st++))

echo "  running a few commands inside ${GREEN}${NAME}${RST}"
echo
docker exec "$NAME" sh -c '
echo "hostname:"
hostname
echo
echo "processes:"
ps
echo
echo "nginx web root:"
ls -l /usr/share/nginx/html
' | sed 's/^/  /'

# ── summary ───────────────────────────────────────────
echo
echo "$SEP"
echo "  ${DIM}what you saw:${RST}"
echo "  ${DIM}- image pulled from a registry${RST}"
echo "  ${DIM}- container started from that image${RST}"
echo "  ${DIM}- service reached through port mapping${RST}"
echo "  ${DIM}- container logs collected by Docker${RST}"
echo "  ${DIM}- isolated namespaces around a normal Linux process${RST}"
echo
echo "  ${DIM}after this script exits, the container is removed${RST}"
echo "$SEP"
echo