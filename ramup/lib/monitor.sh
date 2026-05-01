#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# ramup/lib/monitor.sh — Live Memory Dashboard
# ═══════════════════════════════════════════════════════════

# ─── Start Monitor ────────────────────────────────────────
start_monitor() {
    local refresh_rate="${1:-2}"
    
    # Trap for clean exit
    trap 'echo ""; echo "Monitor stopped."; exit 0' INT TERM
    
    while true; do
        clear
        render_dashboard
        sleep "$refresh_rate"
    done
}

# ─── Render Dashboard ─────────────────────────────────────
render_dashboard() {
    local total_ram free_ram used_ram
    local zram_size zram_used compression
    local swap_total swap_used
    local effective_ram gained
    local uptime_str load_avg
    
    total_ram=$(get_total_ram_mb)
    free_ram=$(get_available_ram_mb)
    used_ram=$((total_ram - free_ram))
    zram_size=$(get_zram_size_mb)
    zram_used=$(get_zram_used_mb)
    compression=$(get_compression_ratio)
    swap_total=$(get_swap_total_mb)
    swap_used=$(get_swap_used_mb)
    effective_ram=$((total_ram + zram_size + swap_total))
    gained=$((zram_size + swap_total))
    uptime_str=$(uptime -p 2>/dev/null || uptime | awk -F'up' '{print $2}' | awk -F',' '{print $1}')
    load_avg=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
    
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Calculate percentages
    local ram_pct=$((used_ram * 100 / total_ram))
    local zram_pct=0
    [[ "$zram_size" -gt 0 ]] && zram_pct=$((zram_used * 100 / zram_size))
    local swap_pct=0
    [[ "$swap_total" -gt 0 ]] && swap_pct=$((swap_used * 100 / swap_total))
    local effective_pct=$((used_ram * 100 / effective_ram))
    
    # Build the dashboard
    echo -e "${GREEN}${BOLD}"
    echo "  ╔═══════════════════════════════════════════════════════════════╗"
    echo "  ║                    🟢 R A M U P  Monitor 🟢                  ║"
    echo "  ╠═══════════════════════════════════════════════════════════════╣"
    echo -e "  ║  ${DIM}${timestamp}${NC}${GREEN}${BOLD}                               ║"
    echo "  ╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Memory Bar
    echo -e "  ${WHITE}${BOLD}📊 MEMORY OVERVIEW${NC}"
    echo "  ─────────────────────────────────────────────────────"
    
    print_bar "  Physical RAM" "$used_ram" "$total_ram" "MB" "$ram_pct"
    echo ""
    
    if [[ "$zram_size" -gt 0 ]]; then
        print_bar "  ZRAM" "$zram_used" "$zram_size" "MB" "$zram_pct"
        echo -e "  ${DIM}  Compression: ${compression}:1 | Algorithm: $(get_best_algorithm)${NC}"
        echo ""
    fi
    
    if [[ "$swap_total" -gt 0 ]]; then
        print_bar "  Swap File" "$swap_used" "$swap_total" "MB" "$swap_pct"
        echo ""
    fi
    
    echo -e "  ${GREEN}${BOLD}  Effective RAM: ~${effective_ram}MB${NC} | ${CYAN}Gained: +${gained}MB${NC}"
    echo ""
    
    # Top processes
    echo -e "  ${WHITE}${BOLD}🔝 TOP PROCESSES${NC}"
    echo "  ─────────────────────────────────────────────────────"
    ps aux --sort=-%mem 2>/dev/null | awk 'NR>1 && NR<=8 {
        rss_mb = $6 / 1024;
        bar = "";
        pct = $4;
        bar_len = int(pct / 5);
        for (i=0; i<bar_len; i++) bar = bar "█";
        for (i=bar_len; i<20; i++) bar = bar "░";
        printf "  %5.0fMB %5s%% %s %s\n", rss_mb, $4, bar, $11
    }'
    echo ""
    
    # System info
    echo -e "  ${WHITE}${BOLD}⚙️  SYSTEM${NC}"
    echo "  ─────────────────────────────────────────────────────"
    echo -e "  ${DIM}Uptime:${NC} ${uptime_str}"
    echo -e "  ${DIM}Load:${NC}   ${load_avg}"
    echo -e "  ${DIM}Swap:${NC}   $(get_swap_stats)"
    echo -e "  ${DIM}ZRAM:${NC}  $(get_zram_stats)"
    echo ""
    
    echo -e "  ${DIM}Press Ctrl+C to exit${NC}"
}

# ─── Print Progress Bar ───────────────────────────────────
print_bar() {
    local label="$1"
    local used="$2"
    local total="$3"
    local unit="$4"
    local pct="$5"
    
    local bar_len=30
    local filled=$((pct * bar_len / 100))
    local empty=$((bar_len - filled))
    
    # Color based on percentage
    local color="$GREEN"
    if [[ "$pct" -gt 80 ]]; then
        color="$RED"
    elif [[ "$pct" -gt 60 ]]; then
        color="$YELLOW"
    fi
    
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    
    printf "  ${DIM}%-14s${NC} ${color}[%s]${NC} ${WHITE}%3d%%${NC} ${DIM}%d/%d %s${NC}\n" \
        "$label" "$bar" "$pct" "$used" "$total" "$unit"
}

# ─── Run Benchmark ────────────────────────────────────────
run_benchmark() {
    echo -e "${CYAN}${BOLD}🧪 RAMUP Memory Benchmark${NC}"
    echo ""
    
    # Memory allocation test
    echo -e "${DIM}Testing memory allocation speed...${NC}"
    
    local start end elapsed
    
    # Test 1: Direct RAM write speed
    start=$(date +%s%N)
    dd if=/dev/zero of=/dev/null bs=1M count=1024 2>/dev/null
    end=$(date +%s%N)
    elapsed=$(( (end - start) / 1000000 ))
    echo -e "  ${GREEN}RAM Write:${NC} ${elapsed}ms for 1GB"
    
    # Test 2: Swap write speed (if available)
    if [[ -f "$SWAP_FILE" ]]; then
        start=$(date +%s%N)
        dd if=/dev/zero of="${SWAP_FILE}.bench" bs=1M count=256 2>/dev/null
        sync
        end=$(date +%s%N)
        elapsed=$(( (end - start) / 1000000 ))
        rm -f "${SWAP_FILE}.bench"
        echo -e "  ${YELLOW}Swap Write:${NC} ${elapsed}ms for 256MB"
    fi
    
    # Test 3: ZRAM compression speed
    if is_zram_active; then
        echo -e "  ${GREEN}ZRAM:${NC} Active and ready"
    fi
    
    echo ""
    echo -e "${GREEN}Benchmark complete ✅${NC}"
}
