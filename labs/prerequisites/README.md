# Linux namespaces labs

## Prerequisites

Run:

```bash
./check.sh
```

## Run order:

1. `00-prerequisites/check.sh`
2. `01-uts-pid/demo.sh`
3. `02-mount/demo.sh`
4. `03-network/demo.sh`
5. `04-build-a-container-by-hand/demo.sh`
6. `05-nsenter/demo.sh`

Most labs require `sudo` and a Linux host with `unshare`, `nsenter`, and `iproute2` installed.
If a lab fails, first run ./check.sh again and confirm that sudo works.
