#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# 🟢 RAMUP Installer v2.0
# "More RAM. Zero Cost. No Bullshit."
# ═══════════════════════════════════════════════════════════════════════════════
# Usage: curl -sL ramup.io/install | bash
# Or:    sudo bash install.sh
# ═══════════════════════════════════════════════════════════════════════════════

set -uo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

RAMUP_DIR="/opt/ramup"
RAMUP_VERSION="2.0.0"

# ─── Logo ─────────────────────────────────────────────────────────────────────
echo -e "${GREEN}${BOLD}"
cat << 'LOGO'

    ╔═══════════════════════════════════════════════════════════════╗
    ║                                                               ║
    ║     ██████╗  █████╗ ███╗   ███╗██╗   ██╗██████╗              ║
    ║     ██╔══██╗██╔══██╗████╗ ████║██║   ██║██╔══██╗             ║
    ║     ██████╔╝███████║██╔████╔██║██║   ██║██████╔╝             ║
    ║     ██╔══██╗██╔══██║██║╚██╔╝██║██║   ██║██╔═══╝              ║
    ║     ██║  ██║██║  ██║██║ ╚═╝ ██║╚██████╔╝██║                  ║
    ║     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝                  ║
    ║                                                               ║
    ║          "More RAM. Zero Cost. No Bullshit."                 ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝

LOGO
echo -e "${NC}"

echo -e "${DIM}Advanced VPS Memory Extension Engine v${RAMUP_VERSION}${NC}"
echo -e "${DIM}Works with ANY RAM size. Any distro. Any VPS.${NC}"
echo ""

# ─── Root Check ───────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[✗] This installer requires root privileges${NC}"
    echo -e "${YELLOW}Try: sudo bash install.sh${NC}"
    exit 1
fi

# ─── System Detection ─────────────────────────────────────────────────────────
echo -e "${CYAN}[·]${NC} Detecting system..."

if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_VERSION="${VERSION_ID:-0}"
    OS_NAME="${PRETTY_NAME:-${OS_ID} ${OS_VERSION}}"
else
    OS_ID="unknown"
    OS_VERSION="0"
    OS_NAME="Unknown Linux"
fi

KERNEL=$(uname -r)
RAM_MB=$(awk '/MemTotal/ {printf "%.0f", $2/1024}' /proc/meminfo)
CORES=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)
ARCH=$(uname -m)
VIRT=$(systemd-detect-virt 2>/dev/null || echo "unknown")

# Smart sizing info
if [[ "$RAM_MB" -le 512 ]]; then
    RAM_TIER="ultra-low"
    ZRAM_EXPECTED=$((RAM_MB * 150 / 100))
    SWAP_EXPECTED=$((RAM_MB * 3))
elif [[ "$RAM_MB" -le 1024 ]]; then
    RAM_TIER="low"
    ZRAM_EXPECTED=$((RAM_MB * 125 / 100))
    SWAP_EXPECTED=$((RAM_MB * 2))
elif [[ "$RAM_MB" -le 2048 ]]; then
    RAM_TIER="moderate"
    ZRAM_EXPECTED=$RAM_MB
    SWAP_EXPECTED=$((RAM_MB * 3 / 2))
elif [[ "$RAM_MB" -le 4096 ]]; then
    RAM_TIER="standard"
    ZRAM_EXPECTED=$((RAM_MB * 3 / 4))
    SWAP_EXPECTED=$RAM_MB
elif [[ "$RAM_MB" -le 8192 ]]; then
    RAM_TIER="good"
    ZRAM_EXPECTED=$((RAM_MB / 2))
    SWAP_EXPECTED=$((RAM_MB * 3 / 4))
elif [[ "$RAM_MB" -le 16384 ]]; then
    RAM_TIER="high"
    ZRAM_EXPECTED=$((RAM_MB * 35 / 100))
    SWAP_EXPECTED=$((RAM_MB / 2))
