#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# ramup/lib/kernel.sh — Kernel Memory Optimization
# ═══════════════════════════════════════════════════════════

SYSCTL_RAMUP="/etc/sysctl.d/99-ramup.conf"
SYSCTL_BACKUP="/opt/ramup/backups/sysctl.backup"

# ─── Tune Kernel ──────────────────────────────────────────
tune_kernel() {
    log INFO "Optimizing kernel memory parameters..."
    
    # Backup current sysctl values
    backup_sysctl
    
    # Calculate optimal values based on system
    local swappiness vfs_cache_pressure min_free_kbytes overcommit_ratio
    
    # Swappiness: 10 for most systems (prefer RAM, swap when needed)
    swappiness=10
    
    # VFS cache pressure: 150 (reclaim inode/dentry cache more aggressively)
    vfs_cache_pressure=150
    
    # Min free kbytes: 1-2% of RAM, min 32MB, max 256MB
    min_free_kbytes=$((TOTAL_RAM_MB * 10 / 1000))
    [[ "$min_free_kbytes" -lt 32768 ]] && min_free_kbytes=32768
    [[ "$min_free_kbytes" -gt 262144 ]] && min_free_kbytes=262144
    
    # Overcommit ratio: 80% (allow some overcommit)
    overcommit_ratio=80
    
    # Dirty page tuning: flush sooner to reduce memory pressure
    local dirty_ratio=10
    local dirty_background_ratio=5
    local dirty_expire_centisecs=3000
    local dirty_writeback_centisecs=500
    
    # Write optimized sysctl config
    cat > "$SYSCTL_RAMUP" << EOF
# ═══════════════════════════════════════════════════════════
# 🟢 RAMUP — Kernel Memory Optimization
# Generated: $(date -Iseconds)
# System: ${TOTAL_RAM_MB}MB RAM, ${CPU_CORES} cores
# ═══════════════════════════════════════════════════════════

# ─── Swap Behavior ────────────────────────────────────────
# Prefer RAM over swap. Only swap when memory is really tight.
vm.swappiness = ${swappiness}

# ─── Memory Overcommit ────────────────────────────────────
# Mode 1: Always overcommit, don't check (let OOM handle it)
# This allows apps to allocate more than available, prevents malloc failures
vm.overcommit_memory = 1
vm.overcommit_ratio = ${overcommit_ratio}

# ─── Cache Pressure ───────────────────────────────────────
# Reclaim inode/dentry cache more aggressively to free RAM
vm.vfs_cache_pressure = ${vfs_cache_pressure}

# ─── Minimum Free Memory ──────────────────────────────────
# Keep this much RAM always free for emergency allocations
vm.min_free_kbytes = ${min_free_kbytes}

# ─── Dirty Pages ──────────────────────────────────────────
# Flush dirty pages to disk sooner = less memory pressure
vm.dirty_ratio = ${dirty_ratio}
vm.dirty_background_ratio = ${dirty_background_ratio}
vm.dirty_expire_centisecs = ${dirty_expire_centisecs}
vm.dirty_writeback_centisecs = ${dirty_writeback_centisecs}

# ─── OOM Behavior ─────────────────────────────────────────
# Panic on OOM (optional — prevents silent data corruption)
# vm.panic_on_oom = 0

# ─── Memory Compaction ────────────────────────────────────
# Enable proactive memory compaction
vm.compact_unevictable_allowed = 1

# ─── Huge Pages ───────────────────────────────────────────
# Transparent hugepages: always (helps with large allocations)
# Use 'madvise' if you see THP-related issues
vm.transparent_hugepages = always

# ─── Network Buffer Optimization ──────────────────────────
# Reduce network buffer memory usage
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_mem = 786432 1048576 1572864

# ─── Connection Tracking ──────────────────────────────────
# Reduce conntrack memory if not a router
# net.netfilter.nf_conntrack_max = 65536
EOF
    
    # Apply sysctl
    sysctl --system >/dev/null 2>&1 || {
        log WARN "Some sysctl values may not have applied"
    }
    
    # Save config
    save_kernel_config
    
    log INFO "Kernel optimization applied ✅"
}

