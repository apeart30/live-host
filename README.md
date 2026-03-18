# live-host

A fast, multithreaded subnet scanner that discovers live hosts using ICMP ping.
Invoked via the `live-host` shell alias, it sweeps an entire CIDR range concurrently and prints every responding IP in real time.

---

## Usage

```bash
live-host <ip/cidr>
```

**Examples:**

```bash
live-host 192.168.1.0/24
live-host 10.0.0.0/16
live-host 172.16.0.0/20
```

**Output:**

```
192.168.1.1
192.168.1.5
192.168.1.23
...

Active hosts: 3 / 254
```

---

## How It Works

1. Parses the supplied CIDR block using Python's `ipaddress` module.
2. Spawns up to **128 concurrent threads** via `ThreadPoolExecutor`.
3. Each thread runs a native `ping` command (cross-platform: Linux/macOS/Windows) against one IP with an 800 ms timeout.
4. Responding IPs are printed immediately as they reply.
5. A final summary line reports the ratio of live hosts to total hosts scanned.

---

## Tool File

| File | Description |
|------|-------------|
| `live-host.py` | Main scanner script |

---

## GitHub Integration

The tool lives in this repository as `live-host.py` and is wired into the shell via `.bashrc`:

```bash
alias live-host='python3 ~/tools/live-host.py'
```

Version control is handled through **Git + GitHub CLI (`gh`)**. The workflow used to publish this project:

```bash
# 1. Initialise the local repository
git init
git add .
git commit -m "Initial commit: live-host subnet scanner"

# 2. Create the remote repo and push (using gh CLI)
gh repo create live-host --public --source=. --remote=origin --push
```

The `gh` CLI handles authentication via a stored OAuth token, so no manual remote URL configuration is needed.

---

## Requirements

- Python 3.6+
- `ping` available in `$PATH` (standard on all major OS)
- No third-party packages — pure standard library

---

## Attribution & Inspiration — hping3

`live-host` draws conceptual inspiration from **hping3**, the legendary packet crafting and host-discovery tool. Full credit and respect go to its original authors:

> **Salvatore Sanfilippo** (`antirez`) — *Original creator of hping and hping3*
> Website: [http://www.hping.org](http://www.hping.org)
> GitHub: [https://github.com/antirez](https://github.com/antirez)
>
> *"hping is a command-line oriented TCP/IP packet assembler/analyser. The interface is inspired to the ping(8) unix command, but hping isn't only able to send ICMP echo requests. It supports TCP, UDP, ICMP and RAW-IP protocols..."*
> — Salvatore Sanfilippo, hping3 README

> **Gianluca Varenni** — *hping3 co-developer and contributor*
>
> Additional contributors are listed in the [hping3 source tree](https://github.com/antirez/hping).

While `live-host` uses standard ICMP ping rather than hping3 directly, the philosophy of fast, scriptable host discovery originates from Sanfilippo's work. hping3 remains the gold standard for low-level packet probing and is widely used in penetration testing, network diagnostics, and firewall rule validation.

---

## License

See [license](../license) for terms.

---

*Tool authored by apeart30 — built for fast internal network reconnaissance.*
