# cgroup v2 memory limit lab

This lab demonstrates one of the main jobs of **cgroups**: limiting how many resources a process may use.

In this case, the resource is **memory**.

The lab creates a new child cgroup, sets memory limits on it, starts a Python process that tries to allocate a lot of memory, moves that process into the cgroup, and then observes what the kernel reports.


## What this lab shows

- how to create a child cgroup in **cgroup v2**
- how to set `memory.max`
- how to optionally block swap with `memory.swap.max=0`
- how to move a running process into a cgroup
- how to inspect the result with `memory.events`
- why cgroups are about **resource control**, not namespace-style isolation


## Files

- `demo.sh` — the interactive lab script
- `memalloc.py` — a Python program that keeps allocating memory in chunks


## Requirements

- Linux with **cgroup v2** enabled
- the **memory controller** available in cgroup v2
- `sudo` access
- `python3`
- the shared `../../utils.sh` used by the other labs

The script checks that these exist before running.


## Run

### Default mode: swap allowed

```bash
./demo.sh
```

or explicitly:

```bash
./demo.sh swap-on
```

### Swap blocked

```bash
./demo.sh swap-off
```

## What the script does

### Step 1 — explain the goal

The script introduces the lab and shows whether you are running in:

- `swap-on` mode
- `swap-off` mode

It also suggests opening a second terminal to watch cgroup files while the lab runs.

### Step 2 — create a child cgroup

A new cgroup is created under:

```text
/sys/fs/cgroup/demo-mem
```

This is the resource-control container for the test process.

### Step 3 — set memory limits

The script sets:

- `memory.max = 50 MiB`
- `memory.swap.max = 0` only in `swap-off` mode

So the process gets a very small memory budget compared with the amount it will try to allocate.

### Step 4 — start the Python allocator in stopped state

The Python script is started and immediately stopped with `SIGSTOP`.

That is done intentionally so the process does **not** start consuming memory before it has been placed into the cgroup.

### Step 5 — move the process into the cgroup

The process PID is written to:

```text
/sys/fs/cgroup/demo-mem/cgroup.procs
```

At that point, the process becomes subject to the cgroup limits.

### Step 6 — resume the process and wait

The process is resumed with `SIGCONT` and starts allocating memory.

The shell script waits for the Python process to finish, then records the exit code.

### Step 7 — inspect the result

The script prints:

- `memory.events`
- `memory.peak` if present
- `memory.swap.peak` if present

These files tell the story of what happened under memory pressure.


## What `memalloc.py` does

The Python helper allocates memory in chunks of **10 MiB** until it reaches a target of **1024 MiB** or hits a memory error.

That makes it useful for demonstrating a process that wants far more memory than the cgroup allows.


## Watching from a second terminal

These are useful while the lab is running:

```bash
watch -n 1 cat /sys/fs/cgroup/demo-mem/memory.current
watch -n 1 cat /sys/fs/cgroup/demo-mem/memory.swap.current
watch -n 1 cat /sys/fs/cgroup/demo-mem/memory.events
```

You can also inspect the process itself:

```bash
ps -fp <PID>
cat /proc/<PID>/cgroup
```

## Expected behavior

### `swap-off`

In this mode:

- RAM is capped at **50 MiB**
- swap is blocked

That gives the kernel very little room to keep the process alive.
You will often see `oom` and/or `oom_kill` counters increase in `memory.events`.

### `swap-on`

In this mode:

- RAM is still capped at **50 MiB**
- but swap may still be used

The process may survive longer because some pages can move to swap.
Depending on the system, you may see swap-related counters or different behavior before the process exits.

## Why this matters

Cgroups are one of the core Linux building blocks behind containers.

What cgroups do:

- limit memory
- limit CPU usage
- account for resource consumption
- keep one workload from starving others

## Cleanup

When the lab exits, the script tries to:

- stop or reap the Python process
- use `cgroup.kill` if needed
- remove the child cgroup directory

So each run should leave the system ready for the next demonstration.

