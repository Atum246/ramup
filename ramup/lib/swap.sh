#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# ramup/lib/swap.sh — Smart Swap Management
# ═══════════════════════════════════════════════════════════

SWAP_FILE="/swapfile.ramup"
SWAP_SIZE_MB=0
SWAP_ACTIVE=0

# ─── Setup Smart Swap ─────────────────────────────────────
setup_swap() {
    log INFO "Setting up smart swap..."
    
    # Check if swapon/mkswap are available
    if ! command -v swapon &>/dev/null || ! command -v mkswap &>/dev/null; then
        log WARN "swapon/mkswap not available — swap setup skipped"
        log INFO "Install kmod or util-linux package for swap support"
        return 0
    fi
    
    # Remove old ramup swap if exists
    remove_swap
    
    # Calculate optimal swap size
    SWAP_SIZE_MB=$(calculate_optimal_swap "$TOTAL_RAM_MB")
    
    # Reduce swap if SSD (less wear) but keep reasonable
    if [[ "$HAS_SSD" == "1" ]]; then
        log DEBUG "SSD detected — optimized swap for SSD lifespan"
    fi
    
    # Check available disk space
    local available_mb
    available_mb=$(df -m / | awk 'NR==2 {print $4}')
    
    if [[ "$available_mb" -lt "$((SWAP_SIZE_MB + 500))" ]]; then
        # Not enough space, use what we can (leave 500MB free)
        SWAP_SIZE_MB=$((available_mb - 500))
        log WARN "Limited disk space. Swap size reduced to ${SWAP_SIZE_MB}MB"
    fi
    
    if [[ "$SWAP_SIZE_MB" -lt 128 ]]; then
        log WARN "Not enough disk space for swap. Skipping."
        return 0
    fi
    
    log INFO "Creating ${SWAP_SIZE_MB}MB swap file..."
    
    # Create swap file
    local fs_type
    fs_type=$(get_root_fs_type)
    
    case "$fs_type" in
        ext4|xfs|btrfs)
            fallocate -l "${SWAP_SIZE_MB}M" "$SWAP_FILE" 2>/dev/null || {
                log DEBUG "fallocate failed, using dd..."
                dd if=/dev/zero of="$SWAP_FILE" bs=1M count="$SWAP_SIZE_MB" status=none 2>/dev/null
            }
            ;;
        *)
            dd if=/dev/zero of="$SWAP_FILE" bs=1M count="$SWAP_SIZE_MB" status=none 2>/dev/null
            ;;
    esac
    
    # Set permissions (critical for security)
    chmod 600 "$SWAP_FILE"
    
    # Format as swap
    mkswap "$SWAP_FILE" >/dev/null 2>&1 || {
        log ERROR "Failed to create swap on ${SWAP_FILE}"
        rm -f "$SWAP_FILE"
        return 1
    }
    
    # Activate with lower priority than ZRAM
    swapon -p 10 "$SWAP_FILE" 2>/dev/null || {
        log ERROR "Failed to activate swap file"
        rm -f "$SWAP_FILE"
        return 1
    }
    
    # Add to fstab for persistence (survives reboot)
    if ! grep -q "swapfile.ramup" /etc/fstab 2>/dev/null; then
        echo "${SWAP_FILE} none swap sw,pri=10 0 0" >> /etc/fstab
    fi
    
    SWAP_ACTIVE=1
    
    # Save config
    save_swap_config
    
    log INFO "Smart swap active: ${SWAP_SIZE_MB}MB ✅"
}

# ─── Remove Swap ──────────────────────────────────────────
remove_swap() {
    log INFO "Removing ramup swap..."
    
    # Deactivate swap
    swapoff "$SWAP_FILE" 2>/dev/null || true
    
    # Remove from fstab
    if [[ -f /etc/fstab ]]; then
        sed -i '/swapfile.ramup/d' /etc/fstab 2>/dev/null || true
    fi
    
    # Remove file
    rm -f "$SWAP_FILE"
    
    SWAP_ACTIVE=0
    log DEBUG "Swap removed"
}

# ─── Swap Config ──────────────────────────────────────────
save_swap_config() {
    cat >> "$RAMUP_CONFIG" << EOF
# Swap Configuration
SWAP_ENABLED=1
SWAP_SIZE_MB=${SWAP_SIZE_MB}
SWAP_FILE=${SWAP_FILE}
SWAP_PRIORITY=10
SWAP_SSD=${HAS_SSD}
EOF
}

# ─── Get Swap Stats ───────────────────────────────────────
get_swap_stats() {
    local total used
    total=$(get_swap_total_mb)
    used=$(get_swap_used_mb)
    echo "Swap: ${used}MB / ${total}MB used"
}
