# cgroup v2 CPU throttling lab

This lab demonstrates how Linux **cgroup v2** can control CPU usage of a normal process.

You will:

- create a new child cgroup
- optionally apply a CPU quota with `cpu.max`
- start a CPU-hungry process
- move that process into the cgroup
- observe how the kernel throttles it

## What this lab teaches

This lab focuses on one simple idea:

A process may want to use 100% CPU, but the kernel can limit how much CPU time it is allowed to consume.

In cgroup v2, this is commonly done with:

```bash
cpu.max
```

The value has the form:

```text
<quota> <period>
```

Example:

```text
20000 100000
```

This means:

- the process group may use **20 ms**
- during each **100 ms** period

That is roughly **20% of one CPU core**.

## Prerequisites

This lab expects:

- Linux with **cgroup v2**
- the **cpu** controller available
- `sudo` access
- Bash

## How to run

### Limited mode

This is the main demo.

```bash
./demo.sh limit
```

In this mode the lab sets:

```text
cpu.max = 20000 100000
```

So the workload is allowed about **20% of one CPU**.

### No-limits mode

This gives you a baseline for comparison.

```bash
./demo.sh no-limits
```

In this mode the same workload runs without an explicit CPU quota.

## What the script does

The lab is interactive and pauses between steps.

### 1. Explains the goal

The script introduces the lab and shows the available cgroup controllers.

### 2. Creates a child cgroup

It creates:

```bash
/sys/fs/cgroup/demo-cpu
```

### 3. Sets the CPU policy

In `limit` mode:

```bash
echo "20000 100000" | sudo tee /sys/fs/cgroup/demo-cpu/cpu.max
```

In `no-limits` mode, the default policy is left in place.

### 4. Starts a CPU-hungry process

The workload is:

```bash
yes > /dev/null
```

This is a simple way to create continuous CPU load.

The process starts in a **stopped** state first, so it does not consume CPU before being moved into the cgroup.

### 5. Moves the process into the cgroup

The script writes its PID into:

```bash
cgroup.procs
```

### 6. Resumes the process

The process is continued and allowed to run for a short observation period.

### 7. Shows the result

The script prints:

- `cpu.max`
- `cpu.stat`

and explains what the counters mean.

## Useful counters

The most interesting file is:

```bash
/sys/fs/cgroup/demo-cpu/cpu.stat
```

Common fields include:

- `usage_usec` – total CPU time consumed
- `user_usec` – CPU time spent in user space
- `system_usec` – CPU time spent in kernel space
- `nr_periods` – number of quota periods elapsed
- `nr_throttled` – how many times tasks were throttled
- `throttled_usec` – total time denied due to throttling

In **limited** mode, you should see throttling counters increase.

In **no-limits** mode, you should usually see CPU usage increase without much or any throttling.

## Watch it live

It is useful to open a second terminal while the lab is running.

Watch cgroup CPU counters:

```bash
watch -n 1 cat /sys/fs/cgroup/demo-cpu/cpu.stat
```

Watch the process itself:

```bash
ps -fp <PID>
watch -n 1 ps -o pid,ppid,stat,%cpu,cmd -p <PID>
```

Inspect the cgroup membership:

```bash
cat /proc/<PID>/cgroup
```

## Expected behavior

### In `limit` mode

You should observe:

- the process continuously tries to use CPU
- `%CPU` stays much lower than full core usage
- `nr_throttled` increases
- `throttled_usec` increases

This shows the kernel is actively enforcing the quota.

### In `no-limits` mode

You should observe:

- the same process runs freely
- CPU usage is much higher
- throttling counters stay at zero or near zero

This gives a good side-by-side comparison with the limited run.

## Cleanup

The script automatically cleans up on exit.

It will:

- kill the test workload
- try `cgroup.kill`
- remove the child cgroup directory

So repeated runs should not leave junk behind.

## Troubleshooting

### `This lab expects cgroup v2`

Your system is probably using cgroup v1 or a mixed setup.

Check:

```bash
ls /sys/fs/cgroup/cgroup.controllers
```

If that file does not exist, this lab is not running on a pure cgroup v2 system.

### `This system does not expose the cpu controller`

Check available controllers:

```bash
cat /sys/fs/cgroup/cgroup.controllers
```

If `cpu` is missing, this environment does not expose CPU control through cgroup v2.

### Permission errors

This lab creates and configures a cgroup under `/sys/fs/cgroup`, so `sudo` is required.

## Suggested order

A good way to use this lab:

1. run `./demo.sh no-limits`
2. observe `cpu.stat`
3. run `./demo.sh limit`
4. compare the counters
5. discuss what changed and why

That comparison makes the effect much easier to understand.