elif [[ "$RAM_MB" -le 32768 ]]; then
    RAM_TIER="very-high"
    ZRAM_EXPECTED=$((RAM_MB / 4))
    SWAP_EXPECTED=$((RAM_MB * 35 / 100))
else
    RAM_TIER="enterprise"
    ZRAM_EXPECTED=$((RAM_MB * 15 / 100))
    SWAP_EXPECTED=$((RAM_MB / 4))
fi

[[ "$SWAP_EXPECTED" -gt 32768 ]] && SWAP_EXPECTED=32768
[[ "$ZRAM_EXPECTED" -lt 256 ]] && ZRAM_EXPECTED=256

EFFECTIVE=$((RAM_MB + ZRAM_EXPECTED + SWAP_EXPECTED))

echo -e "${GREEN}[✓]${NC} System: ${OS_NAME}"
echo -e "${GREEN}[✓]${NC} Kernel: ${KERNEL} | Arch: ${ARCH} | Virt: ${VIRT}"
echo -e "${GREEN}[✓]${NC} RAM: ${RAM_MB}MB (${RAM_TIER}) | CPU: ${CORES} cores"
echo ""

echo -e "${CYAN}${BOLD}  Expected improvement:${NC}"
echo -e "  ${DIM}├─${NC} Physical RAM:   ${WHITE}${RAM_MB}MB${NC}"
echo -e "  ${DIM}├─${NC} ZRAM addition:  ${GREEN}+${ZRAM_EXPECTED}MB${NC}"
echo -e "  ${DIM}├─${NC} Swap addition:  ${GREEN}+${SWAP_EXPECTED}MB${NC}"
echo -e "  ${DIM}└─${NC} Effective RAM:  ${GREEN}${BOLD}~${EFFECTIVE}MB${NC} 🚀"
echo ""

# ─── Pre-flight Checks ───────────────────────────────────────────────────────
echo -e "${CYAN}[·]${NC} Running pre-flight checks..."

# Kernel version check (need 3.14+ for ZRAM)
KERNEL_MAJOR=$(echo "$KERNEL" | cut -d. -f1)
KERNEL_MINOR=$(echo "$KERNEL" | cut -d. -f2)
if [[ "$KERNEL_MAJOR" -lt 3 ]] || [[ "$KERNEL_MAJOR" -eq 3 && "$KERNEL_MINOR" -lt 14 ]]; then
    echo -e "${RED}[✗] Kernel ${KERNEL} is too old. Need 3.14+ for ZRAM.${NC}"
    exit 1
fi
echo -e "${GREEN}[✓]${NC} Kernel version OK"

# ZRAM support
if [[ -d /sys/class/block/zram0 ]] || modprobe zram 2>/dev/null; then
    echo -e "${GREEN}[✓]${NC} ZRAM supported"
else
    echo -e "${YELLOW}[!]${NC} ZRAM may not be available (will try anyway)"
fi

# Disk space
DISK_FREE=$(df -m / | awk 'NR==2 {print $4}')
if [[ "$DISK_FREE" -lt 512 ]]; then
    echo -e "${RED}[✗] Not enough disk space (${DISK_FREE}MB free, need 512MB+)${NC}"
    exit 1
fi
echo -e "${GREEN}[✓]${NC} Disk space OK (${DISK_FREE}MB free)"

# Check for existing installation
if [[ -d "$RAMUP_DIR" ]]; then
    echo -e "${YELLOW}[!]${NC} Existing ramup installation found — will upgrade"
    BACKUP_DIR="${RAMUP_DIR}.bak.$(date +%Y%m%d_%H%M%S)"
    cp -a "$RAMUP_DIR" "$BACKUP_DIR" 2>/dev/null || true
    systemctl stop ramup-adjust.service 2>/dev/null || true
    systemctl disable ramup-adjust.service 2>/dev/null || true
fi

# ─── Install Dependencies ─────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}[·]${NC} Checking dependencies..."

