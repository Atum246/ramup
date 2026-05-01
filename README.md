<p align="center">
  <br>
  <img src="https://raw.githubusercontent.com/Atum246/ramup/master/docs/ramup-logo.png" alt="RAMUP" width="400">
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
  Advanced VPS Memory Extension Engine — Works with ANY RAM size. Any distro. Any VPS.
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

## 🎯 How It Works

RAMUP uses **four engines** working together to extend your memory:

### 1. 🗜️ ZRAM Engine
Creates a compressed block device **inside your RAM**. Data that doesn't fit in normal RAM gets compressed and stored in a special region — like having a secret pocket dimension in your memory.

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

## 🛠️ Full Command Reference

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
```bash
--force                # Skip confirmations
--quiet                # Minimal output
--verbose              # Extra logging
--dry-run              # Show what would be done without doing it
--aggressive           # Maximum performance mode
--safe                 # Conservative mode
--json                 # JSON output (for scripting)
```

---

## 🐧 Compatibility

| Category | Support |
|----------|---------|
| **Distros** | Ubuntu, Debian, CentOS, RHEL, Fedora, Arch, Alpine |
| **Kernels** | Linux 3.14+ (required for ZRAM) |
| **Virtualization** | KVM, OpenVZ, VMware, Hyper-V, bare-metal |
| **Storage** | SSD and HDD (SSD recommended for swap) |
| **Architectures** | x86_64, ARM |
| **RAM Range** | 256MB to 128GB+ |

---

## 🛡️ Safety Design

RAMUP is built to be **safe by default**:

1. **📸 Backup First** — Creates a full backup before making any changes
2. **🧱 Proven Tech** — Uses standard Linux features (ZRAM, swap, sysctl), not experimental hacks
3. **⏪ One-Command Rollback** — `ramup off` or `ramup restore` undoes everything
4. **🛡️ Safe OOM Handling** — Never kills your apps unexpectedly
5. **📝 Full Logging** — Every action is logged for debugging
6. **🔄 Upgrade-Safe** — Detects existing installations and upgrades cleanly

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

Please read the contributing guidelines before submitting.

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  <strong>🟢 RAMUP</strong> — More RAM. Zero Cost. No Bullshit.
  <br>
  <br>
  <a href="https://github.com/Atum246/ramup">GitHub</a> · <a href="https://github.com/Atum246/ramup/issues">Issues</a> · <a href="https://github.com/Atum246/ramup/releases">Releases</a>
</p>
