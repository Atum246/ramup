#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# ramup/lib/zram.sh — ZRAM Engine
# ═══════════════════════════════════════════════════════════

ZRAM_DEVICE="/dev/zram0"
ZRAM_SIZE_MB=0
ZRAM_ALGORITHM=""
ZRAM_ACTIVE=0

# ─── Setup ZRAM ───────────────────────────────────────────
setup_zram() {
    log INFO "Setting up ZRAM engine..."
    
    # Check if ZRAM is already active from ramup
    if is_zram_active; then
        log INFO "ZRAM already active, reconfiguring..."
        disable_zram
    fi
    
    # Check for existing system ZRAM (like zram-generator)
    disable_system_zram
    
    # Calculate optimal size
    ZRAM_SIZE_MB=$(calculate_optimal_zram "$TOTAL_RAM_MB" "$CPU_CORES")
    ZRAM_ALGORITHM=$(get_best_algorithm)
    
    log INFO "ZRAM config: ${ZRAM_SIZE_MB}MB, algorithm: ${ZRAM_ALGORITHM}"
    
    # Load zram module
    if ! [[ -b /dev/zram0 ]]; then
        modprobe zram 2>/dev/null || {
            log WARN "Cannot load ZRAM kernel module"
            log INFO "Attempting alternative ZRAM setup..."
            setup_zram_alternative
            return $?
        }
    fi
    
    # Wait for device
    local retries=10
    while [[ ! -b "$ZRAM_DEVICE" ]] && [[ $retries -gt 0 ]]; do
        sleep 0.5
        retries=$((retries - 1))
    done
    
    if [[ ! -b "$ZRAM_DEVICE" ]]; then
        log WARN "ZRAM device not available, trying alternative..."
        setup_zram_alternative
        return $?
    fi
    
    # Set compression algorithm
    echo "$ZRAM_ALGORITHM" > /sys/block/zram0/comp_algorithm 2>/dev/null || {
        log WARN "Algorithm ${ZRAM_ALGORITHM} not available, using default"
        ZRAM_ALGORITHM=$(cat /sys/block/zram0/comp_algorithm 2>/dev/null || echo "lzo")
    }
    
    # Set number of compression streams (match CPU cores for parallelism)
    local streams=$((CPU_CORES > 4 ? 4 : CPU_CORES))
    echo "$streams" > /sys/block/zram0/max_comp_streams 2>/dev/null || true
    
    # Set disk size
    local disk_bytes=$((ZRAM_SIZE_MB * 1024 * 1024))
    echo "$disk_bytes" > /sys/block/zram0/disksize 2>/dev/null || {
        log ERROR "Failed to set ZRAM disk size"
        return 1
    }
    
    # Set memory limit (optional, prevents ZRAM from using more than intended)
    local mem_limit=$((disk_bytes / 2))  # Compressed should be ~half
    echo "$mem_limit" > /sys/block/zram0/mem_limit 2>/dev/null || true
    
    # Create swap on ZRAM
    mkswap "$ZRAM_DEVICE" >/dev/null 2>&1 || {
        log ERROR "Failed to create swap on ZRAM"
        return 1
    }
    
    # Activate with high priority (prefer ZRAM over disk swap)
    swapon -p 100 "$ZRAM_DEVICE" 2>/dev/null || {
        log ERROR "Failed to activate ZRAM swap"
        return 1
    }
    
    ZRAM_ACTIVE=1
    
    # Save config
    save_zram_config
    
    log INFO "ZRAM engine active: ${ZRAM_SIZE_MB}MB (${ZRAM_ALGORITHM}) ✅"
}

# ─── Alternative ZRAM Setup ───────────────────────────────
setup_zram_alternative() {
    # Try using zramctl if available
    if command -v zramctl &>/dev/null; then
        log INFO "Using zramctl for ZRAM setup..."
        zramctl --find --size "${ZRAM_SIZE_MB}M" --algorithm "$ZRAM_ALGORITHM" 2>/dev/null || {
            log WARN "zramctl failed"
        }
        
        local zram_dev
        zram_dev=$(zramctl --output-all 2>/dev/null | tail -1 | awk '{print $1}')
        if [[ -n "$zram_dev" ]]; then
            mkswap "$zram_dev" >/dev/null 2>&1
            swapon -p 100 "$zram_dev" 2>/dev/null
            ZRAM_ACTIVE=1
            save_zram_config
            log INFO "ZRAM active via zramctl: ${ZRAM_SIZE_MB}MB ✅"
            return 0
        fi
    fi
    
    log WARN "ZRAM not available on this system"
    log INFO "Swap file will be used instead for memory extension"
    return 0
}

