# 🟢 RAMUP v2.0.0

**"More RAM. Zero Cost. No Bullshit."**

Advanced VPS Memory Extension Engine. Works with ANY RAM size. Any distro. Any VPS.

```
Your RAM → ~1.5-2x Effective RAM
Cost: $0
Time: 30 seconds
```

## Quick Install

```bash
sudo bash install.sh
```

## Commands

### Core
| Command | Description |
|---------|-------------|
| `ramup install` | Install and activate |
| `ramup uninstall` | Remove and restore defaults |
| `ramup status` | Memory status card |
| `ramup monitor` | Live memory dashboard |
| `ramup on` | Enable all features |
| `ramup off` | Disable safely |

### Optimization
| Command | Description |
|---------|-------------|
| `ramup tune` | Auto-tune for workload |
| `ramup optimize` | Deep memory optimization |
| `ramup profile <process>` | Profile memory by process |
| `ramup fix` | Auto-fix memory issues |
| `ramup boost` | Instant memory boost |

### Intelligence
| Command | Description |
|---------|-------------|
| `ramup analyze` | Analyze memory & suggest fixes |
| `ramup predict` | Predict memory exhaustion |
| `ramup watch <process>` | Watch for memory leaks |
| `ramup top` | Interactive memory top |

### Docker
| Command | Description |
|---------|-------------|
| `ramup docker-opt` | Optimize Docker memory |
| `ramup docker-limit <c> <mb>` | Set container limits |
| `ramup docker-stats` | Container memory stats |

### System
| Command | Description |
|---------|-------------|
| `ramup health` | Full health check |
| `ramup benchmark` | Performance benchmark |
| `ramup sysinfo` | System information |
| `ramup services` | Services by memory |

### Safety
| Command | Description |
|---------|-------------|
| `ramup backup` | Create backup |
| `ramup restore` | Restore from backup |
| `ramup rollback` | Undo last changes |
| `ramup logs` | View logs |

## How It Works

```
┌─────────────────────────────────────────────┐
│          Your VPS (any RAM size)            │
│                                             │
│  ┌──────────────┐  ┌──────────────┐        │
│  │  Normal RAM  │  │  ZRAM        │        │
│  │  (physical)  │  │  (compressed)│        │
│  │  (fast)      │  │  (fast-ish)  │        │
│  └──────────────┘  └──────────────┘        │
│                                             │
│  ┌──────────────┐  ┌──────────────┐        │
│  │  Swap File   │  │  Kernel      │        │
│  │  (overflow)  │  │  (tuned)     │        │
│  │  (backup)    │  │  (optimized) │        │
│  └──────────────┘  └──────────────┘        │
│                                             │
│  Effective: ~1.5-2x your actual RAM 🚀     │
└─────────────────────────────────────────────┘
```

## Smart Sizing

RAMUP adapts to ANY RAM size:

| Your RAM | ZRAM | Swap | Effective |
|----------|------|------|-----------|
| 512MB | 768MB | 1.5GB | ~2.7GB |
| 1GB | 1.25GB | 2GB | ~4.2GB |
| 2GB | 2GB | 3GB | ~7GB |
| 4GB | 3GB | 4GB | ~11GB |
| 8GB | 4GB | 6GB | ~18GB |
| 16GB | 5.6GB | 8GB | ~29.6GB |
| 32GB | 8GB | 11.2GB | ~51.2GB |
| 64GB | 9.6GB | 16GB | ~89.6GB |

## Features

- 🗜️ **ZRAM Engine** — Compressed RAM with auto algorithm selection
- 💽 **Smart Swap** — SSD-aware, auto-sized swap
- ⚙️ **Kernel Tuning** — Optimized memory parameters
- 🔄 **Auto-Adjust** — Real-time workload adaptation
- 🐳 **Docker Optimization** — Container memory management
- 📊 **Memory Profiling** — Per-process analysis
- 🔮 **Predictive** — Memory exhaustion prediction
- 👁️ **Leak Detection** — Watch processes for leaks
- 🏥 **Health Check** — 8-point diagnostic
- 🛡️ **Safety Net** — Backup & one-command rollback
- 📺 **Live Dashboard** — Real-time monitoring
- ⚡ **Instant Boost** — Emergency memory recovery

## Compatibility

- ✅ Ubuntu / Debian
- ✅ CentOS / RHEL / Fedora
- ✅ Arch Linux
- ✅ Alpine Linux
- ✅ Any Linux kernel 3.14+
- ✅ KVM / OpenVZ / VMware / Physical
- ✅ SSD and HDD
- ✅ Any RAM size (256MB to 128GB+)

## License

MIT

---

**🟢 RAMUP — More RAM. Zero Cost. No Bullshit.**
