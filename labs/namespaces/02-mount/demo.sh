#!/usr/bin/env bash
set -euo pipefail
source ../../utils.sh

banner "mount namespace"
sudo unshare --fork --mount ./mount.sh

step 5 5 "final"
echo
echo "outside newly created mount namespace"
mount | grep ns-demo || echo "ns-demo not found"