install_pkg() {
    local pkg="$1"
    if command -v "$pkg" &>/dev/null; then
        return 0
    fi
    
    echo -e "${DIM}  Installing ${pkg}...${NC}"
    
    if command -v apt-get &>/dev/null; then
        apt-get install -y "$pkg" >/dev/null 2>&1
    elif command -v dnf &>/dev/null; then
        dnf install -y "$pkg" >/dev/null 2>&1
    elif command -v yum &>/dev/null; then
        yum install -y "$pkg" >/dev/null 2>&1
    elif command -v pacman &>/dev/null; then
        pacman -S --noconfirm "$pkg" >/dev/null 2>&1
    elif command -v apk &>/dev/null; then
        apk add "$pkg" >/dev/null 2>&1
    fi
}

for cmd in bc awk sed grep; do
    if command -v "$cmd" &>/dev/null; then
        echo -e "${GREEN}[✓]${NC} ${cmd}"
    else
        install_pkg "$cmd" || true
    fi
done

for cmd in zstd lz4; do
    if command -v "$cmd" &>/dev/null; then
        echo -e "${GREEN}[✓]${NC} ${cmd} (compression)"
    else
        install_pkg "$cmd" 2>/dev/null || true
    fi
done

# ─── Install ramup ────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}[·]${NC} Installing ramup to ${RAMUP_DIR}..."

mkdir -p "${RAMUP_DIR}"/{lib,logs,backups,cache}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/ramup" ]]; then
    cp "${SCRIPT_DIR}/ramup" "${RAMUP_DIR}/ramup"
    cp "${SCRIPT_DIR}"/lib/*.sh "${RAMUP_DIR}/lib/" 2>/dev/null || true
else
    echo -e "${RED}[✗]${NC} Cannot find ramup files"
    echo -e "${DIM}Please run this script from the ramup directory${NC}"
    exit 1
fi

chmod +x "${RAMUP_DIR}/ramup"
ln -sfn "${RAMUP_DIR}/ramup" /usr/local/bin/ramup

echo -e "${GREEN}[✓]${NC} Files installed"

# ─── Initialize ───────────────────────────────────────────────────────────────
cat > "${RAMUP_DIR}/config.conf" << EOF
# ═══════════════════════════════════════════════════════════════
# 🟢 RAMUP Configuration
# Generated: $(date -Iseconds)
# System: ${RAM_MB}MB RAM, ${CORES} cores, ${OS_ID} ${OS_VERSION}
# ═══════════════════════════════════════════════════════════════

RAMUP_VERSION=${RAMUP_VERSION}
RAMUP_DIR=${RAMUP_DIR}
SYSTEM_RAM_MB=${RAM_MB}
SYSTEM_CORES=${CORES}
SYSTEM_DISTRO=${OS_ID}
RAM_TIER=${RAM_TIER}
EOF

echo -e "${GREEN}[✓]${NC} Configuration initialized"

# ─── Run Installation ─────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}[·]${NC} Running ramup install..."
echo ""

"${RAMUP_DIR}/ramup" install --force

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}"
echo "  ════════════════════════════════════════════════════════════════"
echo "                    🎉 Installation Complete! 🎉                "
echo "  ════════════════════════════════════════════════════════════════"
echo -e "${NC}"
echo ""
echo -e "  ${WHITE}Quick Start:${NC}"
echo -e "    ${CYAN}ramup status${NC}      Memory status card"
echo -e "    ${CYAN}ramup monitor${NC}     Live dashboard"
echo -e "    ${CYAN}ramup health${NC}      Health check"
echo -e "    ${CYAN}ramup tune${NC}        Auto-tune for workload"
echo -e "    ${CYAN}ramup boost${NC}       Instant memory boost"
echo -e "    ${CYAN}ramup help${NC}        All commands"
echo ""
echo -e "  ${DIM}Your VPS memory has been extended! 🚀${NC}"
echo ""
