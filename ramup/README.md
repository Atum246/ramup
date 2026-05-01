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
  <a href="https://atum246.github.io/ramup/">🌐 Website</a> · <a href="#-commands">Commands</a> · <a href="#-vps--cloud-provider-guides">VPS Guides</a>
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

**Verify:**
```bash
ramup status
```

---

## ☁️ VPS & Cloud Provider Guides

### 🔵 DigitalOcean
```bash
ssh root@your-ip
curl -sL ramup.io/install | bash
```
- **Best plan:** $4/mo droplet (1GB → ~4.2GB effective)
- All plans use SSD. "Regular" CPU for best ZRAM compression.

### 🟠 Vultr
```bash
ssh root@your-ip
curl -sL ramup.io/install | bash
```
- **Best plan:** $2.50/mo (512MB → ~2.7GB effective)
- NVMe on all plans — swap is blazing fast. High Frequency instances get even better ZRAM.

### 🟢 Hetzner
```bash
ssh root@your-ip
curl -sL ramup.io/install | bash
```
- **Best plan:** €3.29/mo CX22 (2GB → ~7GB effective)
- Best value in Europe. NVMe on all plans. ARM (CAX) plans work perfectly too.

### 🟣 Linode / Akamai
```bash
ssh root@your-ip
curl -sL ramup.io/install | bash
```
- **Best plan:** $5/mo Nanode (1GB → ~4.2GB effective)
- NVMe on newer plans. Enable Backups for extra safety.

### 🔴 AWS EC2
```bash
ssh -i key.pem ec2-user@your-ip
sudo bash -c "$(curl -sL ramup.io/install)"
```
- **Best plan:** t4g.micro (free tier eligible, 1GB → ~4.2GB)
- t2/t3/t4g all work. ARM Graviton (t4g) is great. Use gp3 EBS for swap speed.

### 🟡 Google Cloud (GCP)
```bash
gcloud compute ssh instance
curl -sL ramup.io/install | bash
```
- **Best plan:** e2-micro (free tier, 1GB → ~4.2GB)
- e2-micro is free forever. Use SSD persistent disks for swap.

### 🟤 Oracle Cloud
```bash
ssh -i key opc@your-ip
curl -sL ramup.io/install | bash
```
- **Best plan:** Always Free ARM (4 cores, 24GB) or AMD (1 core, 1GB)
- Best free tier in cloud. AMD instance benefits most from RAMUP.

### 🔷 Azure
```bash
ssh azureuser@your-ip
sudo bash -c "$(curl -sL ramup.io/install)"
```
- **Best plan:** B1s (free tier, 1GB → ~4.2GB)
- B-series burstable benefits most. Use Premium SSD — Standard HDD is too slow.

### 🟤 Contabo
```bash
ssh root@your-ip
curl -sL ramup.io/install | bash
```
- **Best plan:** VPS S €4.99/mo (4GB → ~11GB effective)
- Known for cheap RAM-heavy plans. RAMUP makes them unbeatable value.

### 💜 Alibaba Cloud (ECS)
```bash
ssh root@your-ip
curl -sL ramup.io/install | bash
```
- **Best plan:** t6 burstable 1GB → ~4.2GB effective
- All ECS types work. Use Enhanced SSD (ESSD) for swap.

### 🟦 Scaleway
```bash
ssh root@your-ip
curl -sL ramup.io/install | bash
```
- **Best plan:** DEV1-S €7.99/mo (4GB → ~11GB effective)
- French cloud. NVMe on all plans. Global data centers.

### ⬛ UpCloud
```bash
ssh root@your-ip
curl -sL ramup.io/install | bash
```
- **Best plan:** €7/mo 2GB → ~7GB effective
- MaxIOPS storage is extremely fast — swap performance is excellent.

### 🟫 OVHcloud
```bash
ssh root@your-ip
curl -sL ramup.io/install | bash
```
- **Best plan:** €3.50/mo → ~4.2GB effective
- Huge European provider. NVMe on recent plans. Anti-DDoS included.

### 🟨 Hostinger
```bash
ssh root@your-ip
curl -sL ramup.io/install | bash
```
- **Best plan:** $5.99/mo 1GB → ~4.2GB effective
- Budget-friendly. NVMe storage. KVM virtualization.

### ⬛ Kamatera
```bash
ssh root@your-ip
curl -sL ramup.io/install | bash
```
- **Best plan:** $4/mo 1GB → ~4.2GB effective
- 13 global data centers. 30-day free trial.

### ⬛ CloudSigma
```bash
ssh root@your-ip
curl -sL ramup.io/install | bash
```
- **Best plan:** ~$10.50/mo 1GB → ~4.2GB
- Custom CPU/RAM/SSD sizing. Pay-per-use. Swiss-based.

### 🟦 InterServer
```bash
ssh root@your-ip
curl -sL ramup.io/install | bash
```
- **Best plan:** $6/mo 1GB → ~4.2GB
- Price lock guarantee — rate never increases. SSD storage.

### 🟢 RackNerd
```bash
ssh root@your-ip
curl -sL ramup.io/install | bash
```
- **Best plan:** $10.98/year 1GB → ~4.2GB!
- Insanely cheap yearly plans. Great for hobby projects.

