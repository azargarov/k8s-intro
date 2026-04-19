# Mount Namespace Lab

This lab is meant for you who are new to containers and Kubernetes but want to understand one of the Linux building blocks underneath them.

The goal is simple: create a new **mount namespace**, mount a private filesystem there, and verify that the host does **not** see that mount.

---

## What you should understand after this lab

After running this exercise, you should be able to explain:

- what a **mount namespace** is,
- why it gives a process its own view of mounted filesystems,
- why this is useful for containers,
- what **tmpfs** is,
- why a file created on a tmpfs in a private namespace can disappear when the namespace goes away.

This is one of the easiest hands-on ways to see that containers are not magic. They are mostly regular Linux processes with isolation features.

---

## The idea in plain language

A process normally sees the host's mount table: `/`, `/proc`, `/sys`, `/tmp`, disks, bind mounts, and so on.

A **mount namespace** gives a process a different view of that mount table.

That means:

- the process can mount something,
- see that mount inside its own namespace,
- while the host shell does not see that same mount.

This is useful because containers often need their own filesystem view. For example:

- a container may have its own `/proc`,
- its own bind mounts,
- its own volumes,
- its own temporary filesystems.

The important point is this:

**A mount namespace does not create a new disk. It creates a new view of mounts.**

---

## What is `tmpfs`?

`tmpfs` is a temporary memory-backed filesystem.

When you mount `tmpfs`, files written there live in RAM (and depending on system configuration may also interact with swap). In practice for this lab, you can think of it as a temporary filesystem that disappears when it is unmounted.

So in this lab:

- we create a new mount namespace,
- mount a `tmpfs` at `/tmp/ns-demo`,
- create a file there,
- exit the namespace,
- and the mount and file disappear.

That is exactly the kind of behavior people often describe as “ephemeral”.

---

## Files in this lab

### `demo.sh`
Main entry point. It starts a new mount namespace with:

```bash
sudo unshare --fork --mount ./mount.sh
```

Then, after the isolated shell exits, it checks from the host whether `ns-demo` is visible.

### `mount.sh`
Runs **inside** the new mount namespace. It:

1. shows the mount namespace identity,
2. mounts a private `tmpfs` at `/tmp/ns-demo`,
3. pauses so you can inspect from another terminal,
4. writes `inside.txt` into that filesystem,
5. prints the mount namespace symlink,
6. cleans up on exit.

That is enough for the training. Participants can either run `demo.sh` or follow the manual commands from this README.

---

## Prerequisites

You need:

- a Linux machine or VM,
- `sudo` access,
- `unshare` and `lsns` available (usually from `util-linux`),
- `mount`, `readlink`, `awk`, `grep`,
- two terminal windows if possible.

This lab is best run on a training VM or non-critical Linux host.

---

## How to run the scripted lab

From the directory containing the lab files:

```bash
chmod +x demo.sh mount.sh
./demo.sh
```

Notes:

- The scripts source `../../utils.sh`, so in your training repo they should stay in the expected folder structure.
- If someone copies only these two files elsewhere, the pretty formatting from `utils.sh` will be missing.
- The core Linux idea still works even without that helper file; the manual steps below are the fallback version.

---

## What you should observe

### 1. The process is in a different mount namespace
Inside the namespace, the script prints namespace information using `lsns` and `/proc/$$/ns/mnt`.

That is the proof that this shell is not using the same mount namespace view as the host shell.

### 2. The mount exists inside, but not outside
Inside the namespace:

```bash
mount | grep ns-demo
```

should show the mounted `tmpfs`.

On the host terminal at the same time:

```bash
mount | grep ns-demo
```

should show nothing.

That is the key learning moment.

### 3. The file is temporary
Inside the namespace, the script creates:

```bash
/tmp/ns-demo/inside.txt
```

After the namespace exits and cleanup runs, the mount is gone and the file is gone with it (tmpfs).

---

## Manual lab: do it step by step yourself

### Terminal 1: host shell

Check that nothing is mounted yet:

```bash
mount | grep ns-demo || echo "ns-demo not mounted on host"
```

Start a new shell in a new mount namespace:

```bash
sudo unshare --fork --mount bash
```

Now you are inside the new mount namespace.

---

### Terminal 1: inside the new mount namespace

Check the namespace identity:

```bash
echo $$
readlink /proc/$$/ns/mnt
lsns -t mnt -p $$
```

Create a mount point and mount `tmpfs` there:

```bash
mkdir -p /tmp/ns-demo
mount -t tmpfs tmpfs /tmp/ns-demo
```

Verify it from inside:

```bash
mount | grep ns-demo
```

Create a file there:

```bash
echo "hello from mount namespace" > /tmp/ns-demo/inside.txt
ls -l /tmp/ns-demo
cat /tmp/ns-demo/inside.txt
```

---

### Terminal 2: host shell

While Terminal 1 is still inside the namespace, check from the host:

```bash
mount | grep ns-demo || echo "host cannot see the mount"
ls -ld /tmp/ns-demo 2>/dev/null || echo "/tmp/ns-demo is not visible here"
```

Important subtle point:

- if the directory `/tmp/ns-demo` was created on the normal host filesystem before mounting `tmpfs` on top of it, the directory itself may exist,
- but the **mount** and the **file inside the tmpfs** are what matter for this lab.

What you are proving is not “nothing at all exists”.
What you are proving is: **the host does not share the same mount table entry**.

---

### Finish the manual lab

Back in Terminal 1, exit the namespace shell:

```bash
exit
```

Then on the host, verify again:

```bash
mount | grep ns-demo || echo "mount disappeared"
ls -l /tmp/ns-demo 2>/dev/null || true
```

If the directory is still there and empty, remove it:

```bash
sudo rmdir /tmp/ns-demo 2>/dev/null || true
```

---

## Why this matters for containers and Kubernetes

Containers rely on Linux isolation primitives. Mount namespaces are one of them.

A container runtime can use mount namespaces to give a process:

- its own filesystem view,
- its own mounted volumes,
- its own `/proc`,
- its own writable temporary areas,
- and separation from the host's visible mount layout.

Kubernetes itself works at a higher level, but underneath, the container runtime still depends on Linux primitives like:

- namespaces,
- cgroups,
- capabilities,
- seccomp,
- overlay filesystems,
- bind mounts and volumes.

So when you understand this lab, you understand a real piece of what “container isolation” actually means.

---

## Troubleshooting

### `unshare: command not found`
Install `util-linux`.

### `mount: permission denied`
You probably need `sudo` or a training VM configured for this lab.

### The script formatting looks broken
That likely means `../../utils.sh` is not present in the expected place.
Use the manual commands from this README instead.

### The host unexpectedly sees the mount
That usually means mount propagation needs a closer look on that machine. For an intro session, use the prepared training environment where the scripted lab has already been tested.

---

## Minimal takeaway

**A mount namespace gives a process its own view of mounted filesystems, and that is one of the core mechanisms used by containers.**