# ─── Auto-Tune ────────────────────────────────────────────
auto_tune() {
    local mode="${1:-balanced}"
    
    detect_system
    
    # Detect current workload
    local workload
    workload=$(detect_workload)
    
    log INFO "Detected workload: ${workload}"
    
    case "$workload" in
        web-server)
            # Web servers: moderate swap, good cache
            sysctl -w vm.swappiness=10 >/dev/null 2>&1
            sysctl -w vm.vfs_cache_pressure=200 >/dev/null 2>&1
            log INFO "Tuned for: Web server workload"
            ;;
        database)
            # Databases: minimize swap, maximize RAM
            sysctl -w vm.swappiness=1 >/dev/null 2>&1
            sysctl -w vm.vfs_cache_pressure=50 >/dev/null 2>&1
            log INFO "Tuned for: Database workload"
            ;;
        docker)
            # Docker: balanced, good for containers
            sysctl -w vm.swappiness=10 >/dev/null 2>&1
            sysctl -w vm.vfs_cache_pressure=150 >/dev/null 2>&1
            log INFO "Tuned for: Docker/container workload"
            ;;
        general)
            # General: balanced defaults
            sysctl -w vm.swappiness=10 >/dev/null 2>&1
            sysctl -w vm.vfs_cache_pressure=150 >/dev/null 2>&1
            log INFO "Tuned for: General workload"
            ;;
    esac
    
    if [[ "$AGGRESSIVE" == "1" ]]; then
        # Aggressive mode: maximum memory recovery
        sysctl -w vm.swappiness=5 >/dev/null 2>&1
        sysctl -w vm.vfs_cache_pressure=300 >/dev/null 2>&1
        sysctl -w vm.min_free_kbytes=$((TOTAL_RAM_MB * 20 / 1000 * 1024)) >/dev/null 2>&1
        log INFO "Aggressive mode enabled — maximum memory recovery"
    fi
}

# ─── Detect Workload ──────────────────────────────────────
detect_workload() {
    # Check for web servers
    if pgrep -x "nginx\|apache2\|httpd\|caddy" >/dev/null 2>&1; then
        echo "web-server"
        return
    fi
    
    # Check for databases
    if pgrep -x "mysqld\|postgres\|mongod\|redis-server" >/dev/null 2>&1; then
        echo "database"
        return
    fi
    
    # Check for Docker
    if pgrep -x "dockerd\|containerd" >/dev/null 2>&1; then
        echo "docker"
        return
    fi
    
    echo "general"
}

# ─── Backup Sysctl ────────────────────────────────────────
backup_sysctl() {
    mkdir -p "$(dirname "$SYSCTL_BACKUP")"
    
    # Save current vm.* values
    sysctl -a 2>/dev/null | grep "^vm\." > "$SYSCTL_BACKUP" || true
    
    log DEBUG "Sysctl values backed up"
}

# ─── Restore Kernel ───────────────────────────────────────
restore_kernel() {
    log INFO "Restoring kernel defaults..."
    
    # Remove our sysctl config
    rm -f "$SYSCTL_RAMUP"
    
    # Restore backup if exists
    if [[ -f "$SYSCTL_BACKUP" ]]; then
        while IFS='=' read -r key value; do
            key=$(echo "$key" | tr -d ' ')
            value=$(echo "$value" | tr -d ' ')
            sysctl -w "${key}=${value}" >/dev/null 2>&1 || true
        done < "$SYSCTL_BACKUP"
        log INFO "Kernel parameters restored from backup"
    else
        # Reset to sensible defaults
        sysctl -w vm.swappiness=60 >/dev/null 2>&1 || true
        sysctl -w vm.vfs_cache_pressure=100 >/dev/null 2>&1 || true
        sysctl -w vm.overcommit_memory=0 >/dev/null 2>&1 || true
        sysctl -w vm.dirty_ratio=20 >/dev/null 2>&1 || true
        sysctl -w vm.dirty_background_ratio=10 >/dev/null 2>&1 || true
        log INFO "Kernel parameters reset to defaults"
    fi
    
    sysctl --system >/dev/null 2>&1 || true
}

# ─── Kernel Config ────────────────────────────────────────
save_kernel_config() {
    cat >> "$RAMUP_CONFIG" << EOF
# Kernel Tuning Configuration
KERNEL_TUNED=1
KERNEL_SWAPPINESS=10
KERNEL_VFS_CACHE_PRESSURE=150
KERNEL_OVERCOMMIT_MEMORY=1
KERNEL_OVERCOMMIT_RATIO=80
KERNEL_DIRTY_RATIO=10
KERNEL_DIRTY_BACKGROUND_RATIO=5
EOF
}
