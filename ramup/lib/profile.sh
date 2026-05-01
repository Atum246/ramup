#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# ramup/lib/profile.sh — Memory Profiling & System Info
# ═══════════════════════════════════════════════════════════════════════════════

# ─── Profile Memory Usage ─────────────────────────────────────────────────────
profile_memory() {
    local target="${1:-all}"
    
    echo -e "${CYAN}${BOLD}  📊 Memory Profile: ${target}${NC}"
    echo ""
    
    if [[ "$target" == "all" ]]; then
        profile_all_memory
    else
        profile_process "$target"
    fi
}

profile_all_memory() {
    detect_system
    
    local total_mb available_mb used_mb
    total_mb=$(get_total_ram_mb)
    available_mb=$(get_available_ram_mb)
    used_mb=$((total_mb - available_mb))
    
    echo -e "  ${WHITE}${BOLD}System Memory:${NC}"
    echo -e "  ${DIM}├─${NC} Total: $(human_readable $total_mb)"
    echo -e "  ${DIM}├─${NC} Used: $(human_readable $used_mb)"
    echo -e "  ${DIM}├─${NC} Available: $(human_readable $available_mb)"
    local pct=0
    [[ "$total_mb" -gt 0 ]] && pct=$((used_mb * 100 / total_mb))
    echo -e "  ${DIM}└─${NC} Usage: ${pct}%"
    echo ""
    
    echo -e "  ${WHITE}${BOLD}Memory Breakdown:${NC}"
    echo ""
    
    # Categorize processes
    local web_mem=0 db_mem=0 docker_mem=0 system_mem=0 other_mem=0
    
    while IFS= read -r line; do
        local rss name
        rss=$(echo "$line" | awk '{print $1}')
        name=$(echo "$line" | awk '{print $2}')
        rss=$((rss / 1024))
        
        case "$name" in
            nginx|apache2|httpd|caddy|node|python3|php-fpm)
                web_mem=$((web_mem + rss))
                ;;
            mysqld|postgres|mongod|redis-server|mariadb)
                db_mem=$((db_mem + rss))
                ;;
            dockerd|containerd|docker-proxy)
                docker_mem=$((docker_mem + rss))
                ;;
            systemd|journald|sshd|cron|agetty|rsyslogd)
                system_mem=$((system_mem + rss))
                ;;
            *)
                other_mem=$((other_mem + rss))
                ;;
        esac
    done < <(ps -eo rss,comm --sort=-rss --noheadings 2>/dev/null | head -50)
    
    local cat_total=$((web_mem + db_mem + docker_mem + system_mem + other_mem))
    [[ "$cat_total" -eq 0 ]] && cat_total=1
    
    print_category_bar "  Web Servers" "$web_mem" "$cat_total"
    print_category_bar "  Databases" "$db_mem" "$cat_total"
    print_category_bar "  Docker" "$docker_mem" "$cat_total"
    print_category_bar "  System" "$system_mem" "$cat_total"
    print_category_bar "  Other" "$other_mem" "$cat_total"
    
    echo ""
    
    echo -e "  ${WHITE}${BOLD}Top 10 Processes:${NC}"
    echo ""
    printf "  ${DIM}%-8s %-8s %-6s %s${NC}\n" "RSS(MB)" "%MEM" "PID" "PROCESS"
    echo "  ─────────────────────────────────────────────────"
    
    ps aux --sort=-%mem 2>/dev/null | awk 'NR>1 && NR<=11 {
        rss_mb = $6 / 1024;
        printf "  %-8.0f %-8s %-6s %s\n", rss_mb, $4, $2, $11
    }'
}

profile_process() {
    local name="$1"
    
    local pids
    pids=$(pgrep -x "$name" 2>/dev/null || pgrep -f "$name" 2>/dev/null || echo "")
    
    if [[ -z "$pids" ]]; then
        echo -e "  ${RED}Process '${name}' not found${NC}"
        return 1
    fi
    
    echo -e "  ${WHITE}${BOLD}Process: ${name}${NC}"
    echo ""
    
    local total_rss=0
    local count=0
    
    while IFS= read -r pid; do
        [[ -z "$pid" ]] && continue
        
        local rss vmsize status
        rss=$(ps -p "$pid" -o rss= 2>/dev/null || echo "0")
        vmsize=$(ps -p "$pid" -o vsz= 2>/dev/null || echo "0")
        status=$(ps -p "$pid" -o stat= 2>/dev/null || echo "?")
        
        rss=$((rss / 1024))
        vmsize=$((vmsize / 1024))
        
        echo -e "  ${DIM}├─${NC} PID: ${WHITE}${pid}${NC}"
        echo -e "  ${DIM}│${NC}  RSS: ${WHITE}${rss}MB${NC} | VSZ: ${WHITE}${vmsize}MB${NC} | Status: ${WHITE}${status}${NC}"
        
        # Show memory map summary
        if [[ -r "/proc/${pid}/smaps_rollup" ]]; then
            local rss_clean shared private
            rss_clean=$(awk '/^Rss:/ {print $2}' /proc/${pid}/smaps_rollup 2>/dev/null || echo "0")
            shared=$(awk '/^Shared_Clean:/ {print $2}' /proc/${pid}/smaps_rollup 2>/dev/null || echo "0")
            private=$(awk '/^Private_Clean:/ {print $2}' /proc/${pid}/smaps_rollup 2>/dev/null || echo "0")
            
            echo -e "  ${DIM}│${NC}  Clean RSS: $((rss_clean / 1024))MB | Shared: $((shared / 1024))MB | Private: $((private / 1024))MB"
        fi
        
        total_rss=$((total_rss + rss))
        count=$((count + 1))
    done <<< "$pids"
    
    echo -e "  ${DIM}└─${NC} Total: ${WHITE}${total_rss}MB${NC} across ${WHITE}${count}${NC} process(es)"
}

