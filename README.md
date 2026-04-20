# k8s-intro

Hands-on labs and training material for learning Linux primitives, containers, and Kubernetes from first principles.

## Status

This project is actively developed and still evolving.  
The structure, labs, and explanations are being expanded and refined over time.

## Limitations
- macOS will not work
- WSL 1 will not work  
- WSL 2 may work but is not tested — a Linux VM is recommended

## What this repository is about

This repository is built to explain how modern distributed applications work by starting from the Linux building blocks underneath them.

The material starts with core Linux concepts such as:

- namespaces
- cgroups
- process isolation
- filesystem isolation
- network isolation

## Goal

The goal of this project is to provide a practical and understandable path from:

**Linux primitives → containers → container orchestration**

## What you will learn

- how Linux isolates processes, mounts, and networking
- how cgroups enforce CPU and memory limits
- how containers are built 
  
## Quick start

```bash
git clone https://github.com/azargarov/k8s-intro.git
cd k8s-intro
./labs/prerequisites/check.sh 
```

## Suggested prep

- Linux VM or machine with `sudo`
- `util-linux`, `iproute2`, `procps`, `python3` installed
- run `labs/prerequisites/check.sh` before the session

## License

MIT
