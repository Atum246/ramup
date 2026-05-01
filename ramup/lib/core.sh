#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# ramup/lib/core.sh — Core System Detection & Utilities
# Works with ANY RAM size. Any distro. Any VPS.
# ═══════════════════════════════════════════════════════════════════════════════

# Ensure sbin paths are available
export PATH="/usr/sbin:/sbin:${PATH}"

# ─── System Detection ─────────────────────────────────────────────────────────
TOTAL_RAM_MB=0
CPU_CORES=0
DISTRO=""
DISTRO_VERSION=""
KERNEL_VERSION=""
HAS_SSD=0
HAS_ZRAM_SUPPORT=0
HAS_ZSTD=0
HAS_LZ4=0
VIRT_TYPE=""

detect_system() {
    # RAM
    TOTAL_RAM_MB=$(awk '/MemTotal/ {printf "%.0f", $2/1024}' /proc/meminfo)
    
    # CPU cores
    CPU_CORES=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)
    
    # Distro
    if [[ -f /etc/os-release ]]; then
        local os_id os_version os_name
        os_id=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
        os_version=$(grep "^VERSION_ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
        os_name=$(grep "^PRETTY_NAME=" /etc/os-release | cut -d= -f2 | tr -d '"')
        DISTRO="${os_id:-unknown}"
        DISTRO_VERSION="${os_version:-0}"
        DISTRO_NAME="${os_name:-${DISTRO} ${DISTRO_VERSION}}"
    fi
    
    # Kernel
    KERNEL_VERSION=$(uname -r)
    
    # Virtualization
    VIRT_TYPE=$(systemd-detect-virt 2>/dev/null || echo "unknown")
    
    # Storage
    detect_storage_type
    
    # ZRAM support
    if [[ -d /sys/class/block/zram0 ]] || [[ -f /proc/config.gz ]] || [[ -f /boot/config-"$(uname -r)" ]]; then
        HAS_ZRAM_SUPPORT=1
    fi
    
    # Compression algorithms
    if [[ -f /sys/block/zram0/comp_algorithm ]]; then
        HAS_ZSTD=1
        HAS_LZ4=1
    fi
    command -v zstd &>/dev/null && HAS_ZSTD=1
    command -v lz4 &>/dev/null && HAS_LZ4=1
    
    # Check kernel config
    local kconfig="/boot/config-${KERNEL_VERSION}"
    if [[ -f "$kconfig" ]]; then
        if grep -q "CONFIG_ZRAM=m\|CONFIG_ZRAM=y" "$kconfig" 2>/dev/null; then
            HAS_ZRAM_SUPPORT=1
        fi
    fi
    if [[ -f /proc/config.gz ]]; then
        if zcat /proc/config.gz 2>/dev/null | grep -q "CONFIG_ZRAM=m\|CONFIG_ZRAM=y"; then
            HAS_ZRAM_SUPPORT=1
        fi
    fi
    
    log DEBUG "System: ${DISTRO} ${DISTRO_VERSION}, ${TOTAL_RAM_MB}MB RAM, ${CPU_CORES} cores, Kernel ${KERNEL_VERSION}, Virt: ${VIRT_TYPE}"
}

detect_storage_type() {
    HAS_SSD=0
    
    local root_device
    root_device=$(findmnt -n -o SOURCE / 2>/dev/null | sed 's/[0-9]*$//' | sed 's|^/dev/||')
    
    if [[ -n "$root_device" ]]; then
        local rotational_file="/sys/block/${root_device}/rotational"
        if [[ -f "$rotational_file" ]]; then
            local rotational
            rotational=$(cat "$rotational_file")
            if [[ "$rotational" == "0" ]]; then
                HAS_SSD=1
            fi
        fi
    fi
    
    if lsblk -d -o ROTA 2>/dev/null | grep -q "0"; then
        HAS_SSD=1
    fi
    
    log DEBUG "Storage: SSD=${HAS_SSD}"
}

# ─── Memory Utilities ─────────────────────────────────────────────────────────
get_total_ram_mb() {
    echo "$TOTAL_RAM_MB"
}

get_free_ram_mb() {
    awk '/MemFree/ {printf "%.0f", $2/1024}' /proc/meminfo
}

