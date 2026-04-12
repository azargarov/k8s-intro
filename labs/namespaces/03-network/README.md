# Lab: Network namespaces with a veth pair

This lab demonstrates one of the most important Linux building blocks behind container networking: the **network namespace**.

The goal is simple:

- create two isolated network namespaces
- connect them with a **veth pair**
- assign IP addresses
- bring the interfaces up
- prove that they can talk to each other

This is one of the cleanest ways to show that Linux can create multiple isolated network worlds on the same host.

---

## What this lab teaches

After this lab, you should understand that:

- a process can have its **own network stack**
- each network namespace has its own:
  - interfaces
  - IP addresses
  - routing table
  - ARP table
  - loopback device
- namespaces do not automatically see each other's interfaces
- a **veth pair** acts like a virtual cable between two network namespaces
- communication works only after interfaces are moved, addressed, and brought up
- this is one of the foundations used by containers and Kubernetes networking

---

## Why this matters

Containers often look like tiny separate machines.

From the networking side, that feeling comes largely from Linux namespaces.
A container can have:

- its own `eth0`
- its own `lo`
- its own IP address
- its own routes
- its own listening ports

But none of that requires a real virtual machine.
It can all be done by the Linux kernel using namespaces and virtual interfaces.

This lab helps you see that directly instead of treating container networking as black magic.

## Container vs VM

A virtual machine looks like a full computer because it runs its own kernel on virtualized hardware.

A container is different:
it does not emulate a whole machine and it does not boot its own kernel.
It is just a group of isolated processes that share the host kernel.

That is why a container can feel like a small machine from the inside, while still being much lighter than a VM.

---

## Small theory section

### What is a network namespace?

A **network namespace** gives a process its own isolated view of networking.

That includes:

- network interfaces
- IP addresses
- routes
- firewall rules
- port bindings
- loopback device

So if you create two network namespaces on the same host, they behave like two separate network environments.

### What is a veth pair?

A **veth pair** is two virtual Ethernet interfaces connected back-to-back.

You can think of it as a short virtual patch cable:

- traffic sent into one side comes out of the other side
- if one side is moved into one namespace and the other side into another namespace, those namespaces can talk to each other

That is exactly what this lab does.

### Why loopback matters

Each network namespace has its own loopback interface: `lo`.

Just creating the namespace is not enough. You often must explicitly bring loopback up:

```bash
ip -n red link set lo up
```

---

## Files in this lab

### `demo.sh`

This is the guided lab script.

It:

- creates two namespaces: `red` and `blue`
- creates a veth pair
- moves one end into each namespace
- assigns IP addresses
- brings interfaces up
- tests connectivity with `ping`
- suggests optional follow-up commands such as `python3 -m http.server` and `curl`
- cleans everything up on exit

## Prerequisites

You need:

- a Linux machine or VM
- `sudo` access
- `ip` from `iproute2`
- `ping`
- ideally `python3` and `curl` for the optional HTTP demo
- two terminals if possible

Check the important tools:

```bash
which ip
which ping
which python3
which curl
```

---

## Recommended way to run the lab

Run it from the lab directory:

```bash
chmod +x demo.sh
./demo.sh
```

This works best if you have:

- **Terminal 1** for running the guided lab
- **Terminal 2** for inspection commands while the script pauses

That makes the exercise much more interactive.

---

## What the guided lab does

### Stage 1 — explanation

The script explains that it will create two separate network namespaces:

- `red`
- `blue`

It also explains the idea of a veth pair as a virtual cable.

### Stage 2 — create namespaces

The script runs:

```bash
sudo ip netns add red
sudo ip netns add blue
```

Now the host has two named network namespaces.

### Stage 3 — create the veth pair

The script creates:

```bash
sudo ip link add veth-red type veth peer name veth-blue
```

At this moment both ends still exist on the host.

### Stage 4 — move interfaces into the namespaces

One end goes into `red`, the other into `blue`:

```bash
sudo ip link set veth-red netns red
sudo ip link set veth-blue netns blue
```

Now each namespace owns one interface.

### Stage 5 — assign IP addresses

The script assigns:

- `10.10.1.1/24` to `red`
- `10.10.1.2/24` to `blue`

### Stage 6 — bring devices up

The script brings up:

- `lo` inside each namespace
- the veth interface inside each namespace

Without this step, communication will not work.

