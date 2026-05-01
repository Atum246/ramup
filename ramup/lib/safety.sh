#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# ramup/lib/safety.sh — Safety Net & Rollback
# ═══════════════════════════════════════════════════════════

# ─── Create Backup ────────────────────────────────────────
create_backup() {
    local backup_name="${1:-$(date +%Y%m%d_%H%M%S)}"
    local backup_dir="${RAMUP_BACKUP}/${backup_name}"
    
    mkdir -p "$backup_dir"
    
    # Backup sysctl values
    sysctl -a 2>/dev/null | grep "^vm\.\|^net\." > "${backup_dir}/sysctl.conf" || true
    
    # Backup fstab
    cp /etc/fstab "${backup_dir}/fstab.bak" 2>/dev/null || true
    
    # Backup current swap state
    swapon --show --noheadings > "${backup_dir}/swapon.txt" 2>/dev/null || true
    
    # Backup ZRAM state
    for zram_dev in /sys/block/zram*; do
        if [[ -d "$zram_dev" ]]; then
            local dev_name
            dev_name=$(basename "$zram_dev")
            mkdir -p "${backup_dir}/zram"
            cat "${zram_dev}/disksize" > "${backup_dir}/zram/${dev_name}_disksize" 2>/dev/null || true
            cat "${zram_dev}/comp_algorithm" > "${backup_dir}/zram/${dev_name}_algo" 2>/dev/null || true
        fi
    done
    
    # Create "latest" symlink
    ln -sfn "$backup_dir" "${RAMUP_BACKUP}/latest"
    
    log DEBUG "Backup created: ${backup_dir}"
}

# ─── Restore Backup ───────────────────────────────────────
restore_backup() {
    local backup_name="${1:-latest}"
    local backup_dir="${RAMUP_BACKUP}/${backup_name}"
    
    if [[ ! -d "$backup_dir" ]]; then
        log ERROR "Backup not found: ${backup_name}"
        return 1
    fi
    
    log INFO "Restoring from backup: ${backup_name}"
    
    # Restore fstab
    if [[ -f "${backup_dir}/fstab.bak" ]]; then
        cp "${backup_dir}/fstab.bak" /etc/fstab
        log DEBUG "fstab restored"
    fi
    
    log INFO "Backup restored"
}

# ─── Health Check ─────────────────────────────────────────
run_health_check() {
    echo -e "${CYAN}${BOLD}🏥 RAMUP Health Check${NC}"
    echo ""
    
    local issues=0
    local warnings=0
    
    # Check 1: ZRAM active
    if is_zram_active; then
        echo -e "  ${GREEN}✅${NC} ZRAM is active"
    else
        echo -e "  ${RED}❌${NC} ZRAM is not active"
        issues=$((issues + 1))
    fi
    
    # Check 2: Swap file
    if swapon --show --noheadings 2>/dev/null | grep -q "swapfile.ramup"; then
        echo -e "  ${GREEN}✅${NC} Swap file is active"
    else
        echo -e "  ${YELLOW}⚠️${NC} Swap file not found"
        warnings=$((warnings + 1))
    fi
    
    # Check 3: Kernel tuning
    local swappiness
    swappiness=$(sysctl -n vm.swappiness 2>/dev/null || echo "60")
    if [[ "$swappiness" -le 20 ]]; then
        echo -e "  ${GREEN}✅${NC} Swappiness optimized (${swappiness})"
    else
        echo -e "  ${YELLOW}⚠️${NC} Swappiness not optimized (${swappiness})"
        warnings=$((warnings + 1))
    fi
    
    # Check 4: Memory pressure
    local available_mb
    available_mb=$(get_available_ram_mb)
    local total_mb
    total_mb=$(get_total_ram_mb)
    local used_pct=0
    if [[ "$total_mb" -gt 0 ]]; then
        used_pct=$(( (total_mb - available_mb) * 100 / total_mb ))
    fi
    
    if [[ "$used_pct" -lt 70 ]]; then
        echo -e "  ${GREEN}✅${NC} Memory pressure OK (${used_pct}% used)"
    elif [[ "$used_pct" -lt 85 ]]; then
        echo -e "  ${YELLOW}⚠️${NC} Memory pressure moderate (${used_pct}% used)"
        warnings=$((warnings + 1))
    else
        echo -e "  ${RED}❌${NC} Memory pressure HIGH (${used_pct}% used)"
        issues=$((issues + 1))
    fi
    
    # Check 5: Compression ratio
    local ratio
    ratio=$(get_compression_ratio)
    if [[ "$ratio" != "0" ]]; then
        if (( $(echo "$ratio > 1.5" | bc -l 2>/dev/null || echo "0") )); then
            echo -e "  ${GREEN}✅${NC} Compression ratio good (${ratio}:1)"
        else
            echo -e "  ${YELLOW}⚠️${NC} Compression ratio low (${ratio}:1)"
            warnings=$((warnings + 1))
        fi
    fi
    
    # Check 6: OOM killer activity
    local oom_count
    oom_count=$(dmesg 2>/dev/null | grep -c "Out of memory" || echo "0")
    oom_count=$(echo "$oom_count" | tr -d '[:space:]')
    if [[ "$oom_count" -eq 0 ]]; then
        echo -e "  ${GREEN}✅${NC} No OOM kills detected"
    else
        echo -e "  ${RED}❌${NC} ${oom_count} OOM kills detected!"
        issues=$((issues + 1))
    fi
    
    # Check 7: Auto-adjust daemon
    if systemctl is-active --quiet ramup-adjust.service 2>/dev/null; then
        echo -e "  ${GREEN}✅${NC} Auto-adjust daemon running"
    else
        echo -e "  ${YELLOW}⚠️${NC} Auto-adjust daemon not running"
        warnings=$((warnings + 1))
    fi
    
    # Check 8: Disk space for swap
    local disk_free
    disk_free=$(df -m / | awk 'NR==2 {print $4}')
    if [[ "$disk_free" -gt 1024 ]]; then
        echo -e "  ${GREEN}✅${NC} Disk space OK (${disk_free}MB free)"
    elif [[ "$disk_free" -gt 512 ]]; then
        echo -e "  ${YELLOW}⚠️${NC} Disk space low (${disk_free}MB free)"
        warnings=$((warnings + 1))
    else
        echo -e "  ${RED}❌${NC} Disk space critical (${disk_free}MB free)"
        issues=$((issues + 1))
    fi
    
    echo ""
    echo "  ─────────────────────────────────────────────────────"
    
    if [[ "$issues" -eq 0 && "$warnings" -eq 0 ]]; then
        echo -e "  ${GREEN}${BOLD}All checks passed! System is healthy 🎉${NC}"
    elif [[ "$issues" -eq 0 ]]; then
        echo -e "  ${YELLOW}${BOLD}${warnings} warning(s) found. System is OK.${NC}"
    else
        echo -e "  ${RED}${BOLD}${issues} issue(s) and ${warnings} warning(s) found!${NC}"
        echo -e "  ${DIM}Run 'ramup install' to fix issues${NC}"
    fi
    echo ""
}