get_available_ram_mb() {
    awk '/MemAvailable/ {printf "%.0f", $2/1024}' /proc/meminfo
}

get_used_ram_mb() {
    local total free
    total=$(get_total_ram_mb)
    free=$(get_available_ram_mb)
    echo $((total - free))
}

get_swap_total_mb() {
    awk '/SwapTotal/ {printf "%.0f", $2/1024}' /proc/meminfo
}

get_swap_used_mb() {
    local total free
    total=$(get_swap_total_mb)
    free=$(awk '/SwapFree/ {printf "%.0f", $2/1024}' /proc/meminfo)
    echo $((total - free))
}

get_swap_size_mb() {
    local total=0
    if [[ -f "/swapfile.ramup" ]]; then
        total=$(du -m /swapfile.ramup 2>/dev/null | awk '{print $1}' || echo "0")
    fi
    if [[ "$total" -eq 0 ]]; then
        total=$(get_swap_total_mb)
    fi
    echo "$total"
}

get_zram_size_mb() {
    local total=0
    for zram_dev in /sys/block/zram*; do
        if [[ -d "$zram_dev" ]]; then
            local size
            size=$(cat "${zram_dev}/disksize" 2>/dev/null || echo "0")
            total=$((total + size / 1024 / 1024))
        fi
    done
    echo "$total"
}

get_zram_used_mb() {
    local total=0
    for zram_dev in /sys/block/zram*; do
        if [[ -d "$zram_dev" ]]; then
            local orig_data
            orig_data=$(cat "${zram_dev}/mm_stat" 2>/dev/null | awk '{print $1}' || echo "0")
            if [[ "$orig_data" -gt 0 ]]; then
                total=$((total + orig_data / 1024 / 1024))
            fi
        fi
    done
    echo "$total"
}

get_compression_ratio() {
    local orig_total=0
    local compr_total=0
    
    for zram_dev in /sys/block/zram*; do
        if [[ -d "$zram_dev" ]]; then
            local orig compr
            orig=$(cat "${zram_dev}/mm_stat" 2>/dev/null | awk '{print $1}' || echo "0")
            compr=$(cat "${zram_dev}/mm_stat" 2>/dev/null | awk '{print $2}' || echo "0")
            orig_total=$((orig_total + orig))
            compr_total=$((compr_total + compr))
        fi
    done
    
    if [[ "$compr_total" -gt 0 ]]; then
        echo "scale=1; ${orig_total} / ${compr_total}" | bc 2>/dev/null || echo "2.0"
    else
        echo "0"
    fi
}

# ─── Smart Sizing — Works with ANY RAM ────────────────────────────────────────
calculate_optimal_swap() {
    local ram_mb=$1
    local swap_mb=0
    
    # Smart scaling based on RAM size
    if [[ "$ram_mb" -le 512 ]]; then
        # Ultra-low RAM (512MB or less): 3x RAM
        swap_mb=$((ram_mb * 3))
    elif [[ "$ram_mb" -le 1024 ]]; then
        # Low RAM (512MB-1GB): 2x RAM
        swap_mb=$((ram_mb * 2))
    elif [[ "$ram_mb" -le 2048 ]]; then
        # 1-2GB: 1.5x RAM
        swap_mb=$((ram_mb * 3 / 2))
    elif [[ "$ram_mb" -le 4096 ]]; then
        # 2-4GB: 1x RAM
        swap_mb=$ram_mb
    elif [[ "$ram_mb" -le 8192 ]]; then
        # 4-8GB: 0.75x RAM
        swap_mb=$((ram_mb * 3 / 4))
    elif [[ "$ram_mb" -le 16384 ]]; then
        # 8-16GB: 0.5x RAM
        swap_mb=$((ram_mb / 2))
    elif [[ "$ram_mb" -le 32768 ]]; then
        # 16-32GB: 0.35x RAM
        swap_mb=$((ram_mb * 35 / 100))
    elif [[ "$ram_mb" -le 65536 ]]; then
        # 32-64GB: 0.25x RAM
        swap_mb=$((ram_mb / 4))
    else
        # 64GB+: 0.15x RAM (capped at 32GB)
        swap_mb=$((ram_mb * 15 / 100))
    fi
    
    # Cap at 32GB
    [[ "$swap_mb" -gt 32768 ]] && swap_mb=32768
    
    # Minimum 256MB
    [[ "$swap_mb" -lt 256 ]] && swap_mb=256
    
    echo "$swap_mb"
}