print_category_bar() {
    local label="$1"
    local value="$2"
    local total="$3"
    
    local pct=0
    [[ "$total" -gt 0 ]] && pct=$((value * 100 / total))
    
    local bar_len=20
    local filled=$((pct * bar_len / 100))
    local empty=$((bar_len - filled))
    
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    
    local color="$GREEN"
    [[ "$pct" -gt 30 ]] && color="$YELLOW"
    [[ "$pct" -gt 60 ]] && color="$RED"
    
    printf "  ${DIM}%-16s${NC} ${color}[%s]${NC} ${WHITE}%3d%%${NC} ${DIM}%sMB${NC}\n" "$label" "$bar" "$pct" "$value"
}

# ─── List Services by Memory ──────────────────────────────────────────────────
list_services_by_memory() {
    echo -e "${CYAN}${BOLD}  📋 Services by Memory Usage${NC}"
    echo ""
    
    printf "  ${DIM}%-8s %-8s %-20s %s${NC}\n" "RSS(MB)" "%MEM" "SERVICE" "STATUS"
    echo "  ─────────────────────────────────────────────────────────"
    
    # Get systemd services with memory info
    systemctl list-units --type=service --state=running --no-pager --no-legend 2>/dev/null | while read -r line; do
        local service
        service=$(echo "$line" | awk '{print $1}')
        
        # Get main PID
        local pid
        pid=$(systemctl show "$service" --property=MainPID --value 2>/dev/null || echo "0")
        
        if [[ "$pid" -gt 0 ]]; then
            local rss mem_pct
            rss=$(ps -p "$pid" -o rss= 2>/dev/null || echo "0")
            mem_pct=$(ps -p "$pid" -o %mem= 2>/dev/null || echo "0")
            rss=$((rss / 1024))
            
            if [[ "$rss" -gt 0 ]]; then
                local status
                status=$(systemctl is-active "$service" 2>/dev/null || echo "unknown")
                printf "  %-8s %-8s %-20s %s\n" "${rss}MB" "${mem_pct}" "$service" "$status"
            fi
        fi
    done | sort -rn | head -20
}

# ─── System Info ──────────────────────────────────────────────────────────────
show_sysinfo() {
    detect_system
    
    echo -e "${CYAN}${BOLD}  💻 System Information${NC}"
    echo ""
    
    echo -e "  ${WHITE}${BOLD}Hardware:${NC}"
    echo -e "  ${DIM}├─${NC} CPU: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
    echo -e "  ${DIM}├─${NC} Cores: ${CPU_CORES}"
    echo -e "  ${DIM}├─${NC} RAM: $(human_readable $TOTAL_RAM_MB)"
    echo -e "  ${DIM}├─${NC} Architecture: $(uname -m)"
    echo -e "  ${DIM}└─${NC} Storage: $( [[ $HAS_SSD -eq 1 ]] && echo "SSD" || echo "HDD" )"
    echo ""
    
    echo -e "  ${WHITE}${BOLD}Software:${NC}"
    echo -e "  ${DIM}├─${NC} OS: ${DISTRO} ${DISTRO_VERSION}"
    echo -e "  ${DIM}├─${NC} Kernel: ${KERNEL_VERSION}"
    echo -e "  ${DIM}├─${NC} Virtualization: ${VIRT_TYPE}"
    echo -e "  ${DIM}└─${NC} Shell: ${SHELL}"
    echo ""
    
    echo -e "  ${WHITE}${BOLD}Memory:${NC}"
    echo -e "  ${DIM}├─${NC} Total: $(human_readable $TOTAL_RAM_MB)"
    echo -e "  ${DIM}├─${NC} Available: $(human_readable $(get_available_ram_mb))"
    echo -e "  ${DIM}├─${NC} ZRAM Support: $( [[ $HAS_ZRAM_SUPPORT -eq 1 ]] && echo "Yes ✓" || echo "No ✗" )"
    echo -e "  ${DIM}├─${NC} ZSTD Support: $( [[ $HAS_ZSTD -eq 1 ]] && echo "Yes ✓" || echo "No ✗" )"
    echo -e "  ${DIM}└─${NC} LZ4 Support: $( [[ $HAS_LZ4 -eq 1 ]] && echo "Yes ✓" || echo "No ✗" )"
    echo ""
    
    echo -e "  ${WHITE}${BOLD}Swap:${NC}"
    echo -e "  ${DIM}├─${NC} Total: $(human_readable $(get_swap_total_mb))"
    echo -e "  ${DIM}├─${NC} Used: $(human_readable $(get_swap_used_mb))"
    echo -e "  ${DIM}└─${NC} ZRAM: $(human_readable $(get_zram_size_mb))"
    echo ""
    
    echo -e "  ${WHITE}${BOLD}Optimization:${NC}"
    echo -e "  ${DIM}├─${NC} Swappiness: $(sysctl -n vm.swappiness 2>/dev/null || echo 'N/A')"
    echo -e "  ${DIM}├─${NC} VFS Cache Pressure: $(sysctl -n vm.vfs_cache_pressure 2>/dev/null || echo 'N/A')"
    echo -e "  ${DIM}├─${NC} Overcommit: $(sysctl -n vm.overcommit_memory 2>/dev/null || echo 'N/A')"
    echo -e "  ${DIM}└─${NC} Min Free: $(sysctl -n vm.min_free_kbytes 2>/dev/null || echo 'N/A')KB"
}
