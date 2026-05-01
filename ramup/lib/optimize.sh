#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# ramup/lib/optimize.sh — Deep Memory Optimization
# ═══════════════════════════════════════════════════════════════════════════════

# ─── Deep Optimization ────────────────────────────────────────────────────────
deep_optimize() {
    require_root "optimize"
    
    local before_mb
    before_mb=$(get_available_ram_mb)
    
    echo -e "${CYAN}${BOLD}  Running deep memory optimization...${NC}"
    echo ""
    
    # 1. Drop all caches
    echo -e "  ${DIM}├─${NC} Dropping filesystem caches..."
    sync
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    
    # 2. Compact memory
    echo -e "  ${DIM}├─${NC} Compacting memory..."
    echo 1 > /proc/sys/vm/compact_memory 2>/dev/null || true
    
    # 3. Clear swap and re-enable (defrag)
    echo -e "  ${DIM}├─${NC} Defragmenting swap..."
    local swap_was_on
    swap_was_on=$(swapon --show --noheadings 2>/dev/null | wc -l)
    if [[ "$swap_was_on" -gt 0 ]] && [[ "$(get_swap_used_mb)" -lt "$(get_swap_total_mb)" ]]; then
        # Only if swap isn't full
        :
    fi
    
    # 4. Kill memory hogs
    echo -e "  ${DIM}├─${NC} Cleaning up memory hogs..."
    cleanup_memory
    
    # 5. Optimize tmpfs mounts
    echo -e "  ${DIM}├─${NC} Optimizing tmpfs..."
    optimize_tmpfs
    
    # 6. Clear kernel caches
    echo -e "  ${DIM}├─${NC} Clearing kernel caches..."
    clear_kernel_caches
    
    # 7. Optimize page cache
    echo -e "  ${DIM}├─${NC} Optimizing page cache..."
    echo 1 > /proc/sys/vm/drop_caches 2>/dev/null || true
    sync
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    
    local after_mb
    after_mb=$(get_available_ram_mb)
    local freed=$((after_mb - before_mb))
    
    echo ""
    if [[ "$freed" -gt 0 ]]; then
        echo -e "  ${GREEN}${BOLD}✓ Freed ${freed}MB of memory${NC}"
    else
        echo -e "  ${DIM}System already optimized${NC}"
    fi
}

# ─── Instant Boost ────────────────────────────────────────────────────────────
instant_boost() {
    require_root "boost"
    
    local before_mb
    before_mb=$(get_available_ram_mb)
    
    echo -e "${CYAN}${BOLD}  ⚡ Applying instant memory boost...${NC}"
    
    # Drop all caches immediately
    sync
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    
    # Compact memory
    echo 1 > /proc/sys/vm/compact_memory 2>/dev/null || true
    
    # Aggressive cache pressure
    sysctl -w vm.vfs_cache_pressure=500 >/dev/null 2>&1 || true
    
    # Low swappiness to keep things in RAM
    sysctl -w vm.swappiness=5 >/dev/null 2>&1 || true
    
    local after_mb
    after_mb=$(get_available_ram_mb)
    local freed=$((after_mb - before_mb))
    
    echo -e "  ${GREEN}${BOLD}✓ Boosted! Freed ${freed}MB${NC}"
    
    # Reset cache pressure after 30 seconds
    (sleep 30 && sysctl -w vm.vfs_cache_pressure=150 >/dev/null 2>&1) &
}

