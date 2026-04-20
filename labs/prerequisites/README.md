# Prerequisites

Before running any lab in this section, verify that your environment is ready.

## Check your environment

```bash
./check.sh
```

The script checks for required tools, confirms cgroup v2 is mounted,
and lists your current shell namespaces.

If anything is marked MISSING, install it before continuing.

## What you need

- Linux host or VM (bare metal or a VM with nested virtualization is fine)
- Kernel 5.x or newer with cgroup v2 mounted
- The following tools available on PATH:

| Tool       | Package (Debian/Ubuntu)  | Used for                        |
|------------|--------------------------|---------------------------------|
| `unshare`  | `util-linux`             | creating new namespaces         |
| `nsenter`  | `util-linux`             | entering existing namespaces    |
| `ip`       | `iproute2`               | network namespace setup         |
| `lsns`     | `util-linux`             | listing active namespaces       |
| `ps`       | `procps`                 | inspecting processes            |
| `mount`    | `mount`                  | mount namespace labs            |
| `python3`  | `python3`                | cgroup workload scripts         |
| `sudo`     | `sudo`                   | most labs run privileged steps  |

Quick install on Debian/Ubuntu:

```bash
sudo apt-get install util-linux iproute2 procps python3
```


## If a lab fails

1. Run `./check.sh` again and look for anything marked MISSING
2. Confirm `sudo` works: `sudo true`
3. Confirm cgroup v2 is mounted: `cat /sys/fs/cgroup/cgroup.controllers`
4. Make sure you are on a Linux host — macOS and WSL 1 will not work

