# 🟢 RAMUP

**"Your 4GB just became 7GB"**

Advanced VPS memory extension tool. Safe. Simple. Powerful.

## What It Does

RAMUP makes your cheap VPS behave like it has way more RAM — for free.

```
4GB Physical RAM → ~7GB Effective RAM
Cost: $0
```

### How?

- **ZRAM** — Compressed RAM in memory (biggest win! +50-75%)
- **Smart Swap** — Disk-based overflow (safety net)
- **Kernel Tuning** — Optimized memory parameters
- **Auto-Adjust** — Adapts to your workload in real-time
- **Safety Net** — Rollback if anything goes wrong

## Quick Install

```bash
# One-liner install
curl -sL ramup.io/install | bash

# Or clone and install
git clone https://github.com/ramup/ramup.git
cd ramup
sudo bash install.sh
```

## Commands

```bash
ramup install     # Install and activate
ramup uninstall   # Remove and restore defaults
ramup status      # Show memory status
ramup monitor     # Live memory dashboard
ramup on          # Enable all features
ramup off         # Disable safely
ramup tune        # Auto-tune for workload
ramup health      # System health check
ramup benchmark   # Test performance
ramup logs        # View logs
ramup backup      # Create backup
ramup restore     # Restore from backup
ramup config      # Show configuration
ramup help        # Show help
```

## Features

### 🗜️ ZRAM Engine
- Automatic compression algorithm selection (zstd > lz4 > lzo)
- CPU-aware parallel compression streams
- Optimal sizing based on available RAM

### 💽 Smart Swap
- Auto-sized based on RAM and disk type
- SSD-aware (reduced wear)
- Emergency fallback when ZRAM is full

### ⚙️ Kernel Tuning
- Swappiness optimization
- Memory overcommit handling
- Cache pressure adjustment
- Dirty page tuning
- OOM behavior configuration

### 🔄 Auto-Adjust Daemon
- Real-time workload detection
- Dynamic parameter adjustment
- Memory pressure response
- Automatic cache dropping when critical

### 🛡️ Safety Net
- Pre-install backup
- One-command rollback
- Health monitoring
- OOM kill detection

### 📊 Live Monitor
- Real-time memory dashboard
- ZRAM compression stats
- Process memory usage
- System health indicators

## Compatibility

- ✅ Ubuntu / Debian
- ✅ CentOS / RHEL / Fedora
- ✅ Arch Linux
- ✅ Alpine Linux
- ✅ Any Linux with kernel 3.14+

## Requirements

- Linux kernel 3.14+ (for ZRAM)
- Root access
- 512MB+ free disk space
- bc, awk, sed, grep (auto-installed)

## How It Works

```
┌─────────────────────────────────────────────┐
│          Your VPS (4GB RAM)                 │
│                                             │
│  ┌──────────────┐  ┌──────────────┐        │
│  │  Normal RAM  │  │  ZRAM        │        │
│  │  4GB         │  │  3GB (comp)  │        │
│  │  (fast)      │  │  (fast-ish)  │        │
│  └──────────────┘  └──────────────┘        │
│                                             │
│  ┌──────────────┐  ┌──────────────┐        │
│  │  Swap File   │  │  Kernel      │        │
│  │  4GB (slow)  │  │  Tuning      │        │
│  │  (backup)    │  │  (optimized) │        │
│  └──────────────┘  └──────────────┘        │
│                                             │
│  Effective: ~7-8GB usable memory 🚀        │
└─────────────────────────────────────────────┘
```

## Safety

RAMUP is designed to be safe:

1. **Backs up everything** before making changes
2. **Uses proven Linux features** (ZRAM, swap, sysctl)
3. **One-command rollback** (`ramup off` or `ramup restore`)
4. **Never kills your apps** (safe OOM handling)
5. **Logs everything** for debugging

## License

MIT License — Use freely, modify freely, share freely.

---

**Made with 🟢 by the RAMUP team**

*"Your 4GB just became 7GB"*