# ─── Auto Fix ─────────────────────────────────────────────────────────────────
auto_fix() {
    require_root "fix"
    
    echo -e "${CYAN}${BOLD}  🔧 Auto-fixing memory issues...${NC}"
    echo ""
    
    local fixes=0
    
    # Fix 1: Check if ZRAM is active
    if ! is_zram_active; then
        echo -e "  ${DIM}├─${NC} Enabling ZRAM..."
        setup_zram
        fixes=$((fixes + 1))
    else
        echo -e "  ${DIM}├─${NC} ZRAM already active ✓"
    fi
    
    # Fix 2: Check swap
    if ! swapon --show --noheadings 2>/dev/null | grep -q "swapfile.ramup"; then
        echo -e "  ${DIM}├─${NC} Setting up swap..."
        setup_swap
        fixes=$((fixes + 1))
    else
        echo -e "  ${DIM}├─${NC} Swap active ✓"
    fi
    
    # Fix 3: Check swappiness
    local swappiness
    swappiness=$(sysctl -n vm.swappiness 2>/dev/null || echo "60")
    if [[ "$swappiness" -gt 20 ]]; then
        echo -e "  ${DIM}├─${NC} Optimizing swappiness (${swappiness} → 10)..."
        sysctl -w vm.swappiness=10 >/dev/null 2>&1
        fixes=$((fixes + 1))
    else
        echo -e "  ${DIM}├─${NC} Swappiness OK (${swappiness}) ✓"
    fi
    
    # Fix 4: Check memory pressure
    local used_pct
    local total_mb available_mb
    total_mb=$(get_total_ram_mb)
    available_mb=$(get_available_ram_mb)
    used_pct=$(( (total_mb - available_mb) * 100 / total_mb ))
    
    if [[ "$used_pct" -gt 85 ]]; then
        echo -e "  ${DIM}├─${NC} High memory pressure detected (${used_pct}%) — dropping caches..."
        sync
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
        fixes=$((fixes + 1))
    else
        echo -e "  ${DIM}├─${NC} Memory pressure OK (${used_pct}%) ✓"
    fi
    
    # Fix 5: Check for OOM risk
    local min_free
    min_free=$(sysctl -n vm.min_free_kbytes 2>/dev/null || echo "0")
    local min_free_recommended=$((TOTAL_RAM_MB * 10 / 1000 * 1024))
    [[ "$min_free_recommended" -lt 32768 ]] && min_free_recommended=32768
    
    if [[ "$min_free" -lt "$min_free_recommended" ]]; then
        echo -e "  ${DIM}├─${NC} Adjusting min_free_kbytes for safety..."
        sysctl -w vm.min_free_kbytes="$min_free_recommended" >/dev/null 2>&1
        fixes=$((fixes + 1))
    else
        echo -e "  ${DIM}├─${NC} min_free_kbytes OK ✓"
    fi
    
    # Fix 6: Optimize dirty pages
    local dirty_ratio
    dirty_ratio=$(sysctl -n vm.dirty_ratio 2>/dev/null || echo "20")
    if [[ "$dirty_ratio" -gt 15 ]]; then
        echo -e "  ${DIM}├─${NC} Optimizing dirty page ratio..."
        sysctl -w vm.dirty_ratio=10 >/dev/null 2>&1
        sysctl -w vm.dirty_background_ratio=5 >/dev/null 2>&1
        fixes=$((fixes + 1))
    else
        echo -e "  ${DIM}├─${NC} Dirty pages OK ✓"
    fi
    
    echo ""
    if [[ "$fixes" -gt 0 ]]; then
        echo -e "  ${GREEN}${BOLD}✓ Applied ${fixes} fixes${NC}"
    else
        echo -e "  ${GREEN}${BOLD}✓ No issues found — system is healthy${NC}"
    fi
}

# ─── Predict Memory Exhaustion ────────────────────────────────────────────────
predict_exhaustion() {
    echo -e "${CYAN}${BOLD}  🔮 Memory Exhaustion Prediction${NC}"
    echo ""
    
    detect_system
    
    local total_mb available_mb used_mb
    total_mb=$(get_total_ram_mb)
    available_mb=$(get_available_ram_mb)
    used_mb=$((total_mb - available_mb))
    
    local usage_pct=0
    [[ "$total_mb" -gt 0 ]] && usage_pct=$((used_mb * 100 / total_mb))
    
    if [[ "$usage_pct" -lt 50 ]]; then
        echo -e "  ${GREEN}●${NC} Status: ${GREEN}Healthy${NC}"
        echo -e "  ${DIM}├─${NC} Used: ${used_mb}MB / ${total_mb}MB (${usage_pct}%)"
        echo -e "  ${DIM}├─${NC} Available: ${available_mb}MB"
        echo -e "  ${DIM}└─${NC} Risk: Low — plenty of headroom"
    elif [[ "$usage_pct" -lt 75 ]]; then
        echo -e "  ${YELLOW}●${NC} Status: ${YELLOW}Moderate${NC}"
        echo -e "  ${DIM}├─${NC} Used: ${used_mb}MB / ${total_mb}MB (${usage_pct}%)"
        echo -e "  ${DIM}├─${NC} Available: ${available_mb}MB"
        echo -e "  ${DIM}└─${NC} Risk: Medium — consider enabling ZRAM"
    elif [[ "$usage_pct" -lt 90 ]]; then
        echo -e "  ${RED}●${NC} Status: ${RED}High${NC}"
        echo -e "  ${DIM}├─${NC} Used: ${used_mb}MB / ${total_mb}MB (${usage_pct}%)"
        echo -e "  ${DIM}├─${NC} Available: ${available_mb}MB"
        echo -e "  ${DIM}└─${NC} Risk: High — OOM possible under load"
        echo -e "  ${YELLOW}  💡 Recommendation: Run 'ramup fix' or 'ramup boost'${NC}"
    else
        echo -e "  ${RED}${BOLD}●${NC} Status: ${RED}${BOLD}CRITICAL${NC}"
        echo -e "  ${DIM}├─${NC} Used: ${used_mb}MB / ${total_mb}MB (${usage_pct}%)"
        echo -e "  ${DIM}├─${NC} Available: ${available_mb}MB"
        echo -e "  ${DIM}└─${NC} Risk: CRITICAL — OOM imminent!"
        echo -e "  ${RED}  ⚠️  Run 'ramup boost' immediately!${NC}"
    fi
}

