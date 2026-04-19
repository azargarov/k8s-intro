#!/usr/bin/env bash
set -euo pipefail

source ../../utils.sh

NAME="web1"
IMAGE="nginx:alpine"
HOST_PORT="8080"
CONTAINER_PORT="80"

st=1
total=5


cleanup() {
  docker rm -f "$NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# ── step 1 ────────────────────────────────────────────
step "$st" "$total" "pull the nginx image"
((st++))
echo "  pulling ${GREEN}${IMAGE}${RST}"
echo "  an image is a packaged application filesystem"
echo
docker pull "$IMAGE"

pause_lab

# ── step 2 ────────────────────────────────────────────
step "$st" "$total" "start a container"
((st++))
echo "  starting container ${GREEN}${NAME}${RST}"
echo "  mapping host port ${YELLOW}${HOST_PORT}${RST} to container port ${YELLOW}${CONTAINER_PORT}${RST}"
echo
docker run -d --name "$NAME" -p "${HOST_PORT}:${CONTAINER_PORT}" "$IMAGE" >/dev/null
docker ps --filter "name=^/${NAME}$" | sed 's/^/  /'

pause_lab

# ── step 3 ────────────────────────────────────────────
step "$st" "$total" "access the service"
((st++))
echo "  nginx is now listening inside the container"
echo "  Docker published it on the host"
echo
echo "  ${DIM}running: curl -I http://localhost:${HOST_PORT}${RST}"
echo
curl -I "http://localhost:${HOST_PORT}" | sed 's/^/  /'

echo
echo "  open in browser:"
echo "  ${CYAN}http://localhost:${HOST_PORT}${RST}"

pause_lab

# ── step 4 ────────────────────────────────────────────
step "$st" "$total" "view logs"
((st++))
echo "  containers usually write logs to stdout/stderr"
echo "  Docker collects them for you"
echo
docker logs "$NAME" 2>&1 | tail -n 10 | sed 's/^/  /'

echo
echo "  ${DIM}tip: refresh the page, then run:${RST}"
echo "  ${GRAY}\$ docker logs ${NAME}${RST}"

pause_lab

# ── step 5 ────────────────────────────────────────────
step "$st" "$total" "stop and remove the container"
((st++))
echo "  stopping ${GREEN}${NAME}${RST}"
docker stop "$NAME" >/dev/null

echo "  removing ${GREEN}${NAME}${RST}"
docker rm "$NAME" >/dev/null

echo
docker ps -a --filter "name=^/${NAME}$" | sed 's/^/  /' || true

# ── summary ───────────────────────────────────────────
echo
echo "$SEP"
echo "  ${DIM}what you saw:${RST}"
echo "  ${DIM}- image downloaded${RST}"
echo "  ${DIM}- container started from that image${RST}"
echo "  ${DIM}- service exposed on a host port${RST}"
echo "  ${DIM}- logs collected by Docker${RST}"
echo "  ${DIM}- container stopped and removed${RST}"
echo "$SEP"
echo