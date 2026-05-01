#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# ramup/lib/core.sh — Core system detection & utilities
# ═══════════════════════════════════════════════════════════

# ─── System Detection ─────────────────────────────────────
TOTAL_RAM_MB=0
CPU_CORES=0
DISTRO=""
DISTRO_VERSION=""
KERNEL_VERSION=""
HAS_SSD=0
HAS_ZRAM_SUPPORT=0
HAS_ZSTD=0
HAS_LZ4=0

detect_system() {
    # RAM
    TOTAL_RAM_MB=$(awk '/MemTotal/ {printf "%.0f", $2/1024}' /proc/meminfo)
    
    # CPU cores
    CPU_CORES=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)
    
    # Distro
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO="${ID:-unknown}"
        DISTRO_VERSION="${VERSION_ID:-0}"
    fi
    
    # Kernel
    KERNEL_VERSION=$(uname -r)
    
    # SSD detection
    detect_storage_type
    
    # ZRAM support
    if [[ -d /sys/class/block/zram0 ]] || [[ -f /proc/config.gz ]] || [[ -f /boot/config-"$(uname -r)" ]]; then
        HAS_ZRAM_SUPPORT=1
    fi
    
    # Compression algorithms
    [[ -f /sys/block/zram0/comp_algorithm ]] && HAS_ZSTD=1
    command -v zstd &>/dev/null && HAS_ZSTD=1
    command -v lz4 &>/dev/null && HAS_LZ4=1
    
    # Check kernel config for zram
    local kconfig="/boot/config-${KERNEL_VERSION}"
    if [[ -f "$kconfig" ]]; then
        if grep -q "CONFIG_ZRAM=m\|CONFIG_ZRAM=y" "$kconfig" 2>/dev/null; then
            HAS_ZRAM_SUPPORT=1
        fi
    fi
    
    # Also check /proc/config.gz
    if [[ -f /proc/config.gz ]]; then
        if zcat /proc/config.gz 2>/dev/null | grep -q "CONFIG_ZRAM=m\|CONFIG_ZRAM=y"; then
            HAS_ZRAM_SUPPORT=1
        fi
    fi
    
    log DEBUG "System: ${DISTRO} ${DISTRO_VERSION}, ${TOTAL_RAM_MB}MB RAM, ${CPU_CORES} cores, Kernel ${KERNEL_VERSION}"
}

detect_storage_type() {
    HAS_SSD=0
    
    # Check if root filesystem is on SSD
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
    
    # NVMe check
    if lsblk -d -o ROTA 2>/dev/null | grep -q "0"; then
        HAS_SSD=1
    fi
    
    log DEBUG "Storage: SSD=${HAS_SSD}"
}

# ─── Memory Utilities ─────────────────────────────────────
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
            local orig_data compr_data
            orig_data=$(cat "${zram_dev}/mm_stat" 2>/dev/null | awk '{print $1}' || echo "0")
            compr_data=$(cat "${zram_dev}/mm_stat" 2>/dev/null | awk '{print $2}' || echo "0")
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

# ─── Swap Size Calculator ─────────────────────────────────
calculate_optimal_swap() {
    local ram_mb=$1
    local swap_mb=0
    
    if [[ "$ram_mb" -le 1024 ]]; then
        # <= 1GB: 2x RAM
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
    else
        # 8GB+: 0.5x RAM
        swap_mb=$((ram_mb / 2))
    fi
    
    # Cap at 8GB
    [[ "$swap_mb" -gt 8192 ]] && swap_mb=8192
    
    echo "$swap_mb"
}

# ─── ZRAM Size Calculator ─────────────────────────────────
calculate_optimal_zram() {
    local ram_mb=$1
    local cores=$2
    local zram_mb=0
    
    # Use 50-100% of RAM depending on total RAM
    if [[ "$ram_mb" -le 2048 ]]; then
        # Low RAM: use 100% for ZRAM
        zram_mb=$ram_mb
    elif [[ "$ram_mb" -le 4096 ]]; then
        # 2-4GB: use 75%
        zram_mb=$((ram_mb * 3 / 4))
    elif [[ "$ram_mb" -le 8192 ]]; then
        # 4-8GB: use 50%
        zram_mb=$((ram_mb / 2))
    else
        # 8GB+: use 25%
        zram_mb=$((ram_mb / 4))
    fi
    
    echo "$zram_mb"
}

# ─── Best Compression Algorithm ───────────────────────────
get_best_algorithm() {
    # Preference: zstd > lz4 > lzo-rle > lzo
    local available
    available=$(cat /sys/block/zram0/comp_algorithm 2>/dev/null || echo "")
    
    if [[ -z "$available" ]]; then
        echo "lzo"
        return
    fi
    
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

# ─── Filesystem Type ──────────────────────────────────────
get_root_fs_type() {
    findmnt -n -o FSTYPE / 2>/dev/null || echo "ext4"
}

# ─── Check if running in container ────────────────────────
is_container() {
    [[ -f /.dockerenv ]] || [[ -f /run/.containerenv ]] || grep -q "docker\|lxc\|container" /proc/1/cgroup 2>/dev/null
}

# ─── Check if VPS ─────────────────────────────────────────
is_vps() {
    local virt
    virt=$(systemd-detect-virt 2>/dev/null || echo "none")
    [[ "$virt" != "none" && "$virt" != "physical" ]]
}

# ─── Confirm Prompt ───────────────────────────────────────
confirm() {
    local msg="${1:-Are you sure?}"
    
    if [[ "$FORCE" == "1" ]]; then
        return 0
    fi
    
    echo -en "${YELLOW}${msg} [y/N]${NC} "
    read -r response
    [[ "$response" =~ ^[Yy] ]]
}
