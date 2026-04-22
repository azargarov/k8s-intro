# What a Container Consists Of

## Historical note

Namespaces and cgroups were developed as Linux kernel features for isolation and resource control before modern container platforms became popular.  
Namespace work is closely associated with Eric W. Biederman.  
Cgroups originated at Google through work by Rohit Seth and Paul Menage, first under the name *process containers*.  
Containers later emerged as a practical combination of these kernel primitives.

## Core idea

A container is a packaged application process running on a Linux system with three main things around it:

1. **isolated views of the system**  
   This is mainly done with **namespaces**

2. **resource limits and accounting**  
   This is done with **cgroups**

3. **its own filesystem view**  
   This is done by giving the process a separate root filesystem

When container is started by a system what really happens is:

- Linux starts a regular process
- that process gets its own limited view of the machine
- it is attached to resource limits
- it sees a prepared filesystem as `/`

That combination creates the environment we call a **container**.

---

## The simplest mental model

A short explanation is:

> A container is a regular Linux process that has been isolated, limited, and given its own filesystem view.

---

## Namespaces — separate view

**Namespaces** give a process its own view of parts of the system.

Without namespaces, every process sees the same host reality:

- same hostname
- same process list
- same network stack
- same mount table

Namespaces give a process an isolated view of selected system resources.

Common namespace types:

- **UTS namespace**  
  Gives a separate hostname and domain name

- **PID namespace**  
  Gives a separate process tree  
  Inside the container, the application may even see itself as PID 1

- **Mount namespace**  
  Gives a separate mount table  
  The process can have its own `/proc`, `/tmp`, or bind mounts

- **Network namespace**  
  Gives its own network stack  
  That means its own interfaces, IP addresses, routes, and ports

- **IPC namespace**  
  Isolates shared memory and message queues

- **User namespace**  
  Allows remapping users and groups  
  This is important for security, especially root inside container vs root on host

Namespaces answer the question:

> “What parts of the system can this process see?”

---

## Cgroups — control and measure resources

**cgroups** stands for **control groups**.

They control how much of the machine a process or group of processes may use, and they also let the kernel measure that usage.

Typical things cgroups control:

- **CPU**
- **memory**
- **I/O**
- **number of processes**

Examples:

- limit a container to 512 MiB RAM
- give it only part of one CPU
- restrict how many processes it may create
- observe whether it hit an out-of-memory condition

Cgroups answer the question:

> “How much of the machine may this process use?”

Without cgroups, one badly behaving process could consume too much CPU or memory and disturb other workloads.

---

## Root filesystem — changing what `/` means

A container also needs its own filesystem view.

A normal host process sees the host’s root filesystem:

```text
/
├── bin
├── etc
├── home
├── lib
└── var
```

A container process usually sees a different root filesystem, prepared from an image or directory tree:

```text
/
├── app
├── bin
├── etc
├── lib
└── tmp
```

From the process point of view, this filesystem becomes `/`.

This is commonly done with:

- **chroot**
- **pivot_root**
- mount namespace plus mounts, bind mounts, or overlay filesystem

In practice, modern containers usually use:

- a **mount namespace**
- a prepared root filesystem
- then switch the process into that filesystem as its `/`

This matters because the process now sees:

- its own `/etc`
- its own libraries
- its own application files
- its own `/var`
- usually its own `/proc`

So the application runs in an environment that looks self-contained.

This part answers the question:

> “What files does this process see as its system?”

---

## Putting it together

A container usually consists of:

- **a regular Linux process**
- **namespaces** for isolation
- **cgroups** for limits and accounting
- **its own root filesystem**
- often a **container runtime** to assemble all of this automatically

The runtime, such as Docker, containerd, or CRI-O, does the setup work:

- prepare the filesystem
- create namespaces
- apply cgroups
- start the process
- connect networking
- manage logs and lifecycle

---

## Why this became useful

Containers became popular because they make software easier to package and run consistently.

They help with:

- **isolation**  
  one application has less effect on another

- **portability**  
  the same packaged application can run on many Linux systems

- **repeatability**  
  developers, test systems, and production can run the same artifact

- **efficiency**  
  containers share the host kernel, so they are lighter than full virtual machines

- **operations**  
  platforms like Kubernetes can schedule, restart, and scale them more easily

---

## Very short slide version

> **Container = process + namespaces + cgroups + root filesystem**

Under it:

- **namespaces** → what it can see  
- **cgroups** → what it can use  
- **root filesystem** → what files it sees as `/`

---