### 🟪 A2 Hosting
```bash
ssh root@your-ip
curl -sL ramup.io/install | bash
```
- **Best plan:** $6.99/mo 1GB → ~4.2GB
- Turbo servers with NVMe. "Anytime" money-back guarantee.

### 🟩 DreamHost
```bash
ssh root@your-ip
curl -sL ramup.io/install | bash
```
- **Best plan:** $10/mo 1GB → ~4.2GB
- Managed VPS. SSD storage. Unlimited bandwidth.

### PaaS Providers (Docker-based)

For PaaS providers without SSH access, build RAMUP into your Docker image:

```dockerfile
FROM ubuntu:22.04
RUN curl -sL ramup.io/install | bash
COPY . /app
CMD ["./start.sh"]
```

Works with: **Render**, **Railway**, **Fly.io**, **Koyeb**, **Heroku**, **DigitalOcean App Platform**, **Google Cloud Run**, **AWS App Runner**, **Azure Container Instances**, **Modal**.

### Free Tier Cheat Sheet

| Provider | Free Offering | RAM | With RAMUP |
|----------|--------------|-----|-----------|
| Oracle Cloud | Always Free | 24GB ARM / 1GB AMD | 24GB / ~4.2GB |
| AWS | 12 months | 1GB (t2.micro) | ~4.2GB |
| GCP | Forever | 1GB (e2-micro) | ~4.2GB |
| Azure | 12 months | 1GB (B1s) | ~4.2GB |
| Vultr | $250 credit / 30 days | Any | Any |
| Hetzner | €20 credit | Any | Any |

---

## 🎯 How It Works

### 1. 🗜️ ZRAM Engine
Creates a compressed block device **inside your RAM**. Data gets compressed at ~2.5:1 ratio.

### 2. 💾 Smart Swap
SSD-aware disk swap as overflow. Auto-detects SSD vs HDD. NVMe swap is fast enough for most workloads.

### 3. 🔧 Kernel Tuning
Optimizes `vm.swappiness`, `vm.vfs_cache_pressure`, `vm.overcommit_memory`, and dirty ratios.

### 4. 🤖 Auto-Adjust Daemon
Systemd daemon monitors memory pressure in real-time: Low → Medium → High → Critical.

---

## 📊 Smart Sizing

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

> ⚠️ "Effective" includes ZRAM + swap. ZRAM ≈ real RAM; swap on disk is slower.

---

## 🛠️ Commands

### Core
```bash
ramup install          # Install and activate
ramup uninstall        # Remove and restore
ramup status           # Memory status card
ramup monitor          # Live dashboard
ramup on / off         # Enable / disable
```

### Optimization
```bash
ramup tune             # Auto-tune for workload
ramup optimize         # Deep optimization
ramup profile <name>   # Profile by process
ramup fix              # Auto-fix issues
ramup boost            # Instant boost
```

### Intelligence
```bash
ramup analyze          # Memory analysis
ramup predict          # Exhaustion forecast
ramup watch <process>  # Leak detection
ramup top              # Interactive viewer
```

### Docker
```bash
ramup docker-opt       # Optimize Docker
ramup docker-limit     # Container limits
ramup docker-stats     # Container stats
```

### System
```bash
ramup health           # 8-point check
ramup benchmark        # Performance test
ramup sysinfo          # System info
ramup services         # Services by memory
```

### Safety
```bash
ramup backup           # Create backup
ramup restore          # Restore backup
ramup rollback         # Undo changes
ramup logs             # Activity logs
```

### Options
| Flag | Description |
|------|-------------|
| `--force` | Skip confirmations |
| `--quiet` | Minimal output |
| `--verbose` | Extra logging |
| `--dry-run` | Preview changes |
| `--aggressive` | Max performance |
| `--safe` | Conservative mode |
| `--json` | JSON output |

---

## 🐧 Compatibility

| Category | Support |
|----------|---------|
| **Distros** | Ubuntu, Debian, CentOS, RHEL, Fedora, Arch, Alpine |
| **Kernels** | Linux 3.14+ |
| **Virtualization** | KVM, OpenVZ, VMware, Hyper-V, Xen, bare-metal |
| **Storage** | SSD, NVMe, HDD |
| **Architectures** | x86_64, ARM (aarch64) |
| **RAM Range** | 256MB to 128GB+ |

---

## 🛡️ Safety

1. **📸 Backup First** — Full backup before changes
2. **🧱 Proven Tech** — Standard Linux features only
3. **⏪ One-Command Rollback** — `ramup off` or `ramup restore`
4. **🛡️ Safe OOM** — Never kills apps unexpectedly
5. **📝 Full Logging** — Every action logged
6. **🔄 Upgrade-Safe** — Clean upgrades over existing installs

---

## ⚠️ Important Notes

- **"Effective" RAM ≠ "Real" RAM** — ZRAM ≈ real RAM; swap on disk is slower
- **Swap on HDD is slow** — Use SSD/NVMe for swap
- **Overcommit risks** — `vm.overcommit_memory=1` may trigger OOM killer
- **Not a replacement for real RAM** — Helps survive spikes, not sustained pressure

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  <strong>🟢 RAMUP</strong> — More RAM. Zero Cost. No Bullshit.
  <br><br>
  <a href="https://atum246.github.io/ramup/">Website</a> · <a href="https://github.com/Atum246/ramup">GitHub</a> · <a href="https://github.com/Atum246/ramup/issues">Issues</a>
</p>
