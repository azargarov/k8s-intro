# Linux cgroups v2 Labs

These labs demonstrate how Linux cgroups control resource usage of ordinary processes.

## Goal

The goal of these labs is to show how containers are built not only from isolation features such as namespaces, but also from resource-control features provided by cgroups.

A container is primarily:

- a regular Linux process
- running with isolated namespaces
- often constrained by cgroups
- packaged with its own filesystem

## What you will learn

- what cgroups are responsible for in the container model
- how Linux limits memory usage with `memory.max`
- how Linux controls CPU time with `cpu.max`
- how to inspect cgroup state through files such as `memory.events` and `cpu.stat`
- why cgroups control resource consumption rather than system visibility

## Labs

1. `01-memlimit`  
   Create a child cgroup, apply a memory limit, optionally disable swap, and observe what happens when a process tries to allocate more memory than allowed.

2. `02-cpulimit`  
   Create a child cgroup, apply a CPU quota, and observe how the kernel throttles a CPU-hungry process.

## Recommended order

Run the labs in this order:

- `01-memlimit`
- `02-cpulimit`

## Required tools

- Linux with **cgroup v2**
- `sudo`
- `bash`
- `python3`
- the shared `../../utils.sh`

Depending on the lab, the system must expose the required cgroup controllers such as `memory` and `cpu`.

## Important

These labs create temporary child cgroups under `/sys/fs/cgroup` and move running processes into them.  
If a lab fails midway, use the provided cleanup steps to remove anything left behind.

## Key idea

Namespaces and cgroups solve different problems:

- **namespaces** isolate what a process can see
- **cgroups** control how much of a resource a process may use

Together, they form the foundation of the container model.