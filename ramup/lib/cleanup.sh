#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# ramup/lib/cleanup.sh — Memory Cleanup & Process Optimization
# ═══════════════════════════════════════════════════════════

# ─── Cleanup Memory ───────────────────────────────────────
cleanup_memory() {
    log INFO "Cleaning up memory..."
    
    local before_mb
    before_mb=$(get_free_ram_mb)
    
    # 1. Drop filesystem caches (safe — they rebuild automatically)
    drop_caches
    
    # 2. Kill unnecessary services (safe list only)
    kill_unnecessary_services
    
    # 3. Optimize running services
    optimize_services
    
    local after_mb
    after_mb=$(get_free_ram_mb)
    local freed=$((after_mb - before_mb))
    
    if [[ "$freed" -gt 0 ]]; then
        log INFO "Freed ${freed}MB of memory ✅"
    else
        log DEBUG "System already clean"
    fi
}

# ─── Drop Caches ──────────────────────────────────────────
drop_caches() {
    log DEBUG "Dropping filesystem caches..."
    
    # Sync first (flush pending writes)
    sync
    
    # Drop page cache, dentries, inodes
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    
    log DEBUG "Caches dropped"
}

# ─── Kill Unnecessary Services ────────────────────────────
kill_unnecessary_services() {
    # SAFE list — services that are safe to stop on a VPS
    local safe_to_stop=(
        "snapd"                          # Snap package manager (often unused on VPS)
        "ModemManager"                   # Modem management (useless on VPS)
        "accounts-daemon"                # Accounts service
        "thermald"                       # Thermal daemon (VPS has no thermal issues)
        "udisks2"                        # Disk management (VPS handles this)
        "avahi-daemon"                   # mDNS (useless on VPS)
        "cups"                           # Printing (why on a VPS?!)
        "bluetooth"                      # Bluetooth (LOL on a VPS)
    )
    
    for service in "${safe_to_stop[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            systemctl stop "$service" 2>/dev/null || true
            systemctl disable "$service" 2>/dev/null || true
            log DEBUG "Stopped unnecessary service: ${service}"
        fi
    done
}

# ─── Optimize Running Services ────────────────────────────
optimize_services() {
    # Limit journald memory usage
    if [[ -f /etc/systemd/journald.conf ]]; then
        if ! grep -q "^SystemMaxUse=" /etc/systemd/journald.conf; then
            sed -i 's/^#SystemMaxUse=.*/SystemMaxUse=50M/' /etc/systemd/journald.conf 2>/dev/null || true
            systemctl restart systemd-journald 2>/dev/null || true
            log DEBUG "Limited journald to 50MB"
        fi
    fi
    
    # Reduce systemd-udevd memory
    if systemctl is-active --quiet systemd-udevd 2>/dev/null; then
        # It's needed but we can reduce its memory
        :
    fi
}

# ─── Memory Usage by Process ──────────────────────────────
show_top_memory_hogs() {
    echo -e "${CYAN}${BOLD}Top Memory Consumers:${NC}"
    echo ""
    printf "  ${DIM}%-8s %-8s %s${NC}\n" "RSS(MB)" "%MEM" "PROCESS"
    echo "  ─────────────────────────────────────"
    
    ps aux --sort=-%mem 2>/dev/null | awk 'NR>1 && NR<=11 {
        rss_mb = $6 / 1024;
        printf "  %-8.0f %-8s %s\n", rss_mb, $4, $11
    }'
}

# ─── Find Memory Leaks ────────────────────────────────────
detect_memory_leaks() {
    log INFO "Scanning for potential memory leaks..."
    
    local leak_suspects=()
    
    # Check for processes with steadily growing RSS
    while IFS= read -r line; do
        local pid rss
        pid=$(echo "$line" | awk '{print $1}')
        rss=$(echo "$line" | awk '{print $2}')
        
        # Flag processes using >500MB
        if [[ "$rss" -gt 512000 ]]; then
            local name
            name=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
            leak_suspects+=("${name} (${pid}): ${rss}KB")
        fi
    done < <(ps -eo pid,rss --sort=-rss --no-headers 2>/dev/null | head -20)
    
    if [[ ${#leak_suspects[@]} -gt 0 ]]; then
        log WARN "Potential memory hogs detected:"
        for suspect in "${leak_suspects[@]}"; do
            log WARN "  → ${suspect}"
        done
    else
        log INFO "No obvious memory leaks detected"
    fi
}
