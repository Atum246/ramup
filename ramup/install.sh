#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# 🟢 RAMUP Installer
# ═══════════════════════════════════════════════════════════
# Usage: curl -sL ramup.io/install | bash
# Or:    bash install.sh
# ═══════════════════════════════════════════════════════════

set -euo pipefail

# ─── Colors ───────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

RAMUP_DIR="/opt/ramup"
RAMUP_VERSION="1.0.0"
RAMUP_REPO="https://github.com/ramup/ramup"  # Update with actual repo

# ─── Banner ───────────────────────────────────────────────
echo -e "${GREEN}${BOLD}"
cat << 'EOF'
    ╔═══════════════════════════════════════╗
    ║         🟢  R A M U P  🟢           ║
    ║                                       ║
    ║    "Your 4GB just became 7GB"        ║
    ║                                       ║
    ╚═══════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${DIM}Advanced VPS memory extension tool v${RAMUP_VERSION}${NC}"
echo -e "${DIM}Safe. Simple. Powerful.${NC}"
echo ""

# ─── Root Check ───────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[✗] This installer requires root privileges${NC}"
    echo -e "${YELLOW}Try: sudo bash install.sh${NC}"
    exit 1
fi

# ─── OS Detection ─────────────────────────────────────────
echo -e "${CYAN}[·]${NC} Detecting system..."

if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_VERSION="${VERSION_ID:-0}"
else
    OS_ID="unknown"
    OS_VERSION="0"
fi

KERNEL=$(uname -r)
RAM_MB=$(awk '/MemTotal/ {printf "%.0f", $2/1024}' /proc/meminfo)
CORES=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)

echo -e "${GREEN}[✓]${NC} System: ${OS_ID} ${OS_VERSION} | Kernel: ${KERNEL}"
echo -e "${GREEN}[✓]${NC} RAM: ${RAM_MB}MB | CPU Cores: ${CORES}"

# ─── Pre-flight Checks ───────────────────────────────────
echo ""
echo -e "${CYAN}[·]${NC} Running pre-flight checks..."

# Check kernel version (need 3.14+ for ZRAM)
KERNEL_MAJOR=$(echo "$KERNEL" | cut -d. -f1)
KERNEL_MINOR=$(echo "$KERNEL" | cut -d. -f2)
if [[ "$KERNEL_MAJOR" -lt 3 ]] || [[ "$KERNEL_MAJOR" -eq 3 && "$KERNEL_MINOR" -lt 14 ]]; then
    echo -e "${RED}[✗] Kernel ${KERNEL} is too old. Need 3.14+ for ZRAM.${NC}"
    exit 1
fi
echo -e "${GREEN}[✓]${NC} Kernel version OK (${KERNEL})"

# Check for ZRAM support
if [[ -d /sys/class/block/zram0 ]] || modprobe zram 2>/dev/null; then
    echo -e "${GREEN}[✓]${NC} ZRAM supported"
else
    echo -e "${YELLOW}[!]${NC} ZRAM may not be available (will try anyway)"
fi

# Check disk space
DISK_FREE=$(df -m / | awk 'NR==2 {print $4}')
if [[ "$DISK_FREE" -lt 512 ]]; then
    echo -e "${RED}[✗] Not enough disk space (${DISK_FREE}MB free, need 512MB+)${NC}"
    exit 1
fi
echo -e "${GREEN}[✓]${NC} Disk space OK (${DISK_FREE}MB free)"

# ─── Backup Existing Installation ─────────────────────────
if [[ -d "$RAMUP_DIR" ]]; then
    echo ""
    echo -e "${YELLOW}[!]${NC} Existing ramup installation found"
    echo -e "${DIM}Creating backup before reinstall...${NC}"
    
    BACKUP_DIR="${RAMUP_DIR}.bak.$(date +%Y%m%d_%H%M%S)"
    cp -a "$RAMUP_DIR" "$BACKUP_DIR" 2>/dev/null || true
    echo -e "${GREEN}[✓]${NC} Backup created: ${BACKUP_DIR}"
    
    # Stop existing services
    systemctl stop ramup-adjust.service 2>/dev/null || true
    systemctl disable ramup-adjust.service 2>/dev/null || true
fi

# ─── Install Dependencies ─────────────────────────────────
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
    else
        echo -e "${YELLOW}[!]${NC} Cannot install ${pkg} - unknown package manager"
        return 1
    fi
}

# Required tools
for cmd in bc awk sed grep; do
    if command -v "$cmd" &>/dev/null; then
        echo -e "${GREEN}[✓]${NC} ${cmd} available"
    else
        echo -e "${YELLOW}[!]${NC} ${cmd} not found (installing...)"
        install_pkg "$cmd" || true
    fi
done

# Optional but recommended
for cmd in zstd lz4; do
    if command -v "$cmd" &>/dev/null; then
        echo -e "${GREEN}[✓]${NC} ${cmd} available"
    else
        install_pkg "$cmd" 2>/dev/null || true
    fi
done

# ─── Install ramup ────────────────────────────────────────
echo ""
echo -e "${CYAN}[·]${NC} Installing ramup to ${RAMUP_DIR}..."

# Create directory structure
mkdir -p "${RAMUP_DIR}"/{lib,logs,backups}

# Copy files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/ramup" ]]; then
    # Local install
    cp "${SCRIPT_DIR}/ramup" "${RAMUP_DIR}/ramup"
    cp "${SCRIPT_DIR}"/lib/*.sh "${RAMUP_DIR}/lib/"
else
    # Download from repo (placeholder — update with actual URL)
    echo -e "${RED}[✗]${NC} Cannot find ramup files"
    echo -e "${DIM}Please run this script from the ramup directory${NC}"
    exit 1
fi

# Make executable
chmod +x "${RAMUP_DIR}/ramup"

# Create symlink in PATH
ln -sfn "${RAMUP_DIR}/ramup" /usr/local/bin/ramup

echo -e "${GREEN}[✓]${NC} Files installed"

# ─── Initialize Config ────────────────────────────────────
echo -e "${CYAN}[·]${NC} Initializing configuration..."

cat > "${RAMUP_DIR}/config.conf" << EOF
# ═══════════════════════════════════════════════════════════
# 🟢 RAMUP Configuration
# Generated: $(date -Iseconds)
# System: ${RAM_MB}MB RAM, ${CORES} cores, ${OS_ID} ${OS_VERSION}
# ═══════════════════════════════════════════════════════════

# General
RAMUP_VERSION=${RAMUP_VERSION}
RAMUP_DIR=${RAMUP_DIR}

# Will be populated by ramup install
EOF

echo -e "${GREEN}[✓]${NC} Configuration initialized"

# ─── Run Installation ─────────────────────────────────────
echo ""
echo -e "${CYAN}[·]${NC} Running ramup install..."
echo ""

# Run the actual install
"${RAMUP_DIR}/ramup" install --force

# ─── Done ─────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}"
echo "  ════════════════════════════════════════════════════"
echo "            🎉 Installation Complete! 🎉             "
echo "  ════════════════════════════════════════════════════"
echo -e "${NC}"
echo ""
echo -e "  ${WHITE}Commands:${NC}"
echo -e "    ${CYAN}ramup status${NC}    — Check memory status"
echo -e "    ${CYAN}ramup monitor${NC}   — Live dashboard"
echo -e "    ${CYAN}ramup health${NC}    — System health check"
echo -e "    ${CYAN}ramup off${NC}       — Disable safely"
echo -e "    ${CYAN}ramup help${NC}      — All commands"
echo ""
echo -e "  ${DIM}Your VPS memory has been extended! 🚀${NC}"
echo ""
