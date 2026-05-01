<p align="center">
  <br>
  <img src="https://raw.githubusercontent.com/Atum246/ramup/master/docs/ramup-logo.svg" alt="RAMUP" width="400">
  <br>
  <br>
</p>

<p align="center">
  <strong>More RAM. Zero Cost. No Bullshit.</strong>
</p>

<p align="center">
  <a href="#-quick-install"><img src="https://img.shields.io/badge/install-one--click-green?style=flat-square" alt="Install"></a>
  <a href="https://github.com/Atum246/ramup/blob/master/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="License"></a>
  <a href="https://github.com/Atum246/ramup/releases"><img src="https://img.shields.io/badge/version-v2.0.0-orange?style=flat-square" alt="Version"></a>
  <img src="https://img.shields.io/badge/platform-linux-lightgrey?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/bash-3.14+-yellow?style=flat-square" alt="Bash">
</p>

<p align="center">
  Advanced VPS Memory Extension Engine — Works with ANY RAM size. Any distro. Any VPS.<br>
  <a href="https://atum246.github.io/ramup/">🌐 Website</a> · <a href="#-commands">Commands</a> · <a href="#-vps-provider-guides">VPS Guides</a>
</p>

---

## 🤔 What Is RAMUP?

RAMUP is a Linux memory extension engine that makes your cheap VPS behave like it has **way more RAM** — for free. It combines ZRAM, smart swap, kernel tuning, and a real-time auto-adjust daemon to squeeze maximum performance out of minimal hardware.

```
Your VPS (4GB RAM)  →  After RAMUP  →  ~11GB Effective RAM
Cost: $0
Time: 30 seconds
```

**No kernel modifications. No proprietary software. Just proven Linux features, automated and optimized.**

---

## ⚡ Quick Install

**One-liner:**
```bash
curl -sL ramup.io/install | bash
```

**Or clone and install:**
```bash
git clone https://github.com/Atum246/ramup.git
cd ramup/ramup
sudo bash install.sh
```

**Verify it's working:**
```bash
ramup status
```

---

## ☁️ VPS Provider Guides

RAMUP works on any Linux VPS. Here are step-by-step guides for popular providers:

### 🔵 DigitalOcean Droplets

```bash
# SSH into your droplet
ssh root@your-droplet-ip

# Install RAMUP
curl -sL ramup.io/install | bash

# Verify
ramup status
```

**Tips for DigitalOcean:**
- Works on all droplet sizes (including the $4/mo 512MB)
- DigitalOcean droplets use SSD — swap performance is excellent
- Recommended: Use the "Regular" CPU option for best ZRAM compression

### 🟠 Vultr VPS

```bash
# SSH into your instance
ssh root@your-vultr-ip

# Install RAMUP
curl -sL ramup.io/install | bash

# Verify
ramup status
```

**Tips for Vultr:**
- Vultr uses NVMe SSDs on all plans — swap is fast
- Works great on the $2.50/mo 512MB instance
- High Frequency instances get even better ZRAM performance

### 🟢 Linode / Akamai

```bash
# SSH into your Linode
ssh root@your-linode-ip

# Install RAMUP
curl -sL ramup.io/install | bash

# Verify
ramup status
```

**Tips for Linode:**
- Linode uses NVMe on newer plans
- The 1GB Nanode ($5/mo) goes from 1GB → ~4.2GB effective
- Enable the "Backup" service for extra safety

### 🔴 Hetzner Cloud

```bash
# SSH into your server
ssh root@your-hetzner-ip

# Install RAMUP
curl -sL ramup.io/install | bash

# Verify
ramup status
```

**Tips for Hetzner:**
- Hetzner's CX11 (2GB) becomes ~7GB effective — incredible value
- All plans use NVMe/SSD storage
- Hetzner's ARM (CAX) plans work perfectly too

### 🟣 AWS EC2

```bash
# SSH into your instance
ssh -i your-key.pem ec2-user@your-instance-ip

# Install RAMUP (requires sudo)
sudo bash -c "$(curl -sL ramup.io/install)"

# Verify
ramup status
```

**Tips for AWS:**
- Works on t2/t3/t4g micro instances (1GB → ~4.2GB)
- `t4g` (ARM/Graviton) instances work perfectly
- EBS-backed instances have moderate swap speed — use `gp3` volumes
- Consider enabling [EBS optimization](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-optimized.html)

### 🟡 Google Cloud (GCP)

```bash
# SSH via gcloud
gcloud compute ssh your-instance-name

# Install RAMUP
curl -sL ramup.io/install | bash

# Verify
ramup status
```

**Tips for GCP:**
- Works on `e2-micro` and `e2-small` instances
- GCP's `e2-micro` (1GB shared) benefits massively from ZRAM
- Use SSD persistent disks for better swap performance

### ⚪ Oracle Cloud Free Tier

```bash
# SSH into your instance
ssh -i your-key opc@your-instance-ip

# Install RAMUP
curl -sL ramup.io/install | bash

# Verify
ramup status
```

