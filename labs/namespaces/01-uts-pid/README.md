# Lab 1: UTS and PID namespaces

This lab demonstrates two core Linux isolation mechanisms that later become part of how containers work:

- **UTS namespace** — gives a process its own hostname and domain name view
- **PID namespace** — gives a process its own process tree and PID numbering

---

## What this lab teaches

After this lab, you should understand that:

- a process can have its **own hostname view** without changing the real host hostname
- a process can live in a **different PID namespace** and appear as **PID 1** there
- the **same process has different PID views** depending on where you look from
- when **PID 1 exits inside a PID namespace**, that namespace ends and its remaining processes are terminated
- containers are not magic — they are built on Linux process isolation primitives like these

---

## Why this matters

If you later work with Docker or Kubernetes, you constantly deal with isolated processes.

A container is usually just:

- a normal Linux process
- with isolated namespaces
- and limited resources via cgroups

This lab helps build that mental model from the Linux level upward.

---

## Small theory section

### UTS namespace

UTS stands for **UNIX Time-sharing System**, but in practice for this lab it means:

- hostname isolation
- domain name isolation

If a process is in a new UTS namespace, it can change its hostname there without changing the host machine's hostname.

That is why a container can show its own hostname while the real node keeps its original one.

### PID namespace

A PID namespace gives a process its own view of process numbering.

Inside a new PID namespace:

- the first process usually becomes **PID 1**
- child processes get their own local PIDs
- the host still sees them with normal host PIDs

So one process can effectively have **two identities**:

- one PID from the host point of view
- another PID from inside the namespace

### Why PID 1 matters

Inside Linux, PID 1 is special.

In a PID namespace, the first process acts as the “init” process for that namespace. When it exits, the namespace is torn down, and remaining processes in that namespace are normally terminated.

That is an important idea for understanding why containers stop when their main process exits.

---

## Files in this lab

### `demo.sh`

Runs on the **host** and guides through the lab.

It:

- shows the host hostname and current shell PID
- explains what will happen
- starts a new UTS + PID namespace with `unshare`
- returns to the host and summarizes the result

### `uts_pid_lab.sh`

Runs **inside** the new namespaces.

It:

- verifies it is running as PID 1 in the new PID namespace
- shows namespace identity
- changes hostname only inside the UTS namespace
- starts a background `sleep` process
- shows how the same processes look from different views
- explains what happens when PID 1 exits

## Prerequisites

You need:

- a Linux machine
- `sudo` access
- `unshare` available
- `ps`, `awk`, `readlink`
- a terminal where you can press keys to continue through the guided pauses

Check that `unshare` exists:

```bash
which unshare
```

Usually it comes from `util-linux`.

---

## Recommended way to run the lab

Run it from the lab directory:

```bash
chmod +x demo.sh uts_pid_lab.sh
./demo.sh
```

The host-side script starts the namespaced script with:

```bash
sudo unshare --fork --pid --uts --mount-proc ./uts_pid_lab.sh
```

That is the actual core of the lab. The rest is explanation and guided observation.

---

## What the guided lab does

### Stage 1 — host state

`demo.sh` shows:

- the real host hostname
- the current shell PID
- the current UTS and PID namespace links from `/proc/.../ns/...`

This is the reference point before isolation begins.

### Stage 2 — explanation

The script explains that it will create:

- a new UTS namespace for private hostname view
- a new PID namespace for private process numbering

It also suggests opening a second terminal on the host and watching the system from outside.

### Stage 3 — inside the namespaces

`uts_pid_lab.sh` starts inside the new namespaces and immediately checks that it is running as PID 1. Then it shows:

- host PID vs namespace PID
- namespace links
- current hostname
- process table before and after launching `sleep 300`
- why PID 1 exit ends the namespace

It also changes hostname to `demo-box`, but only inside the isolated UTS namespace.

### Stage 4 — back on the host

When `uts_pid_lab.sh` exits, `demo.sh` resumes on the host and confirms:

- the host hostname never changed
- the PID namespace disappeared
- processes that existed only in that namespace were cleaned up

That closes the loop.

---

## Best way to observe it during training

Use **two terminals**.

### Terminal 1

Run the guided lab:

```bash
./demo.sh
```

### Terminal 2

Use this to inspect from the host side while the lab pauses:

```bash
hostname
ps -ef | grep 'uts_pid_lab.sh'
sudo lsns -t uts,pid
```

When the inner script tells you to inspect a specific PID, also try:

```bash
ps -fp <host-pid>
sudo lsns -p <host-pid> -t uts,pid
```

This makes the “same process, different view” idea much clearer.

---

## Manual version of the lab

### 1. Check host hostname and shell PID

```bash
hostname
echo $$
readlink /proc/$$/ns/uts
readlink /proc/$$/ns/pid
```

### 2. Start a shell in new UTS and PID namespaces

```bash
sudo unshare --fork --pid --uts --mount-proc bash
```

You are now inside a new environment.

### 3. Inspect the environment from inside

```bash
echo $$
hostname
readlink /proc/$$/ns/uts
readlink /proc/$$/ns/pid
ps -ef
```

You should notice that the shell may now appear as PID 1.

### 4. Change hostname inside the namespace

```bash
hostname demo-box
hostname
```

From another host terminal, run:

```bash
hostname
```

The host hostname should remain unchanged.

### 5. Start a background process

```bash
sleep 300 &
echo $!
ps -ef
```

Now the namespaced shell sees that process with local PID numbering.

### 6. Compare with the host

From the original host terminal, inspect the corresponding processes:

```bash
ps -ef | grep sleep
sudo lsns -t uts,pid
```

You will see that the host still treats them as ordinary host processes.

### 7. Exit the namespace

```bash
exit
```

When PID 1 exits, the namespace ends. The background `sleep` started only inside that namespace should not continue living independently there.

---

## Expected learning outcome

> A container is not a tiny virtual machine. It is usually just a normal Linux process running with isolated namespaces and constrained resources.

This lab covers the **namespace isolation** part of that picture.

---

## Troubleshooting

### `unshare: command not found`

Install `util-linux`.

### `hostname: you must be root to change the host name`

That is expected if you try to run the manual version without `sudo` or without the proper namespace setup.

### `Refusing to run: not PID 1 in a PID namespace`

That message comes from `uts_pid_lab.sh` when it is not launched the intended way. It expects to be started via:

```bash
sudo unshare --fork --pid --uts --mount-proc ./uts_pid_lab.sh
```

### Script pauses and waits for a key

That is intentional. The pauses are part of the guided training flow.

### Color output looks strange

This lab uses ANSI escape sequences from `utils.sh`. If a terminal does not support them well, the lab still works, but output may look less polished.

---

## Short conclusion

This lab shows, in a direct and visible way, that Linux can give a process:

- its own hostname world
- its own process world

That is one of the foundations of modern containerized systems.
