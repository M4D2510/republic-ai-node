# Republic Compute Provider Setup — Complete Guide (v2)

A practical, hands-on guide for setting up a GPU machine as a Republic AI compute provider using `raicompute 0.1.0+` and the official Vast.ai host integration.

> **What you get:** Your registered GPU receives Republic Network inference jobs and earns RAI rewards (plus USDC under Season 2 rules). If you also list it on Vast.ai's marketplace, you earn rental income on top.

This guide is based on hands-on testing in late April 2026. It covers what actually works, what does not, and the troubleshooting steps that took us hours to figure out.

---

## Table of Contents

1. [TL;DR](#1-tldr)
2. [Hardware and Network Requirements](#2-hardware-and-network-requirements)
3. [Critical Warning: Vast.ai Rented Containers Will Not Work](#3-critical-warning-vastai-rented-containers-will-not-work)
4. [Pre-Flight Checklist](#4-pre-flight-checklist)
5. [Step 1 — Install raicompute](#5-step-1--install-raicompute)
6. [Step 2 — Generate Login Credentials From Your Mnemonic](#6-step-2--generate-login-credentials-from-your-mnemonic)
7. [Step 3 — Login](#7-step-3--login)
8. [Step 4 — Register Your Machine](#8-step-4--register-your-machine)
9. [Step 5 — Verify Earnings](#9-step-5--verify-earnings)
10. [Updating Rental Prices](#10-updating-rental-prices)
11. [Performance Tuning for Maximum Earnings](#11-performance-tuning-for-maximum-earnings)
12. [Earnings Tracking and Optimization](#12-earnings-tracking-and-optimization)
13. [Security Best Practices](#13-security-best-practices)
14. [Troubleshooting](#14-troubleshooting)
15. [Diagnostic Commands](#15-diagnostic-commands)
16. [Why Vast.ai Rented Containers Fail (Technical Detail)](#16-why-vastai-rented-containers-fail-technical-detail)
17. [Hardware Recommendations](#17-hardware-recommendations)
18. [Alternative Hosting Options](#18-alternative-hosting-options)
19. [Frequently Asked Questions](#19-frequently-asked-questions)

---

## 1. TL;DR

For experienced operators who just want the steps:

```bash
# 1. Install
pip install raicompute

# 2. Generate credentials from your real mnemonic (see Section 6 for the script)
python3 raicompute_sig.py

# 3. Login
raicompute login --auth-wallet republic1... --auth-wallet-hex 0x... --auth-pubkey ... --auth-sig ...

# 4. Register machine (NOT inside a Vast.ai rented container — see Section 3)
raicompute install --provider-slug vast

# 5. Enable services and verify
sudo systemctl enable --now vastai.service vast_metrics.service vastai_bouncer.service
raicompute host-metrics
```

If `host-metrics` returns `401 Unauthorized`, you are not running on a real Vast.ai host. Read Section 3 and Section 16.

---

## 2. Hardware and Network Requirements

### Minimum

- NVIDIA GPU with 16 GB+ VRAM (RTX 3090, 4090, A4000, A5000, A6000, L4, L40, etc.)
- 8 vCPU, 32 GB RAM
- 200 GB NVMe SSD (more if you want to host larger models or rentals with disk allocation)
- Ubuntu 22.04 LTS (or another recent Linux with systemd, NVIDIA driver, Docker)
- Outbound internet on ports `7071` (Vast.ai controller), `443` (HTTPS), `22` (SSH)
- 24/7 uptime — every minute offline is lost earnings

### Recommended

- Two or more GPUs (more concurrent jobs = more earnings)
- 64 GB+ RAM if you plan to run large LLMs (70B+)
- 1 TB NVMe (separate `/var/lib/vastai_kaalia` partition)
- 1 Gbps symmetric connection (some renters require this)
- UPS (power outage during a rental kills your reliability score)
- Wired ethernet, not Wi-Fi

### Network Notes

- **No public IP needed.** Vast.ai daemon initiates outbound connections to controller at `54.80.85.221:7071` (and other IPs). NAT and firewalls are fine as long as outbound is permitted.
- **No port forwarding needed for raicompute.** Inbound connections happen over Vast.ai's tunneling.
- If you also want to be SSHable from outside (recommended for debugging), open `22/tcp` inbound or use Tailscale/ZeroTier.
- Watch out for ISP throttling. Vast.ai bandwidth tests check ~100 Mbps minimum; below that, your earnings drop.

---

## 3. Critical Warning: Vast.ai Rented Containers Will Not Work

**Do not try to install raicompute inside a Vast.ai container that you rented.** It will look like it is working, then fail at the last step.

What happens in detail:

| Step | Outcome inside a rented container |
|------|-----------------------------------|
| `pip install raicompute` | ✅ Succeeds |
| `raicompute login` | ✅ Succeeds — proxy server accepts your wallet signature |
| `raicompute install --provider-slug vast` | ✅ Vast.ai daemon installer runs without errors |
| Daemon registers a `machine_id` | ✅ Connects to Vast.ai controller at `54.80.85.221:7071` |
| `raicompute host-metrics` | ❌ **Returns `401 Unauthorized` from `https://console.vast.ai/api/v0/machines/`** |

The reason: a rented container only has `CONTAINER_API_KEY` (scope: managing the rented container). The host endpoint requires a **host API key**, which you only have if your Vast.ai account is configured as a host provider.

**See Section 16** for the full technical breakdown — including how to verify this yourself in 30 seconds.

---

## 4. Pre-Flight Checklist

Before starting, gather:

- [ ] A machine matching the requirements in Section 2
- [ ] **NVIDIA driver** version 525+ installed (`nvidia-smi` works)
- [ ] **Docker** installed (or willing to let `raicompute install` install it)
- [ ] **Python 3.7+** (`python3 --version` returns `3.7` or higher)
- [ ] Your Republic AI **wallet mnemonic** (24 words) — the one with the `republic` bech32 prefix
- [ ] Your wallet bech32 address (looks like `republic1abc...xyz`)
- [ ] Your wallet hex address (looks like `0x...`)
- [ ] An existing **Vast.ai HOST account** (not a renter/customer account — see Section 3 for the difference)
- [ ] At least 2 hours of uninterrupted time for the install (Docker download + daemon download + benchmarks)

If you only have your testnet `rai...` address, derive the `republic...` address from the same mnemonic. Both come from the same private key but use different bech32 prefixes (and different derivation paths: `m/44'/60'/0'/0/0` for `republic`, vs the Cosmos default for `rai`).

---

## 5. Step 1 — Install raicompute

```bash
pip install raicompute
```

If you get a permission error, install in a virtualenv:

```bash
python3 -m venv ~/raicompute-venv
source ~/raicompute-venv/bin/activate
pip install raicompute
```

Verify:

```bash
raicompute --help
```

Expected output:

```
usage: raicompute [-h]
                  {login,auth-verify,install,host-metrics,host-update,generate-test-credentials}
                  ...
```

---

## 6. Step 2 — Generate Login Credentials From Your Mnemonic

`raicompute login` requires four values:

| Argument | Description |
|----------|-----------------------------------|
| `--auth-wallet` | Your bech32 address (`republic1...`) |
| `--auth-wallet-hex` | Your hex address (`0x...`) |
| `--auth-pubkey` | Base64-encoded uncompressed secp256k1 public key |
| `--auth-sig` | Base64-encoded signature of the message `republic-verify` |

The CLI does **not** generate these from a mnemonic. You can either:

- **(a)** Use `raicompute generate-test-credentials` — but this creates a **new throwaway wallet**, so any earnings would go to the throwaway, not your real wallet.
- **(b)** Generate them from your real mnemonic with the script below.

Use option **(b)** for real earnings.

### Step 2a — Install Python dependencies

```bash
pip install ecdsa mnemonic eth-hash bip32 bech32
```

### Step 2b — Save and run the credentials script

Create `raicompute_sig.py`:

```python
"""
Generate raicompute login credentials from a mnemonic.
Uses ethsecp256k1 (Ethereum-compatible) — same algorithm raicompute uses.
"""
import base64
from mnemonic import Mnemonic
from bip32 import BIP32
import ecdsa
from eth_hash.auto import keccak
import bech32

MESSAGE = "republic-verify"
HRP = "republic"
DERIVATION_PATH = "m/44'/60'/0'/0/0"   # Ethereum BIP44 path used by Cosmos EVM chains

mnemonic_str = input("Paste mnemonic: ").strip()

seed = Mnemonic("english").to_seed(mnemonic_str)
priv_bytes = BIP32.from_seed(seed).get_privkey_from_path(DERIVATION_PATH)

sk = ecdsa.SigningKey.from_string(priv_bytes, curve=ecdsa.SECP256k1)
vk = sk.get_verifying_key()

# Public key: 64-byte uncompressed (X || Y), no 0x04 prefix, base64-encoded
pubkey_uncompressed = vk.to_string()
pubkey_b64 = base64.b64encode(pubkey_uncompressed).decode()

# Address: keccak256(uncompressed_pubkey)[-20:]
addr_bytes = keccak(pubkey_uncompressed)[-20:]
addr_hex = "0x" + addr_bytes.hex()
addr_bech32 = bech32.bech32_encode(HRP, bech32.convertbits(addr_bytes, 8, 5))

# Sign keccak256("republic-verify")
msg_hash = keccak(MESSAGE.encode())
sig = sk.sign_digest(msg_hash, sigencode=ecdsa.util.sigencode_string)
sig_b64 = base64.b64encode(sig).decode()

print()
print("=== Credentials ===")
print(f"Wallet (Bech32): {addr_bech32}")
print(f"Wallet (Hex):    {addr_hex}")
print(f"Public Key (b64): {pubkey_b64}")
print(f"Signature (b64):  {sig_b64}")
print()
print("Login command:")
print(
    f"raicompute login --auth-wallet {addr_bech32} "
    f"--auth-wallet-hex {addr_hex} "
    f"--auth-pubkey {pubkey_b64} "
    f"--auth-sig {sig_b64}"
)
```

Run it:

```bash
python3 raicompute_sig.py
```

Paste your mnemonic when prompted. The script prints credentials and a ready-to-run `raicompute login` command.

### Sanity Check

The `Wallet (Bech32)` it prints **must** match your known `republic1...` address. If it does not match:

- Double-check the mnemonic for typos or extra whitespace
- Confirm the path is `m/44'/60'/0'/0/0` (Ethereum-compatible), not Cosmos default `m/44'/118'/0'/0/0`
- Confirm you are using the right wallet — Republic AI Season 2 uses the `republic` bech32 prefix, not the testnet `rai` prefix

### Security

- Run the script in a private session — no screen sharing, no streaming
- Do not paste the mnemonic into chat, screenshots, or commit history
- After login the mnemonic is no longer needed; you can clear bash history with `history -c`
- Consider running on a clean machine, not your daily driver

---

## 7. Step 3 — Login

Run the command printed by the script:

```bash
raicompute login \
  --auth-wallet republic1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx \
  --auth-wallet-hex 0xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx \
  --auth-pubkey BASE64PUBKEY... \
  --auth-sig BASE64SIGNATURE...
```

Expected output:

```
Session saved successfully for wallet republic1... at /root/.republic_session.json
```

Verify the proxy server accepts your credentials:

```bash
raicompute auth-verify
```

Expected: `Verification successful.`

The session is saved at `~/.republic_session.json`. All subsequent commands use it automatically.

---

## 8. Step 4 — Register Your Machine

> **Stop here if you are inside a Vast.ai rented container.** This step appears to succeed and breaks in Step 5. See Section 3.

```bash
raicompute install --provider-slug vast
```

This will:

1. Create a `vastai_kaalia` system user
2. Install Docker (if not already present)
3. Install the Vast.ai host daemon to `/var/lib/vastai_kaalia/`
4. Configure systemd services: `vastai.service`, `vast_metrics.service`, `vastai_bouncer.service`
5. Run hardware probe (`lshw`, `dmidecode`, `nvidia-smi`)
6. Register a `machine_id` with Vast.ai's controller

The install can take 5–15 minutes. Be patient through Docker download.

### Expected warnings (normal)

```
No unpartitioned zones to create a partition. Will attempt a loopback partition; this will have significantly worse performance.
```

For testing this is acceptable. For real earnings, prepare a dedicated partition before installing — see Section 11.

### After installation

Enable and start the services if not already running:

```bash
sudo systemctl enable --now vastai.service vast_metrics.service vastai_bouncer.service
sudo systemctl status vastai.service --no-pager
```

You should see `Active: active (running)`.

Wait 2–3 minutes for the daemon to complete its first hardware probe and benchmarks. Then proceed to Step 5.

---

## 9. Step 5 — Verify Earnings

```bash
raicompute host-metrics
```

### Expected on success

```json
{
  "machines": [
    {
      "id": 32061875,
      "hostname": "...",
      "gpu_name": "RTX 3090",
      "earnings_24h": "...",
      "reliability": "...",
      "status": "online"
    }
  ]
}
```

### If you see this error

```
Error (500): {"detail":"Provider error: 401 Client Error: Unauthorized for url: https://console.vast.ai/api/v0/machines/"}
```

You are not registered as a host on Vast.ai. Most common reasons:

1. **You are inside a Vast.ai rented container** — see Section 3 and Section 16
2. **Your machine has not finished registering** — wait 5 more minutes, check `/var/lib/vastai_kaalia/kaalia.log` for `Identify` and benchmark messages
3. **Your Vast.ai host API key is missing or scoped incorrectly** — generate a new key under https://cloud.vast.ai/account/

See Section 14 for full troubleshooting.

---

## 10. Updating Rental Prices

```bash
raicompute host-update --machine-id <id> --price-gpu 0.50 --price-disk 0.10
```

- `--price-gpu` — USD per GPU per hour
- `--price-disk` — USD per GB of disk per hour

### How to choose prices

1. Go to https://cloud.vast.ai/create/
2. Filter by your GPU model
3. Sort by `$/hr` and look at the top 20% range — match or undercut by 5–10%
4. Too expensive: low utilization, low earnings
5. Too cheap: race to the bottom, no profit margin

Watch the marketplace for a few days. The Republic provider-proxy also pays for inference jobs, but the Vast.ai marketplace rate sets the floor for what your GPU is worth.

---

## 11. Performance Tuning for Maximum Earnings

### Disk

The default loopback partition is **slow**. For real earnings:

```bash
# Identify a free partition (e.g. /dev/nvme1n1p1)
lsblk
# Format and mount it for vastai
mkfs.ext4 /dev/nvme1n1p1
mkdir -p /mnt/vastai_data
mount /dev/nvme1n1p1 /mnt/vastai_data
chown -R vastai_kaalia:docker /mnt/vastai_data
```

Then symlink:

```bash
systemctl stop vastai.service
mv /var/lib/vastai_kaalia/data /var/lib/vastai_kaalia/data.bak
ln -s /mnt/vastai_data /var/lib/vastai_kaalia/data
systemctl start vastai.service
```

Add the mount to `/etc/fstab` so it persists across reboots.

### GPU power limit

If you are not on a power-limited setup, **uncap the GPU**:

```bash
# Show current limit
nvidia-smi -q -d POWER | grep "Power Limit"
# Set to max (verify with nvidia-smi --help-query-gpu)
nvidia-smi -pm 1
nvidia-smi -pl 350    # for RTX 3090, 350W is the default max
```

Higher power → faster inference → better reliability score → more rentals.

### CPU governor

Set to `performance` to reduce inference latency:

```bash
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

Make persistent via `cpupower-gui` or a systemd service.

### Network buffer tuning

For 1 Gbps+ links:

```bash
sudo sysctl -w net.core.rmem_max=134217728
sudo sysctl -w net.core.wmem_max=134217728
sudo sysctl -w net.ipv4.tcp_rmem="4096 87380 67108864"
sudo sysctl -w net.ipv4.tcp_wmem="4096 65536 67108864"
```

Persist by adding to `/etc/sysctl.conf`.

### Reliability score

Vast.ai weights this heavily. Improve by:

- 24/7 uptime — set up auto-restart on power failure (BIOS option "Restore on AC Power Loss")
- Pass bandwidth test consistently (re-run with `vastai test-machine <id>`)
- Pass GPU benchmark (DLPerf score visible in dashboard)
- No frequent disconnects — check logs for `socket write error` or `Broken pipe`
- Avoid running other heavy workloads on the same machine

A 0.95+ reliability score is competitive. Below 0.85, you get fewer rentals.

---

## 12. Earnings Tracking and Optimization

### Dashboard

- **Vast.ai earnings:** https://cloud.vast.ai/host/machines/
- **Republic earnings:** `raicompute host-metrics` and (if available) https://points.republicai.io

### Metrics to watch daily

| Metric | What it means | Target |
|--------|---------------|--------|
| Utilization % | Hours rented / hours online | 60%+ |
| $/GPU-hour earned | Average rental rate | Within 10% of marketplace median |
| Reliability score | Vast.ai weighted uptime | 0.95+ |
| Republic jobs/day | Inference jobs from raicompute | Tracked in `host-metrics` |
| GPU temp | Cooling adequate? | <80 °C under load |

### A/B test pricing weekly

Change `--price-gpu` by ±5% each week and track utilization. Find the price point that maximizes (price × utilization).

### Multiple GPUs per machine

If you have 2+ GPUs in one box, Vast.ai can rent them individually. Make sure all GPUs show in `nvidia-smi` and the daemon picks them up. Each GPU gets its own pricing.

### Time-of-day pricing

Demand varies. Some hosts run a script that adjusts prices based on hour of day:

```bash
# Pseudo-code
if [ $(date +%H) -ge 18 ] && [ $(date +%H) -le 23 ]; then
    raicompute host-update --price-gpu 0.55  # Peak
else
    raicompute host-update --price-gpu 0.40  # Off-peak
fi
```

Schedule via cron.

---

## 13. Security Best Practices

### Wallet hygiene

- Use a dedicated Republic wallet for hosting (not your personal hot wallet)
- Move earnings to cold storage weekly
- Never SSH from the host machine to other systems with shared credentials

### SSH

- Disable password auth, use ed25519 keys only
- Use `fail2ban` to ban brute force attempts
- Consider Tailscale or WireGuard instead of public SSH

### System hardening

- Keep Ubuntu patched: `sudo apt update && sudo apt upgrade` weekly
- Run `lynis audit system` and address high findings
- Enable `unattended-upgrades` for security patches

### Container isolation

Vast.ai daemon spawns Docker containers for renters. They are isolated by default but:

- Do not store sensitive files anywhere readable by Docker
- Do not run other services on the same machine if possible
- Monitor with `docker ps -a` and `docker logs <container>` if a renter does something suspicious

### Backup the daemon credentials

```bash
sudo tar czf /root/vastai_backup_$(date +%F).tar.gz \
  /var/lib/vastai_kaalia/machine_id \
  /var/lib/vastai_kaalia/data \
  ~/.republic_session.json
```

Store offline. Lose this and you may have to re-register the machine (and lose reliability score).

---

## 14. Troubleshooting

### `pip install raicompute` fails with permission error

Use a virtualenv (see Section 5).

### Login command says signature is invalid

Common causes:

- **Wrong derivation path.** Republic uses `m/44'/60'/0'/0/0` (Ethereum), not Cosmos default `m/44'/118'/0'/0/0`.
- **Wrong message.** It must be exactly `republic-verify` — lowercase, hyphen, no whitespace.
- **Wrong hash.** Use **keccak256**, not SHA-256.
- **Compressed pubkey.** Use 64-byte uncompressed (X || Y), no `0x04` prefix.

The script in Section 6 handles all four correctly.

### Bech32 address from script does not match your real address

You probably used a different derivation path historically. For Republic AI specifically, the correct path is `m/44'/60'/0'/0/0`.

If your existing wallet was derived differently, you have two choices:

1. Use the wallet from path `m/44'/60'/0'/0/0` derived from the same mnemonic (this is your "Republic" wallet)
2. Or migrate funds from your existing wallet to the new one — but this requires that the existing wallet works on the same chain

### `raicompute install` hangs at "check apt update"

Network issue or apt mirror is slow. Wait up to 15 minutes. If it never progresses:

- `Ctrl+C` to abort
- Run `apt-get update` manually and look for errors
- Re-run `raicompute install`

### `raicompute install` hangs at "Update Vast.ai daemon"

The Vast.ai daemon is downloading from `s3.amazonaws.com/public.vast.ai/kaalia/daemons`. Check connectivity:

```bash
curl -I https://s3.amazonaws.com/public.vast.ai/kaalia/daemons/
```

If it fails, your network blocks AWS S3 (rare). Use a VPN or different network.

### `host-metrics` returns 401 on a real host machine

1. Confirm the machine appears at https://cloud.vast.ai/host/machines
2. If missing, check daemon connection in `/var/lib/vastai_kaalia/kaalia.log` for `Identify` messages
3. If present but `host-metrics` still 401, your Vast.ai host API key may be missing. Generate one at https://cloud.vast.ai/account/ → API Keys → Create
4. Some setups need the API key in `~/.vastai/api_key` or `VAST_API_KEY` environment variable

### `host-metrics` returns 401 inside a rented container

Expected. See Section 3 and Section 16. There is no fix — switch to a host machine.

### Daemon registers but no rentals come

- Check reliability score in dashboard. Below 0.85 means few rentals.
- Re-run benchmarks: `vastai test-machine <id>`
- Verify pricing is competitive on https://cloud.vast.ai/create/
- Check `kaalia.log` for `cont_started` messages — these are inbound rentals

### Daemon disconnects frequently (`socket write error: Broken pipe`)

Your network is unstable. Common causes:

- Wi-Fi instead of ethernet → switch to wired
- ISP throttling → contact ISP
- Router NAT table overflow → reboot router
- Excessive concurrent connections → reduce `MaxSessions` in sshd_config

### Renter complains "GPU not visible in container"

NVIDIA Container Toolkit is missing or broken:

```bash
sudo apt install -y nvidia-container-toolkit
sudo systemctl restart docker
```

Test with:

```bash
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi
```

You should see your GPU(s) listed.

### Disk fills up unexpectedly

Vast.ai container images can be large. Clean periodically:

```bash
docker system prune -a --volumes
```

⚠️ This deletes stopped containers and unused images. Do not run while rentals are active.

### Earnings report does not match dashboard

`raicompute host-metrics` queries Vast.ai API which has a 1–5 minute delay. Refresh the dashboard or wait. If the discrepancy persists 24h+, contact Vast.ai support.

---

## 15. Diagnostic Commands

Useful one-liners for debugging.

### Daemon status

```bash
sudo systemctl status vastai.service vast_metrics.service vastai_bouncer.service --no-pager
```

### Daemon logs

```bash
sudo tail -f /var/lib/vastai_kaalia/kaalia.log
sudo journalctl -u vastai.service -f
```

### Machine info reported by daemon

```bash
sudo grep -E "Identify|machine_uuid|cont_started|reliability" /var/lib/vastai_kaalia/kaalia.log | tail -20
```

### Active Vast.ai connection

```bash
sudo ss -tnp | grep -E "7071"
```

You should see an established connection to `54.80.85.221:7071` (or another Vast.ai controller IP).

### GPU usage

```bash
nvidia-smi
nvidia-smi dmon -s pucvmet  # Per-GPU continuous monitoring
```

### Docker containers

```bash
sudo docker ps -a
sudo docker stats
```

### Disk usage

```bash
df -h /var/lib/vastai_kaalia
sudo du -sh /var/lib/vastai_kaalia/*
```

### Network throughput

```bash
sudo iftop -i eth0
# Or
sudo nethogs eth0
```

### Republic session file

```bash
cat ~/.republic_session.json | python3 -m json.tool
```

### All-in-one health check

```bash
echo "=== Services ===" && systemctl is-active vastai.service vast_metrics.service vastai_bouncer.service
echo "=== Daemon connection ===" && ss -tn | grep 7071
echo "=== GPU ===" && nvidia-smi --query-gpu=name,utilization.gpu,memory.used --format=csv,noheader
echo "=== Disk ===" && df -h /var/lib/vastai_kaalia | tail -1
echo "=== Active rentals ===" && docker ps --format "table {{.Names}}\t{{.Status}}"
echo "=== Earnings ===" && raicompute host-metrics 2>&1 | head -20
```

---

## 16. Why Vast.ai Rented Containers Fail (Technical Detail)

Vast.ai has two types of accounts:

| Account Type | Sees in Console | API Access | Can run raicompute? |
|--------------|-----------------|------------|---------------------|
| **Customer (renter)** | "Instances" tab — list of GPUs they have rented | Container API key only | ❌ No |
| **Host (provider)** | "Host → Machines" tab — list of GPUs they have listed | Host API key with `/machines/` endpoint | ✅ Yes |

When you `pip install raicompute && raicompute install --provider-slug vast` inside a rented container:

1. Daemon installs successfully — files arrive at `/var/lib/vastai_kaalia/`.
2. Daemon connects to Vast.ai controller (TCP port 7071) using its own protocol with `machine_uuid` auth. **This bypasses the API key system**, so it succeeds.
3. Daemon sends `Identify` with a freshly generated `machine_id`. Vast.ai's controller acknowledges the connection but does **not** create a marketplace machine entry under any host account because no host account is associated with this `machine_id`.
4. `raicompute host-metrics` calls `https://console.vast.ai/api/v0/machines/` over **HTTP**, not the daemon's TCP protocol. The HTTP API requires a host API key in the `Authorization` header.
5. The container only has a `CONTAINER_API_KEY` (visible in `env | grep CONTAINER_API_KEY`). This key has scope for managing the rented container — not for listing host machines. The HTTP API rejects it with **`401 Unauthorized`**.

You can confirm this by inspecting the env:

```bash
env | grep -iE "vast|api_key"
# CONTAINER_API_KEY=...   <-- container scope, not host scope
# VAST_TCP_PORT_22=...
# VAST_CONTAINERLABEL=C.xxxxxxxx
```

There is no environment variable named `VAST_API_KEY` or anything else with host-level scope. raicompute has no way to authenticate as a host from inside a rented container, by design.

**Conclusion:** A rented Vast.ai container can never become a Vast.ai host. To run raicompute, you need a machine where **you control the OS and have a host API key** — i.e., a real server you own or rent at the OS level.

---

## 17. Hardware Recommendations

### What to look for in a GPU

- **VRAM:** 16 GB is the minimum that gets rented. 24 GB is the sweet spot for current LLM workloads. 48 GB+ commands premium rates.
- **Compute generation:** RTX 30-series, 40-series, A-series, L-series, and H-series all work. Older Pascal/Volta cards (P100, V100) are mostly obsolete for inference rates.
- **Memory bandwidth:** matters more than core count for LLM inference. Check the GPU spec sheet.
- **PCIe lanes:** for multi-GPU builds, allocate at least PCIe 4.0 x8 per card. PCIe 3.0 x4 bottlenecks larger models.

### Build considerations

- Used cards from miners typically work fine — buy used unless warranty matters
- Multi-GPU machines benefit from server-grade motherboards with sufficient PCIe lanes
- ECC RAM is not strictly needed for inference but reduces silent corruption — worth it for high-end builds
- Cooling matters: a thermal-throttling GPU loses rentals fast. Budget for good airflow and consider undervolting for sustained load.
- Add a UPS to protect against power outages — they ruin reliability scores.

### What earnings depend on

Earnings are not deterministic. They depend on:

- Your GPU's relative position on the Vast.ai marketplace (supply vs demand for that model)
- Your reliability score (built up over weeks of uptime)
- Your pricing strategy (see Section 10)
- Republic Network inference job volume (varies by season and overall network activity)
- Your geographic location (some renters prefer specific regions)

Track real numbers via `host-metrics` and the Vast.ai dashboard for at least a month before making projections. Numbers from other hosts are not reliable predictors of your own setup.

## 18. Alternative Hosting Options

If you do not have your own GPU machine, here are realistic ways to participate as a Republic AI compute provider.

### Option A — Use your own PC

- Best ROI if you have an idle gaming PC with NVIDIA GPU
- Run Ubuntu 22.04 in dual-boot or fresh install
- Open ports `7071` and `22` outbound; nothing inbound is required
- Stable internet and 24/7 uptime maximize earnings

### Option B — Dedicated GPU server

| Provider | GPU Options | Approx. Monthly Cost (USD) | Notes |
|----------|-------------|------------------------------|-------|
| **Hetzner** | RTX 4000 SFF Ada, RTX 6000 Ada | $250–$700 | Germany/Finland; best value |
| **OVH** | RTX A4000, A5000, A6000 | $400–$900 | EU/NA; flexible terms |
| **Latitude.sh** | RTX 4090, A6000, H100 | $500–$2500 | NA/EU/APAC; bare metal |
| **Lambda Labs** | A100, H100, H200 | $1500+ | Best for high-end; expensive |
| **Coreweave** | A40, A100, H100 | Custom | Enterprise; large scale |

You get full root access — raicompute and Vast.ai daemon install cleanly. List the machine on Vast.ai marketplace **and** earn raicompute rewards on top. Break-even depends on rental occupancy; track `host-metrics` carefully the first month.

### Option C — Cloud GPU VM (AWS, GCP, Azure)

- Most expensive per GPU-hour; usually not profitable for compute-provider economics
- AWS `g5.xlarge` with 1× A10G runs ~$1.00/hr but you can only rent it out at ~$0.30/hr → loses money
- Useful for testing or if you have unused cloud credits

### Option D — Validator only, no compute provider

- If you already run a validator, you continue to earn validator rewards (Season 2 allocates 5%)
- This requires no GPU and no raicompute setup
- Fine to skip the provider role entirely if you do not want to invest in hardware

### Option E — Rent and re-list (NOT recommended)

Renting a GPU from a cloud provider and trying to re-list it as your "host" machine on Vast.ai is technically possible (if the provider gives you root access) but:

- Margins are typically negative (cloud GPU costs more than Vast.ai rentals pay)
- Reliability score suffers because cloud VMs reboot for maintenance
- Some cloud providers' ToS prohibit re-renting
- **For Vast.ai specifically: rented containers cannot become hosts at all.** This was tested hands-on. See Section 3 and Section 16 for the technical reason.

Skip this option unless you have a specific edge.

---

## 19. Frequently Asked Questions

### Q: Can I run raicompute on multiple machines with the same wallet?

Yes. `raicompute install` registers each machine separately. They all earn into the same wallet.

### Q: Can I run raicompute on Windows?

Not officially supported. Vast.ai daemon is Linux-only. Use WSL2 only for testing — production needs native Linux.

### Q: Do I need to run a Republic node on the same machine?

No. raicompute is independent of running a Republic blockchain node.

### Q: Is my wallet's private key safe on the host machine?

Only your **signature** is stored in `~/.republic_session.json`, not the private key or mnemonic. Even if the host is compromised, the attacker cannot drain your wallet — only spoof your provider identity (which is a much smaller risk).

### Q: How do I update raicompute?

```bash
pip install --upgrade raicompute
```

The Vast.ai daemon updates itself hourly from `s3.amazonaws.com/public.vast.ai/kaalia/daemons` (see `update_*.log`).

### Q: Can I uninstall and reinstall later?

Yes. To uninstall:

```bash
sudo systemctl stop vastai.service vast_metrics.service vastai_bouncer.service
sudo systemctl disable vastai.service vast_metrics.service vastai_bouncer.service
sudo rm -rf /var/lib/vastai_kaalia
sudo userdel vastai_kaalia
pip uninstall raicompute
rm ~/.republic_session.json
```

To reinstall, follow this guide from Step 1. Note: you may lose your reliability score and have to re-build it.

### Q: What if Vast.ai is down?

The Vast.ai daemon retries connecting indefinitely. Once Vast.ai recovers, your daemon reconnects automatically without you doing anything.

### Q: Will my GPU last?

GPUs running 24/7 at 80–100% utilization last 3–5 years before fan failures (replaceable for $20) or VRAM degradation. Most consumer GPUs outlast their warranty under continuous load. Used cards from miners typically work fine despite the FUD.

### Q: How do I withdraw earnings?

- **Vast.ai earnings:** Withdraw from https://cloud.vast.ai/host/billing/ to your bank or crypto wallet
- **Republic earnings:** Auto-paid to your wallet (`republic1...`) on the chain

### Q: What is the minimum payout?

- Vast.ai: $20 minimum withdrawal
- Republic: No minimum; rewards arrive on-chain immediately

### Q: Can I pause hosting temporarily?

Yes:

```bash
sudo systemctl stop vastai.service vast_metrics.service vastai_bouncer.service
```

This brings your machine offline. Your reliability score will degrade if offline for hours. To resume:

```bash
sudo systemctl start vastai.service vast_metrics.service vastai_bouncer.service
```

### Q: Is there a Republic-only mode that skips Vast.ai integration?

As of `raicompute 0.1.0`, no. The CLI requires `--provider-slug vast` (or another supported provider). Future versions may support standalone hosting.

---

## License

This guide is published under the MIT License. Use freely.

## Disclaimer

This is a community-written guide based on hands-on testing of `raicompute 0.1.0`. The Republic AI team has not officially endorsed it. Behavior may change in newer versions. If anything is wrong or out of date, please open an issue or pull request at https://github.com/M4D2510/raicompute-setup-guide

## Contributing

Found something wrong, missing, or out of date? Open an issue or pull request.

Particularly welcome:

- New provider slugs supported by raicompute (besides `vast`)
- Earnings data from real hosts
- Alternative hosting platforms (decentralized, sovereign cloud, etc.)
- Hardware benchmarks for Republic-specific workloads
