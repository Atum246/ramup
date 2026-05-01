#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# ramup/lib/autoadjust.sh — Auto-Adjust Daemon
# ═══════════════════════════════════════════════════════════

ADJUST_PID_FILE="/var/run/ramup-adjust.pid"
ADJUST_INTERVAL=60  # Check every 60 seconds

# ─── Setup Auto-Adjust ────────────────────────────────────
setup_autoadjust() {
    log INFO "Setting up auto-adjust daemon..."
    
    # Create systemd service
    cat > /etc/systemd/system/ramup-adjust.service << EOF
[Unit]
Description=RAMUP Auto-Adjust Daemon
After=multi-user.target

[Service]
Type=simple
ExecStart=${RAMUP_DIR}/ramup adjust-daemon
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
    
    # Create the daemon command in main script
    create_adjust_daemon
    
    # Enable and start
    systemctl daemon-reload
    systemctl enable ramup-adjust.service 2>/dev/null || true
    systemctl start ramup-adjust.service 2>/dev/null || true
    
    log INFO "Auto-adjust daemon active ✅"
}

# ─── Create Daemon Script ─────────────────────────────────
create_adjust_daemon() {
    # Add daemon command to main ramup script if not present
    if ! grep -q "adjust-daemon" "${RAMUP_DIR}/ramup" 2>/dev/null; then
        cat >> "${RAMUP_DIR}/lib/adjust-daemon.sh" << 'DAEMON'
#!/usr/bin/env bash
# RAMUP Auto-Adjust Daemon
# Monitors memory and adjusts ZRAM/swap behavior in real-time

source /opt/ramup/lib/core.sh
source /opt/ramup/lib/zram.sh
source /opt/ramup/lib/kernel.sh

while true; do
    total=$(get_total_ram_mb)
    free=$(get_available_ram_mb)
    used=$((total - free))
    pct=$((used * 100 / total))
    
    if [[ $pct -gt 90 ]]; then
        # CRITICAL: Maximum compression
        sysctl -w vm.swappiness=5 >/dev/null 2>&1
        sysctl -w vm.vfs_cache_pressure=300 >/dev/null 2>&1
        # Drop caches
        sync
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
    elif [[ $pct -gt 75 ]]; then
        # HIGH: Aggressive swap
        sysctl -w vm.swappiness=20 >/dev/null 2>&1
        sysctl -w vm.vfs_cache_pressure=200 >/dev/null 2>&1
    elif [[ $pct -gt 50 ]]; then
        # MODERATE: Balanced
        sysctl -w vm.swappiness=10 >/dev/null 2>&1
        sysctl -w vm.vfs_cache_pressure=150 >/dev/null 2>&1
    else
        # LOW: Relaxed
        sysctl -w vm.swappiness=10 >/dev/null 2>&1
        sysctl -w vm.vfs_cache_pressure=100 >/dev/null 2>&1
    fi
    
    sleep 60
done
DAEMON
    fi
}

# ─── Stop Auto-Adjust ─────────────────────────────────────
stop_autoadjust() {
    log INFO "Stopping auto-adjust daemon..."
    
    systemctl stop ramup-adjust.service 2>/dev/null || true
    systemctl disable ramup-adjust.service 2>/dev/null || true
    rm -f /etc/systemd/system/ramup-adjust.service
    rm -f "${RAMUP_DIR}/lib/adjust-daemon.sh"
    
    systemctl daemon-reload 2>/dev/null || true
    
    log INFO "Auto-adjust daemon stopped"
}
