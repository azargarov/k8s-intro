# Lab: Build a container by hand

This lab combines several Linux isolation features to create something that already **feels like a small container**.

A container is usually just:

- a Linux process
- running in isolated namespaces
- often with resource limits
- usually with a separate root filesystem

## What this lab teaches

After this lab, you should understand that:

- a single Linux process can have its own:
  - hostname`
  - PID view
  - mount table
  - network stack
- combining several namespaces at once makes a process start to feel like a “small machine”
- a private mount table is not the same thing as a fully separate filesystem root
- a new network namespace often starts with only loopback
- the main process inside a PID namespace can appear as **PID 1**
- what Docker and container runtimes do is built on Linux features like these

## Why this matters

This lab demonstrates the Linux kernel building blocks used to create a container:

- UTS namespace → separate hostname
- PID namespace → separate process tree and numbering
- mount namespace → separate mount view
- network namespace → separate network stack

Putting these together gives you the basic skeleton of a container.

## Small theory section

### UTS namespace

UTS namespace gives a process its own hostname and domain name view.

That is why a process can say:

```bash
hostname handmade-container
```

without changing the host machine's hostname.

### PID namespace

PID namespace gives a process its own view of process numbering.

Inside the lab, the first process becomes PID 1 in that namespace.
From the host, the same process still has a normal host PID.

That is one of the reasons a container can look like it has its own init process.

### Mount namespace

Mount namespace gives a process its own mount table.

That means the process can mount something like a `tmpfs` and see it privately, while the host does not see that mount entry in its own mount table.

Important: this does **not automatically mean a separate root filesystem**.
The process may still be working mostly on the host filesystem, just with a private mount view.

### Network namespace

Network namespace gives a process its own network environment.

That includes:

- interfaces
- addresses
- routes
- loopback device

A newly created network namespace is usually very minimal.
Often it starts with only `lo`, and `lo` may be down until you explicitly bring it up.

## What this lab is not

This lab is deliberately incomplete.

It shows the core idea, but it is **not a full container runtime**.

What is still missing:

- no separate root filesystem via `chroot` or `pivot_root`
- no cgroups
- no image management
- no runtime lifecycle
- no bridge, veth, or container networking setup

## Files in this lab

### `demo.sh`

Runs on the **host** and guides through the lab.

It:

- shows host namespace state
- explains what will happen
- launches the isolated process with `unshare`
- returns to the host and summarizes the result

### `handmade_container.sh`

Runs inside the isolated namespaces.

It:

- verifies it is PID 1 in the new PID namespace
- changes hostname inside the new UTS namespace
- brings up loopback in the new network namespace
- mounts a private `tmpfs`
- writes a file inside that mount
- shows process list, interfaces, mounts, and namespace links
- explains what is still missing compared with a real container

## Prerequisites

You need:

- a Linux machine or VM
- `sudo` access
- `unshare`
- `ip`
- `mount`
- `ps`
- `readlink`
- a terminal where you can press keys to continue

Check the important tools:

```bash
which unshare
which ip
which mount
which ps
```

## Recommended way to run the lab

Run it from the lab directory:

```bash
chmod +x demo.sh handmade_container.sh
./demo.sh
```

The host-side script launches the isolated process like this:

```bash
sudo unshare --fork --pid --uts --mount --net --mount-proc ./handmade_container.sh
```

That is the core of the lab.

## What the guided lab does

### Stage 1 — host state

`demo.sh` shows:

- the host hostname
- the current shell PID
- current namespace links for UTS, PID, mount, and net

This is the baseline before the new isolated environment starts.

### Stage 2 — explanation

The script explains that it will create new:

- UTS namespace
- PID namespace
- mount namespace
- network namespace

It also explains that this is still not a full runtime because there is no separate root filesystem and no cgroups.

### Stage 3 — inside the isolated environment

`handmade_container.sh` runs inside the new namespaces and shows:

- host PID vs namespace PID
- hostname change
- loopback inside the private network namespace
- a private `tmpfs` mount
- a file written inside that mount
- process table
- first mount entries
- namespace links

This is the main part of the lab.

### Stage 4 — back on the host

When the inside process exits, the host-side script resumes and confirms that the isolated environment is gone.

### Stage 5 — mental model

The final stage connects the exercise back to real containers:

- namespaces give isolation
- cgroups give resource control
- separate root filesystem gives a more container-like file view
- runtimes automate all of this

## Best way to observe it during exercise

Use **two terminals**.

### Terminal 1

Run the guided lab:

```bash
./demo.sh
```

### Terminal 2

Inspect the host side while the lab pauses:

```bash
hostname
ps -ef | grep handmade_container
sudo lsns
mount | grep container-root
```

What to notice:

- host hostname does not change
- host still sees the process with a normal host PID
- the private tmpfs mount does not show up as a normal host mount entry
- when the main process exits, the isolated environment disappears

## Manual version of the lab

If you want participants to type the important parts themselves instead of using the guided script, use this flow.

### 1. Start a shell in new namespaces

```bash
sudo unshare --fork --pid --uts --mount --net --mount-proc bash
```

Now you are in a new isolated shell.

### 2. Check PID and hostname

```bash
echo $$
hostname
readlink /proc/$$/ns/*
```

You should see that this shell is likely PID 1 in the new PID namespace.

### 3. Change hostname

```bash
hostname handmade-container
hostname
```

From another host terminal:

```bash
hostname
```

The host hostname should remain unchanged.

### 4. Bring up loopback in the new network namespace

```bash
ip addr
ip link set lo up
ip addr
```

You will see that the new namespace is very minimal.

### 5. Mount a private tmpfs

```bash
ROOT=/tmp/container-root
mkdir -p "$ROOT"
mount -t tmpfs tmpfs "$ROOT"
echo "hello from handmade container" > "$ROOT/hello.txt"
mount | grep "$ROOT"
ls -l "$ROOT"
cat "$ROOT/hello.txt"
```

### 6. Inspect the process table

```bash
ps -ef
```

### 7. Inspect mounts

```bash
mount | head -20
```

### 8. Exit

```bash
exit
```

Once PID 1 exits, the namespaces go away.

---

## What to observe

By the end, they should have seen that:

- hostname can be private
- PID numbering can be private
- network namespace can start with only loopback
- mounts can be private
- one process can look surprisingly container-like
- but without a new root filesystem, it is still clearly not a full container

## Troubleshooting

### `unshare: command not found`

Install `util-linux`.

### `ip: command not found`

Install `iproute2`.

### `hostname: you must be root to change the host name`

Run through the `sudo unshare ...` launcher exactly as shown.

### `RTNETLINK answers: Operation not permitted`

The environment may restrict creating namespaces or changing interfaces.
Use a normal Linux VM if needed.

### `mount: permission denied`

Make sure the script really runs inside the `sudo unshare` environment.

### `mountpoint: command not found`

Install `util-linux`, or replace the check with a different mount existence test.