### Stage 7 — test connectivity

The script pings:

- `red -> blue`
- `blue -> red`

If everything is correct, both pings succeed.

### Stage 8 — optional service demo

The script suggests a very useful extension:

- run an HTTP server inside `red`
- connect to it from `blue`

That makes the lab feel more like a real application path, not just a ping test.

---

## Best way to observe it during training

Use **two terminals**.

### Terminal 1

Run the guided lab:

```bash
./demo.sh
```

### Terminal 2

While the script pauses, inspect from the host:

```bash
sudo ip netns list
sudo ip -n red addr
sudo ip -n blue addr
sudo ip -n red link
sudo ip -n blue link
```

Useful extra commands:

```bash
sudo ip netns exec red ip addr
sudo ip netns exec blue ip addr
sudo ip netns exec red ip route
sudo ip netns exec blue ip route
```

If you want a more shell-like experience:

```bash
sudo ip netns exec red bash
sudo ip netns exec blue bash
```

---

## Manual version of the lab

### 1. Create two namespaces

```bash
sudo ip netns add red
sudo ip netns add blue
```

Check that they exist:

```bash
sudo ip netns list
```

### 2. Create a veth pair

```bash
sudo ip link add veth-red type veth peer name veth-blue
```

Check from the host:

```bash
ip link show veth-red
ip link show veth-blue
```

### 3. Move one interface into each namespace

```bash
sudo ip link set veth-red netns red
sudo ip link set veth-blue netns blue
```

At this point the host no longer owns those interfaces directly.

### 4. Assign IP addresses

```bash
sudo ip -n red addr add 10.10.1.1/24 dev veth-red
sudo ip -n blue addr add 10.10.1.2/24 dev veth-blue
```

### 5. Bring loopback and interfaces up

```bash
sudo ip -n red link set lo up
sudo ip -n blue link set lo up
sudo ip -n red link set veth-red up
sudo ip -n blue link set veth-blue up
```

### 6. Verify the result

```bash
sudo ip -n red addr
sudo ip -n blue addr
```

### 7. Test connectivity

```bash
sudo ip netns exec red ping -c 2 10.10.1.2
sudo ip netns exec blue ping -c 2 10.10.1.1
```

If both pings work, the setup is correct.

### 8. Optional service test

In one terminal:

```bash
sudo ip netns exec red python3 -m http.server 8080
```

In another terminal:

```bash
sudo ip netns exec blue curl http://10.10.1.1:8080
```

That proves not only ICMP but actual application traffic can flow.

### 9. Cleanup

When done, remove everything:

```bash
sudo ip netns del red
sudo ip netns del blue
sudo ip link del veth-red 2>/dev/null || true
sudo ip link del veth-blue 2>/dev/null || true
```

If the interface was already deleted together with the namespace move, that is fine.

---

## What participants should observe

There are a few key learning points.

### 1. The host does not “see inside” automatically

The host created the namespaces, but their interfaces are isolated. Once `veth-red` moves into `red`, the host cannot treat it like a normal host interface anymore.

### 2. Each namespace has its own loopback

### 3. Connectivity does not happen by magic

Networking works only after:

- interface creation
- interface move
- IP assignment
- link up
- loopback up

That sequence is useful for troubleshooting later.

### 4. This is already “container-style networking”

You are not using Docker here. You are using raw Linux features directly.

---

## Common problems

### `ip: command not found`

Install `iproute2`.

### `Operation not permitted`

You likely need `sudo`.

### Ping fails

Check these first:

```bash
sudo ip -n red addr
sudo ip -n blue addr
sudo ip -n red link
sudo ip -n blue link
```

Most likely causes:

- IP address not assigned
- interface still down
- loopback not up
- typo in namespace or interface name

### `curl` fails in the optional demo

Check that the HTTP server is actually running in `red`:

```bash
sudo ip netns exec red ss -ltnp
```

Also verify that `python3` and `curl` exist.

---

## How this connects to containers and Kubernetes

In container platforms, something similar happens behind the scenes:

- a process gets its own network namespace
- an interface is attached to it
- that interface is connected to something outside
- traffic is routed between isolated workloads

Kubernetes adds more layers on top:

- CNI plugins
- bridges
- overlays
- service IPs
- kube-proxy or eBPF-based routing

But underneath all that, Linux network namespaces are still one of the core pieces.

---