**Tips for Oracle Cloud:**
- The Always Free ARM instance (4 cores, 24GB RAM) is overkill — but RAMUP still optimizes it
- The AMD free tier (1GB RAM) benefits the most: 1GB → ~4.2GB effective
- Oracle uses block storage — swap speed depends on volume performance

### 🟤 Contabo VPS

```bash
# SSH into your VPS
ssh root@your-contabo-ip

# Install RAMUP
curl -sL ramup.io/install | bash

# Verify
ramup status
```

**Tips for Contabo:**
- Contabo is known for offering lots of RAM for cheap — RAMUP makes it even better
- Their VPS S (4GB) becomes ~11GB effective
- Contabo uses SSD storage on most plans

### 💜 Alibaba Cloud (ECS)

```bash
# SSH into your instance
ssh root@your-alibaba-ip

# Install RAMUP
curl -sL ramup.io/install | bash

# Verify
ramup status
```

**Tips for Alibaba Cloud:**
- Works on all ECS instance types including `ecs.t6` (burstable)
- The 1GB `ecs.t6-c1m1.large` goes from 1GB → ~4.2GB effective
- Use Enhanced SSD for best swap performance

### 🔷 Azure Virtual Machines

```bash
# SSH into your VM
ssh azureuser@your-vm-ip

# Install RAMUP (requires sudo)
sudo bash -c "$(curl -sL ramup.io/install)"

# Verify
ramup status
```

**Tips for Azure:**
- Works on B-series burstable instances (B1s 1GB → ~4.2GB)
- Use Premium SSD for swap — Standard HDD is too slow
- The free tier B1s (1GB) benefits the most

### General VPS Tips

| Provider | Min RAM | Best Plan for RAMUP | SSD Type |
|----------|---------|---------------------|----------|
| DigitalOcean | 512MB | $6/mo (1GB → 4.2GB) | SSD |
| Vultr | 512MB | $2.50/mo (512MB → 2.7GB) | NVMe |
| Hetzner | 2GB | €3.29/mo (2GB → 7GB) | NVMe |
| AWS EC2 | 1GB | t4g.micro (1GB → 4.2GB) | EBS gp3 |
| GCP | 1GB | e2-micro (1GB → 4.2GB) | SSD |
| Oracle | 1GB | Free AMD (1GB → 4.2GB) | Block |
| Contabo | 4GB | VPS S (4GB → 11GB) | SSD |
| Alibaba | 1GB | t6 burstable (1GB → 4.2GB) | ESSD |
| Azure | 1GB | B1s (1GB → 4.2GB) | Premium |

---

## 🎯 How It Works

RAMUP uses **four engines** working together:

### 1. 🗜️ ZRAM Engine
Creates a compressed block device **inside your RAM**. Data that doesn't fit in normal RAM gets compressed — like having a secret pocket dimension in your memory.

```
Physical RAM: 4GB
ZRAM Size:    3GB (compressed with lzo)
Compression:  ~2.5:1 ratio
Effective:    ~7.5GB usable
```

### 2. 💾 Smart Swap
A swap file on disk acts as overflow when RAM and ZRAM are full. Automatically detects SSD vs HDD — SSD-backed swap is **100x faster** than spinning disks.

### 3. 🔧 Kernel Tuning
Optimized `sysctl` parameters for memory management:

| Parameter | Value | Effect |
|-----------|-------|--------|
| `vm.swappiness` | 10 | Prefer RAM over swap |
| `vm.vfs_cache_pressure` | 150 | Reclaim cache aggressively |
| `vm.overcommit_memory` | 1 | Allow memory overcommit |
| `vm.dirty_ratio` | 10 | Flush dirty pages sooner |
| `vm.dirty_background_ratio` | 5 | Start flushing earlier |

### 4. 🤖 Auto-Adjust Daemon
A background systemd service monitors memory pressure in **real-time** and adjusts parameters dynamically:

| Pressure Level | Threshold | Behavior |
|---------------|-----------|----------|
| 🟢 Low | < 50% | Relaxed settings |
| 🟡 Medium | 50-75% | Balanced |
| 🟠 High | 75-90% | Aggressive swap |
| 🔴 Critical | > 90% | Maximum recovery |

---

## 📊 Smart Sizing — Any RAM, Automatically

RAMUP adapts to **ANY** RAM size. Here's what to expect:

| Your RAM | ZRAM | Swap | Effective | Gain |
|----------|------|------|-----------|------|
| 512MB | 768MB | 1.5GB | **~2.7GB** | 5.4x |
| 1GB | 1.25GB | 2GB | **~4.2GB** | 4.2x |
| 2GB | 2GB | 3GB | **~7GB** | 3.5x |
| 4GB | 3GB | 4GB | **~11GB** | 2.75x |
| 8GB | 4GB | 6GB | **~18GB** | 2.25x |
| 16GB | 5.6GB | 8GB | **~30GB** | 1.87x |
| 32GB | 8GB | 11GB | **~51GB** | 1.59x |
| 64GB | 9.6GB | 16GB | **~90GB** | 1.41x |

