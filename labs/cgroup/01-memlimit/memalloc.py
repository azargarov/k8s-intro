#!/bin/env python3 

import time

ALLOC_MB=100
print("python: pid starting")
time.sleep(2)

print("python: allocating " + str(ALLOC_MB) + " MiB...")
x = bytearray(ALLOC_MB * 1024 * 1024)

for i in range(0, len(x), 4096):
    x[i] = 1

print("python: allocation finished")
time.sleep(300)