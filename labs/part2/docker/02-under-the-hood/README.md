# Docker Lab 02 — Look Under the Hood

## Goal

Inspect a running container from the host and connect Docker back to the Linux primitives you already explored earlier.

By the end of this lab, you should be able to explain:

- that a container is still a regular Linux process
- that Docker places that process into isolated namespaces
- that Docker also applies resource control through cgroups
- that `docker exec` enters the running container environment

## Why this matters

In the first Docker lab, you used Docker as a tool:

- pull an image
- start a container
- access a service
- read logs
- stop and remove it

Now the question becomes:

> What did Docker actually create on the host?

This lab answers that by inspecting the running container from both sides:

- from the host
- from inside the container

## What you need

Check that Docker is available:

```bash
docker version
```

You will also use tools you have already seen in earlier labs:

```bash
which ps
which lsns
which readlink
```

## Step 1 — Start a container

Run nginx in the background:

```bash
docker run -d --name web1 -p 8080:80 nginx:alpine
```

Check that it is running:

```bash
docker ps
```

What to notice:

- the container is running in the background
- Docker shows the image, name, status, and published ports

## Step 2 — Inspect basic metadata

Show the full metadata:

```bash
docker inspect web1
```

That output is large, so pull out only a few useful values.

Get the container PID on the host:

```bash
PID=$(docker inspect -f '{{.State.Pid}}' web1)
echo "$PID"
```

Get the container IP address:

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web1
```

What to notice:

- Docker knows the host PID of the container process
- Docker knows the container network configuration
- this already suggests that a container is tied to a real host process

## Step 3 — Look at the container process on the host

Show the process directly from the host:

```bash
ps -fp "$PID"
```

What to notice:

- the container has a real PID on the host
- Docker did not create a tiny virtual machine
- the container is represented by normal Linux processes

## Step 4 — Compare namespaces

Show namespace links for your current shell:

```bash
readlink /proc/$$/ns/*
```

Now show namespace links for the container process:

```bash
readlink /proc/$PID/ns/*
```

You can also list them in a more readable form:

```bash
lsns -p "$PID"
```

What to notice:

- namespace identifiers differ from your shell
- the container process has its own isolated view of the system
- this connects directly to your earlier namespace labs

Useful namespaces to look for:

- `mnt` — mount namespace
- `pid` — PID namespace
- `net` — network namespace
- `uts` — hostname namespace
- `ipc` — IPC namespace

## Step 5 — Look at cgroup membership

Show which cgroup the process belongs to:

```bash
cat /proc/$PID/cgroup
```

You can also inspect the cgroup files directly:

```bash
ls /proc/$PID/root/sys/fs/cgroup
```

On many systems, Docker also places information in the container metadata that helps you find the cgroup path.

What to notice:

- the process belongs to a cgroup
- Docker uses cgroups together with namespaces
- this connects directly to your earlier cgroup labs

## Step 6 — Enter the running container

Run a shell inside the container:

```bash
docker exec -it web1 sh
```

Inside the container, run:

```bash
hostname
ps
ip addr
ls /
```

Then exit:

```bash
exit
```

What to notice:

- the hostname is isolated
- the process list is smaller and has a container-local view
- the network view is separate from the host
- the filesystem looks like a compact standalone system

## Step 7 — Compare inside and outside

From the host, show the process again:

```bash
ps -fp "$PID"
```

From inside the container, you already saw a much smaller process list.

This is the key idea:

- from the host, the process is part of the normal system
- from inside the container, the process sees an isolated environment

That illusion is created by Linux kernel features, not by a full virtual machine.

## Step 8 — Clean up

Stop the container:

```bash
docker stop web1
```

Remove it:

```bash
docker rm web1
```

## What you learned

In this lab:

- you started a container and inspected its metadata
- you found the container PID on the host
- you confirmed that the container is a normal Linux process
- you compared namespaces between your shell and the container process
- you looked at cgroup membership
- you entered the running container with `docker exec`

## Key idea

Docker does not invent a new execution model.

It uses Linux primitives you already know:

- namespaces for isolation
- cgroups for resource control
- regular Linux processes to run the workload

Docker adds packaging, networking, image distribution, and a convenient user interface around those building blocks.
