import os
import sys
import time

chunk_mb = 10
target_mb = 1024
chunks = []
allocated = 0

print(f"[python] pid={os.getpid()}\n", flush=True)

try:
    while allocated < target_mb:
        chunks.append(bytearray(chunk_mb * 1024 * 1024))
        allocated += chunk_mb
        print(f"\r[python] allocated {allocated} MiB", end="" , flush=True)
        time.sleep(0.2)
    print("you can now continue                    ", flush=True)

except MemoryError:
    print("\r[python] MemoryError raised              ", flush=True)
    time.sleep(2)
    sys.exit(1)