> ⚠️ **Note:** "Effective" includes ZRAM + swap. ZRAM performs close to real RAM; swap on disk is slower. Actual performance depends on workload.

---

## 🛠️ Commands

### Core
```bash
ramup install          # Install and activate everything
ramup uninstall        # Remove and restore defaults
ramup status           # Memory status card with visual bars
ramup monitor          # Live memory dashboard (refreshing)
ramup on               # Enable all features
ramup off              # Disable all features safely
```

### Optimization
```bash
ramup tune             # Auto-tune for current workload
ramup optimize         # Deep memory optimization
ramup profile <name>   # Profile memory by process name
ramup fix              # Auto-fix detected memory issues
ramup boost            # Instant boost (drop caches + compact)
```

### Intelligence
```bash
ramup analyze          # Memory analysis & suggestions
ramup predict          # Predict when memory will run out
ramup watch <process>  # Watch a process for memory leaks
ramup top              # Interactive memory top viewer
```

### Docker
```bash
ramup docker-opt       # Optimize Docker memory usage
ramup docker-limit     # Set memory limits per container
ramup docker-stats     # Container memory statistics
```

### System
```bash
ramup health           # 8-point system health check
ramup benchmark        # Memory performance benchmark
ramup sysinfo          # Detailed system information
ramup services         # List services sorted by memory usage
```

### Backup & Safety
```bash
ramup backup           # Create a manual backup
ramup restore          # Restore from latest backup
ramup rollback         # Undo last changes
ramup logs             # View recent activity logs
ramup config           # Show/edit configuration
```

### Daemon Control
```bash
ramup daemon-start     # Start the auto-adjust daemon
ramup daemon-stop      # Stop the daemon
ramup daemon-status    # Check if daemon is running
```

### Global Options
| Option | Description |
|--------|-------------|
| `--force` | Skip confirmations |
| `--quiet` | Minimal output |
| `--verbose` | Extra logging |
| `--dry-run` | Show what would be done |
| `--aggressive` | Maximum performance mode |
| `--safe` | Conservative mode |
| `--json` | JSON output for scripting |

---

## 🐧 Compatibility

| Category | Support |
|----------|---------|
| **Distros** | Ubuntu, Debian, CentOS, RHEL, Fedora, Arch, Alpine |
| **Kernels** | Linux 3.14+ (required for ZRAM) |
| **Virtualization** | KVM, OpenVZ, VMware, Hyper-V, Xen, bare-metal |
| **Storage** | SSD, NVMe, HDD (SSD/NVMe recommended for swap) |
| **Architectures** | x86_64, ARM (aarch64) |
| **RAM Range** | 256MB to 128GB+ |

---

## 🛡️ Safety

RAMUP is designed to be **safe by default**:

1. **📸 Backup First** — Creates a full backup before making any changes
2. **🧱 Proven Tech** — Uses standard Linux features (ZRAM, swap, sysctl)
3. **⏪ One-Command Rollback** — `ramup off` or `ramup restore` undoes everything
4. **🛡️ Safe OOM Handling** — Never kills your apps unexpectedly
5. **📝 Full Logging** — Every action is logged for debugging
6. **🔄 Upgrade-Safe** — Detects existing installations and upgrades cleanly

---

## ⚠️ Important Notes

- **"Effective" RAM ≠ "Real" RAM** — ZRAM performs close to real RAM (compressed in-memory), but swap on disk is significantly slower
- **Swap on HDD is slow** — If your VPS uses spinning disks, swap will be a bottleneck for high-I/O workloads
- **Overcommit risks** — `vm.overcommit_memory=1` allows memory overcommit. The OOM killer may activate if you actually run out
- **Not a replacement for real RAM** — RAMUP helps survive memory spikes, but sustained memory pressure on a tiny VPS will always hit limits

---

## 📈 Benchmarks

```
RAM Write:      28ms for 1GB     (direct RAM — blazing fast)
Swap Write:     1301ms for 256MB (SSD disk — acceptable)
ZRAM:           Active with ~2.5:1 compression ratio
```

> Real-world performance depends on your workload, VPS provider, and storage type.

---

## 🤝 Contributing

Contributions are welcome! Here's how:

1. **Fork** the repository
2. **Create** your feature branch (`git checkout -b feature/awesome-thing`)
3. **Commit** your changes (`git commit -m 'Add awesome thing'`)
4. **Push** to the branch (`git push origin feature/awesome-thing`)
5. **Open** a Pull Request

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  <strong>🟢 RAMUP</strong> — More RAM. Zero Cost. No Bullshit.
  <br>
  <br>
  <a href="https://atum246.github.io/ramup/">Website</a> · <a href="https://github.com/Atum246/ramup">GitHub</a> · <a href="https://github.com/Atum246/ramup/issues">Issues</a> · <a href="https://github.com/Atum246/ramup/releases">Releases</a>
</p>
