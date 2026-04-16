# Linux Namespaces Labs

These labs demonstrate the basic Linux namespace types that make containers possible.

## Goal

Understand that a container is not magic.  
A container is primarily:

- a regular Linux process
- running with isolated namespaces
- often constrained by cgroups
- packaged with its own filesystem

## Labs

0. `00-prerequisites`  
   Check that the required tools are installed and inspect the current environment.

1. `01-uts-pid`  
   Show an isolated hostname and PID tree.

2. `02-mount`  
   Show an isolated mount table.

3. `03-network`  
   Show an isolated network stack using two namespaces and a veth pair.

4. `04-build-a-container-by-hand`  
   Combine namespaces into a primitive handmade container.

5. `05-nsenter`  
   Enter the namespaces of another process.

## Recommended order

Run the labs in this order:

- `00-prerequisites`
- `01-uts-pid`
- `02-mount`
- `03-network`
- `04-build-a-container-by-hand`
- `05-nsenter` *(optional)*

## Required tools

- bash
- sudo
- util-linux (`unshare`, `nsenter`)
- iproute2 (`ip`, `ip netns`)
- procps (`ps`)
- mount / findmnt
- python3 (optional, for a simple HTTP demo)

## Important

These labs modify namespaces and sometimes create temporary network interfaces.  
If a lab fails midway, use the provided cleanup steps to remove anything left behind.