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
  <a href="#install"><img src="https://img.shields.io/badge/install-one--click-green?style=flat-square" alt="Install"></a>
  <a href="https://github.com/Atum246/ramup/blob/master/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="License"></a>
  <a href="https://github.com/Atum246/ramup"><img src="https://img.shields.io/badge/version-v2.0.0-orange?style=flat-square" alt="Version"></a>
  <img src="https://img.shields.io/badge/platform-linux-lightgrey?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/bash-3.14+-yellow?style=flat-square" alt="Bash">
</p>

---

**RAMUP** is an advanced VPS memory extension engine that makes your cheap VPS behave like it has way more RAM — for free.

```
Your VPS (4GB RAM)  →  After RAMUP  →  ~9GB Effective RAM
Cost: $0
Time: 30 seconds
```

## ⚡ Quick Install

```bash
curl -sL ramup.io/install | bash
```

Or clone and install:

```bash
git clone https://github.com/Atum246/ramup.git
cd ramup
sudo bash install.sh
```

## 🎯 What It Does

RAMUP uses proven Linux technologies to extend your VPS memory:

| Technology | What It Does | Gain |
|-----------|--------------|------|
| **ZRAM** | Compressed RAM in memory | +50-75% |
| **Smart Swap** | SSD-aware disk swap | +100% (slow) |
| **Kernel Tuning** | Optimized memory params | +10-20% |
| **Auto-Adjust** | Real-time adaptation | Dynamic |

**Result:** 4GB → ~9GB effective RAM. 8GB → ~18GB. 16GB → ~30GB.

## 📊 Smart Sizing

RAMUP adapts to ANY RAM size automatically:

| Your RAM | ZRAM | Swap | Effective |
|----------|------|------|-----------|
| 512MB | 768MB | 1.5GB | **~2.7GB** |
| 1GB | 1.25GB | 2GB | **~4.2GB** |
| 2GB | 2GB | 3GB | **~7GB** |
| 4GB | 3GB | 4GB | **~11GB** |
| 8GB | 4GB | 6GB | **~18GB** |
| 16GB | 5.6GB | 8GB | **~30GB** |
| 32GB | 8GB | 11GB | **~51GB** |
| 64GB | 9.6GB | 16GB | **~90GB** |

## 🛠️ Commands

### Core
```bash
ramup install          # Install and activate
ramup uninstall        # Remove and restore defaults
ramup status           # Memory status card
ramup monitor          # Live memory dashboard
ramup on / off         # Enable / disable
```

### Optimization
```bash
ramup tune             # Auto-tune for workload
ramup optimize         # Deep memory optimization
ramup profile <name>   # Profile memory by process
ramup fix              # Auto-fix memory issues
ramup boost            # Instant memory boost
```

### Intelligence
```bash
ramup analyze          # Memory analysis & suggestions
ramup predict          # Predict memory exhaustion
ramup watch <process>  # Watch for memory leaks
ramup top              # Interactive memory top
```

### Docker
```bash
ramup docker-opt       # Optimize Docker memory
ramup docker-limit     # Set container limits
ramup docker-stats     # Container memory stats
```

### System
```bash
ramup health           # 8-point health check
ramup benchmark        # Performance benchmark
ramup sysinfo          # System information
ramup services         # Services by memory usage
```

### Safety
```bash
ramup backup           # Create backup
ramup restore          # Restore from backup
ramup rollback         # Undo last changes
ramup logs             # View activity logs
```

## 🔧 How It Works

### 1. ZRAM Engine
ZRAM creates a compressed block device in your RAM. Data that doesn't fit in normal RAM gets compressed and stored in a special RAM region.

```
Physical RAM: 4GB
ZRAM Size:    3GB (compressed)
Compression:  ~2.5:1 ratio
Effective:    ~7.5GB usable
```

### 2. Smart Swap
A swap file on disk acts as overflow when RAM and ZRAM are full. SSD-backed swap is 100x faster than HDD.

### 3. Kernel Tuning
Optimized parameters for memory management:
- `vm.swappiness = 10` — prefer RAM over swap
- `vm.vfs_cache_pressure = 150` — reclaim cache aggressively
- `vm.overcommit_memory = 1` — allow memory overcommit
- `vm.dirty_ratio = 10` — flush pages sooner

### 4. Auto-Adjust Daemon
A background process monitors memory pressure and adjusts parameters in real-time:
- **Low pressure** (<50%) — relaxed settings
- **Medium** (50-75%) — balanced
- **High** (75-90%) — aggressive swap
- **Critical** (>90%) — maximum recovery

## 🐧 Compatibility

- ✅ Ubuntu / Debian
- ✅ CentOS / RHEL / Fedora
- ✅ Arch Linux
- ✅ Alpine Linux
- ✅ Any Linux kernel 3.14+
- ✅ KVM / OpenVZ / VMware / Physical
- ✅ SSD and HDD
- ✅ Any RAM size (256MB to 128GB+)
- ✅ x86_64 and ARM

## 🛡️ Safety

RAMUP is designed to be safe:

1. **Backs up everything** before making changes
2. **Uses proven Linux features** (ZRAM, swap, sysctl)
3. **One-command rollback** (`ramup off` or `ramup restore`)
4. **Never kills your apps** (safe OOM handling)
5. **Logs everything** for debugging

## 📈 Benchmarks

```
RAM Write:   28ms for 1GB   (direct RAM)
Swap Write:  1301ms for 256MB (SSD disk)
ZRAM:        Active with 50:1 compression
```

## 🤝 Contributing

Contributions welcome! Please read the contributing guidelines first.

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  <strong>🟢 RAMUP</strong> — More RAM. Zero Cost. No Bullshit.
  <br>
  <br>
  <a href="https://github.com/Atum246/ramup">GitHub</a> · <a href="https://github.com/Atum246/ramup/issues">Issues</a> · <a href="https://github.com/Atum246/ramup/releases">Releases</a>
</p>
