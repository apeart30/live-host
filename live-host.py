#!/usr/bin/env python3
import ipaddress
import platform
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed

def ping_host(ip: str, timeout_ms: int = 800) -> bool:
    system = platform.system().lower()
    if system == "windows":
        cmd = ["ping", "-n", "1", "-w", str(timeout_ms), ip]
    else:
        timeout_sec = max(1, int(round(timeout_ms / 1000)))
        cmd = ["ping", "-c", "1", "-W", str(timeout_sec), ip]

    result = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return result.returncode == 0

def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <ip/cidr>  e.g. {sys.argv[0]} 192.168.1.0/24")
        sys.exit(1)

    cidr = sys.argv[1]
    try:
        network = ipaddress.ip_network(cidr, strict=False)
    except ValueError as e:
        print(f"Invalid CIDR: {e}")
        sys.exit(1)

    hosts = [str(ip) for ip in network.hosts()]
    active = []

    with ThreadPoolExecutor(max_workers=128) as pool:
        futures = {pool.submit(ping_host, ip): ip for ip in hosts}
        for f in as_completed(futures):
            ip = futures[f]
            try:
                if f.result():
                    active.append(ip)
                    print(ip)
            except Exception:
                pass

    print(f"\nActive hosts: {len(active)} / {len(hosts)}")

if __name__ == "__main__":
    main()