calculate_optimal_zram() {
    local ram_mb=$1
    local cores=$2
    local zram_mb=0
    
    # Smart scaling based on RAM size
    if [[ "$ram_mb" -le 512 ]]; then
        # Ultra-low: 150% of RAM (aggressive)
        zram_mb=$((ram_mb * 150 / 100))
    elif [[ "$ram_mb" -le 1024 ]]; then
        # Low: 125% of RAM
        zram_mb=$((ram_mb * 125 / 100))
    elif [[ "$ram_mb" -le 2048 ]]; then
        # 1-2GB: 100% of RAM
        zram_mb=$ram_mb
    elif [[ "$ram_mb" -le 4096 ]]; then
        # 2-4GB: 75% of RAM
        zram_mb=$((ram_mb * 3 / 4))
    elif [[ "$ram_mb" -le 8192 ]]; then
        # 4-8GB: 50% of RAM
        zram_mb=$((ram_mb / 2))
    elif [[ "$ram_mb" -le 16384 ]]; then
        # 8-16GB: 35% of RAM
        zram_mb=$((ram_mb * 35 / 100))
    elif [[ "$ram_mb" -le 32768 ]]; then
        # 16-32GB: 25% of RAM
        zram_mb=$((ram_mb / 4))
    else
        # 32GB+: 15% of RAM
        zram_mb=$((ram_mb * 15 / 100))
    fi
    
    # Minimum 256MB for ZRAM
    [[ "$zram_mb" -lt 256 ]] && zram_mb=256
    
    echo "$zram_mb"
}

# ─── Best Compression Algorithm ───────────────────────────────────────────────
get_best_algorithm() {
    local available
    available=$(cat /sys/block/zram0/comp_algorithm 2>/dev/null || echo "")
    
    if [[ -z "$available" ]]; then
        echo "lzo"
        return
    fi
    
    # Preference: zstd (best ratio) > lz4 (fastest) > lzo-rle > lzo
    if echo "$available" | grep -q "zstd"; then
        echo "zstd"
    elif echo "$available" | grep -q "lz4"; then
        echo "lz4"
    elif echo "$available" | grep -q "lzo-rle"; then
        echo "lzo-rle"
    else
        echo "lzo"
    fi
}

# ─── Filesystem Type ──────────────────────────────────────────────────────────
get_root_fs_type() {
    findmnt -n -o FSTYPE / 2>/dev/null || echo "ext4"
}

# ─── Check Environment ────────────────────────────────────────────────────────
is_container() {
    [[ -f /.dockerenv ]] || [[ -f /run/.containerenv ]] || grep -q "docker\|lxc\|container" /proc/1/cgroup 2>/dev/null
}

is_vps() {
    local virt
    virt=$(systemd-detect-virt 2>/dev/null || echo "none")
    [[ "$virt" != "none" && "$virt" != "physical" ]]
}

is_low_memory() {
    [[ "$TOTAL_RAM_MB" -lt 2048 ]]
}

is_ultra_low_memory() {
    [[ "$TOTAL_RAM_MB" -lt 1024 ]]
}

# ─── Confirm Prompt ───────────────────────────────────────────────────────────
confirm() {
    local msg="${1:-Are you sure?}"
    
    if [[ "$FORCE" == "1" ]]; then
        return 0
    fi
    
    echo -en "${YELLOW}${msg} [y/N]${NC} "
    read -r response
    [[ "$response" =~ ^[Yy] ]]
}

# ─── Human Readable Sizes ─────────────────────────────────────────────────────
human_readable() {
    local mb=$1
    if [[ "$mb" -ge 1024 ]]; then
        echo "$(echo "scale=1; ${mb} / 1024" | bc 2>/dev/null || echo "${mb}")GB"
    else
        echo "${mb}MB"
    fi
}

# ─── Timestamp ────────────────────────────────────────────────────────────────
now() {
    date '+%Y-%m-%d %H:%M:%S'
}
