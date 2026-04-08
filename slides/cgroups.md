
# Cgroups

Cgroups are a Linux kernel mechanism for grouping processes and controlling how much CPU, memory, I/O, and process count they can use.
In container terms, cgroups answer the question: **how much resource is this workload allowed to consume?**

## Why they exist

Without limits, one busy process can take too much memory or CPU and hurt the rest of the system.
Cgroups let Linux divide resources between groups of processes in a controlled way.

## Core idea

A cgroup is just a group in a hierarchy.
Processes are attached to that group.
Controllers then apply rules to that group.

Examples:

- `cpu.max` limits CPU time
- `memory.max` limits memory
- `pids.max` limits number of processes


## Where it lives

In cgroup v2, the main interface is the virtual filesystem:

```bash
/sys/fs/cgroup
```

Useful files:

- `cgroup.procs` — which processes belong to the group
- `cgroup.controllers` — available controllers
- `memory.current` — current memory usage
- `memory.max` — memory limit
- `cpu.max` — CPU quota
- `pids.max` — max number of processes

## Minimal demo

Create a group, limit memory, and move a process into it:

```bash
sudo mkdir /sys/fs/cgroup/demo
echo 50000000 | sudo tee /sys/fs/cgroup/demo/memory.max
echo $$ | sudo tee /sys/fs/cgroup/demo/cgroup.procs
cat /sys/fs/cgroup/demo/memory.current
```

## What to observe

If the process stays under the limit, it continues normally.
If it goes too far, Linux starts reclaiming memory and may eventually kill the process.

Useful status files:

- `memory.current`
- `memory.events`
- `cpu.stat`
- `pids.current`


## Takeaway

Cgroups are the kernel-level resource control part of containers.
If you understand `memory.max`, `cpu.max`, `pids.max`, and `cgroup.procs`, you already understand the most important part.

# Links

- https://docs.kernel.org/admin-guide/cgroup-v2.html?utm_source=chatgpt.com