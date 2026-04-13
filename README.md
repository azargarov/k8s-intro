# k8s-intro

Hands-on labs and training material for learning Linux primitives, containers, and Kubernetes from first principles.

## Status

This project is actively developed and still evolving.  
The structure, labs, and explanations are being expanded and refined over time.

## What this repository is about

This repository is built to explain how modern distributed applications work by starting from the Linux building blocks underneath them.

Instead of treating containers and Kubernetes as black boxes, the material starts with core Linux concepts such as:

- namespaces
- cgroups
- process isolation
- filesystem isolation
- network isolation

From there, the labs move toward the ideas behind containers and, later, Kubernetes.

## Goal

The goal of this project is to provide a practical and understandable path from:

**Linux primitives → containers → container orchestration**

This material is especially useful for:

- beginners who want to understand what containers really are
- engineers who use Docker or Kubernetes but want a deeper foundation
- training sessions where concepts should be demonstrated step by step

## Current lab structure

```text
labs/
├── namespaces/
│   ├── 00-prerequisites/
│   ├── 01-uts-pid/
│   ├── 02-mount/
│   ├── 03-network/
│   └── 04-build-a-container-by-hand/
```

## Suggested run order

1. `00-prerequisites/check.sh`
2. `01-uts-pid/demo.sh`
3. `02-mount/demo.sh`
4. `03-network/demo.sh`
5. `04-build-a-container-by-hand/demo.sh`

## What you will learn

By working through the labs, you should get a clearer understanding of:

- why containers are not virtual machines
- how Linux isolates processes, hostname, mounts, and networking
- how a container can be assembled from kernel features
- why these ideas matter for modern application delivery
- how these concepts connect to Docker and Kubernetes

## Notes

The repository is still being actively developed.  
Some labs are already usable, while others may still change in structure, wording, or scope.

## License

MIT