# ─── Disable ZRAM ─────────────────────────────────────────
disable_zram() {
    log INFO "Disabling ZRAM..."
    
    # Swap off all ZRAM devices
    for zram_dev in /sys/block/zram*; do
        if [[ -d "$zram_dev" ]]; then
            local dev_name
            dev_name=$(basename "$zram_dev")
            swapoff "/dev/${dev_name}" 2>/dev/null || true
            echo 1 > "${zram_dev}/reset" 2>/dev/null || true
        fi
    done
    
    # Remove module if possible
    modprobe -r zram 2>/dev/null || true
    
    ZRAM_ACTIVE=0
    log INFO "ZRAM disabled"
}

# ─── Disable System ZRAM ─────────────────────────────────
disable_system_zram() {
    # Disable systemd zram-generator if present
    if systemctl is-active --quiet systemd-zram-setup@zram0 2>/dev/null; then
        log INFO "Disabling system ZRAM service..."
        systemctl stop systemd-zram-setup@zram0 2>/dev/null || true
        systemctl disable systemd-zram-setup@zram0 2>/dev/null || true
    fi
    
    # Disable zramswap service
    if systemctl is-active --quiet zramswap 2>/dev/null; then
        log INFO "Disabling zramswap service..."
        systemctl stop zramswap 2>/dev/null || true
        systemctl disable zramswap 2>/dev/null || true
    fi
    
    # Disable any existing zram swap
    for zram_dev in /sys/block/zram*; do
        if [[ -d "$zram_dev" ]]; then
            local dev_name
            dev_name=$(basename "$zram_dev")
            local swap_active
            swap_active=$(swapon --show=NAME --noheadings 2>/dev/null | grep "/dev/${dev_name}" || true)
            if [[ -n "$swap_active" ]]; then
                log INFO "Disabling existing ZRAM swap: /dev/${dev_name}"
                swapoff "/dev/${dev_name}" 2>/dev/null || true
                echo 1 > "${zram_dev}/reset" 2>/dev/null || true
            fi
        fi
    done
}

# ─── Check ZRAM Status ───────────────────────────────────
is_zram_active() {
    # Check if our ZRAM swap is active
    swapon --show --noheadings 2>/dev/null | grep -q "zram"
}

# ─── ZRAM Config ──────────────────────────────────────────
save_zram_config() {
    cat >> "$RAMUP_CONFIG" << EOF
# ZRAM Configuration
ZRAM_ENABLED=1
ZRAM_SIZE_MB=${ZRAM_SIZE_MB}
ZRAM_ALGORITHM=${ZRAM_ALGORITHM}
ZRAM_DEVICE=${ZRAM_DEVICE}
ZRAM_PRIORITY=100
EOF
}

# ─── Get ZRAM Stats ───────────────────────────────────────
get_zram_stats() {
    if [[ ! -d /sys/block/zram0 ]]; then
        echo "ZRAM: not available"
        return
    fi
    
    local disksize orig_data compr_data same_pages pages_compacted
    disksize=$(cat /sys/block/zram0/disksize 2>/dev/null || echo "0")
    read -r orig_data compr_data _ _ _ _ same_pages pages_compacted _ < /sys/block/zram0/mm_stat 2>/dev/null || true
    
    local disksize_mb=$((disksize / 1024 / 1024))
    local orig_mb=$((orig_data / 1024 / 1024))
    local compr_mb=$((compr_data / 1024 / 1024))
    
    local ratio="0"
    if [[ "$compr_data" -gt 0 ]]; then
        ratio=$(echo "scale=1; ${orig_data} / ${compr_data}" | bc 2>/dev/null || echo "0")
    fi
    
    echo "ZRAM: ${disksize_mb}MB allocated, ${orig_mb}MB data, ${compr_mb}MB compressed, ratio ${ratio}:1"
}