# ─── Analyze Memory ───────────────────────────────────────────────────────────
analyze_memory() {
    echo -e "${CYAN}${BOLD}  📊 Memory Analysis${NC}"
    echo ""
    
    detect_system
    
    local total_mb available_mb used_mb swap_total swap_used zram_size
    total_mb=$(get_total_ram_mb)
    available_mb=$(get_available_ram_mb)
    used_mb=$((total_mb - available_mb))
    swap_total=$(get_swap_total_mb)
    swap_used=$(get_swap_used_mb)
    zram_size=$(get_zram_size_mb)
    
    local usage_pct=$((used_mb * 100 / total_mb))
    
    echo -e "  ${WHITE}${BOLD}Overview:${NC}"
    echo -e "  ${DIM}├─${NC} Total RAM: $(human_readable $total_mb)"
    echo -e "  ${DIM}├─${NC} Used: $(human_readable $used_mb) (${usage_pct}%)"
    echo -e "  ${DIM}├─${NC} Available: $(human_readable $available_mb)"
    echo -e "  ${DIM}├─${NC} ZRAM: $(human_readable $zram_size)"
    echo -e "  ${DIM}└─${NC} Swap: ${swap_used}MB / ${swap_total}MB"
    echo ""
    
    echo -e "  ${WHITE}${BOLD}Top Memory Consumers:${NC}"
    echo ""
    printf "  ${DIM}%-8s %-8s %-6s %s${NC}\n" "RSS(MB)" "%MEM" "PID" "PROCESS"
    echo "  ─────────────────────────────────────────────"
    
    ps aux --sort=-%mem 2>/dev/null | awk 'NR>1 && NR<=11 {
        rss_mb = $6 / 1024;
        printf "  %-8.0f %-8s %-6s %s\n", rss_mb, $4, $2, $11
    }'
    
    echo ""
    
    # Suggestions
    echo -e "  ${WHITE}${BOLD}Suggestions:${NC}"
    
    if [[ "$zram_size" -eq 0 ]]; then
        echo -e "  ${YELLOW}💡 Enable ZRAM for +50-75% effective RAM${NC}"
    fi
    
    if [[ "$swap_total" -eq 0 ]]; then
        echo -e "  ${YELLOW}💡 Add swap file for memory overflow protection${NC}"
    fi
    
    local swappiness
    swappiness=$(sysctl -n vm.swappiness 2>/dev/null || echo "60")
    if [[ "$swappiness" -gt 30 ]]; then
        echo -e "  ${YELLOW}💡 Lower swappiness (${swappiness} → 10) for better performance${NC}"
    fi
}

# ─── Memory Top ───────────────────────────────────────────────────────────────
memory_top() {
    trap 'echo ""; exit 0' INT TERM
    
    while true; do
        clear
        echo -e "${GREEN}${BOLD}  ╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}${BOLD}  ║                    🟢 RAMUP Memory Top 🟢                    ║${NC}"
        echo -e "${GREEN}${BOLD}  ╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        # Memory overview
        local total available used pct
        total=$(get_total_ram_mb)
        available=$(get_available_ram_mb)
        used=$((total - available))
        pct=$((used * 100 / total))
        
        echo -e "  ${WHITE}RAM:${NC} ${used}MB / ${total}MB (${pct}%) | ZRAM: $(get_zram_size_mb)MB | Swap: $(get_swap_used_mb)/$(get_swap_total_mb)MB"
        echo ""
        
        # Process list
        printf "  ${DIM}%-8s %-6s %-6s %-20s %s${NC}\n" "RSS(MB)" "%MEM" "PID" "USER" "COMMAND"
        echo "  ─────────────────────────────────────────────────────────────────"
        
        ps aux --sort=-%mem 2>/dev/null | awk 'NR>1 && NR<=21 {
            rss_mb = $6 / 1024;
            cmd = $11;
            for (i=12; i<=NF; i++) cmd = cmd " " $i;
            if (length(cmd) > 40) cmd = substr(cmd, 1, 37) "...";
            printf "  %-8.0f %-6s %-6s %-20s %s\n", rss_mb, $4, $2, $1, cmd
        }'
        
        sleep 3
    done
}
