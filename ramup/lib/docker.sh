#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# ramup/lib/docker.sh — Docker Memory Optimization
# ═══════════════════════════════════════════════════════════════════════════════

# ─── Optimize Docker ──────────────────────────────────────────────────────────
optimize_docker() {
    if ! command -v docker &>/dev/null; then
        log WARN "Docker not found — skipping Docker optimization"
        return 0
    fi
    
    echo -e "${CYAN}${BOLD}  🐳 Optimizing Docker memory...${NC}"
    echo ""
    
    # 1. Enable Docker live-restore (reduces memory on restart)
    echo -e "  ${DIM}├─${NC} Configuring Docker daemon..."
    configure_docker_daemon
    
    # 2. Set container memory limits
    echo -e "  ${DIM}├─${NC} Setting default memory limits..."
    set_default_container_limits
    
    # 3. Clean up unused resources
    echo -e "  ${DIM}├─${NC} Cleaning up unused Docker resources..."
    cleanup_docker
    
    # 4. Optimize container logs
    echo -e "  ${DIM}├─${NC} Optimizing container logging..."
    optimize_container_logs
    
    echo ""
    echo -e "  ${GREEN}${BOLD}✓ Docker optimization complete${NC}"
}

# ─── Configure Docker Daemon ──────────────────────────────────────────────────
configure_docker_daemon() {
    local daemon_json="/etc/docker/daemon.json"
    
    if [[ -f "$daemon_json" ]]; then
        # Backup existing config
        cp "$daemon_json" "${daemon_json}.bak.$(date +%Y%m%d)" 2>/dev/null || true
    fi
    
    # Create optimized daemon config
    mkdir -p /etc/docker
    
    local current_config="{}"
    [[ -f "$daemon_json" ]] && current_config=$(cat "$daemon_json")
    
    # Merge with our optimizations
    cat > "$daemon_json" << 'EOF'
{
    "live-restore": true,
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "default-ulimits": {
        "nofile": {
            "Name": "nofile",
            "Hard": 65536,
            "Soft": 65536
        }
    }
}
EOF
    
    # Reload Docker if running
    if systemctl is-active --quiet docker 2>/dev/null; then
        systemctl reload docker 2>/dev/null || true
    fi
}

# ─── Set Default Container Limits ─────────────────────────────────────────────
set_default_container_limits() {
    # This sets up a systemd drop-in to limit container memory by default
    local dropin_dir="/etc/systemd/system/docker.service.d"
    mkdir -p "$dropin_dir"
    
    cat > "${dropin_dir}/memory-limit.conf" << EOF
[Service]
# Limit default container memory to 75% of total RAM
Environment="DOCKER_DEFAULT_MEMORY_LIMIT=${TOTAL_RAM_MB}m"
EOF
    
    systemctl daemon-reload 2>/dev/null || true
}

# ─── Cleanup Docker ───────────────────────────────────────────────────────────
cleanup_docker() {
    # Remove stopped containers
    docker container prune -f 2>/dev/null || true
    
    # Remove unused images
    docker image prune -f 2>/dev/null || true
    
    # Remove unused volumes
    docker volume prune -f 2>/dev/null || true
    
    # Remove build cache
    docker builder prune -f 2>/dev/null || true
    
    log DEBUG "Docker cleanup complete"
}

# ─── Optimize Container Logs ──────────────────────────────────────────────────
optimize_container_logs() {
    # Limit log size for all containers
    local docker_config="/etc/docker/daemon.json"
    
    if [[ -f "$docker_config" ]]; then
        if ! grep -q "max-size" "$docker_config" 2>/dev/null; then
            # Add log limits
            python3 -c "
import json
with open('$docker_config') as f:
    config = json.load(f)
config['log-driver'] = 'json-file'
config['log-opts'] = {'max-size': '10m', 'max-file': '3'}
with open('$docker_config', 'w') as f:
    json.dump(config, f, indent=4)
" 2>/dev/null || true
        fi
    fi
}

# ─── Set Docker Container Limit ───────────────────────────────────────────────
set_docker_limit() {
    local container="$1"
    local limit_mb="$2"
    
    if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${container}$"; then
        log ERROR "Container '${container}' not found or not running"
        return 1
    fi
    
    # Update container memory limit (requires restart)
    docker update --memory="${limit_mb}m" --memory-swap="${limit_mb}m" "$container" 2>/dev/null || {
        log ERROR "Failed to set memory limit for ${container}"
        return 1
    }
    
    log OK "Set ${container} memory limit to ${limit_mb}MB"
}

# ─── Docker Memory Stats ──────────────────────────────────────────────────────
docker_memory_stats() {
    if ! command -v docker &>/dev/null; then
        log ERROR "Docker not found"
        return 1
    fi
    
    echo -e "${CYAN}${BOLD}  🐳 Docker Container Memory Stats${NC}"
    echo ""
    
    if ! docker ps --format '{{.Names}}' 2>/dev/null | head -1 | grep -q .; then
        echo -e "  ${DIM}No running containers${NC}"
        return 0
    fi
    
    printf "  ${DIM}%-25s %-12s %-12s %-8s %s${NC}\n" "CONTAINER" "USAGE" "LIMIT" "%MEM" "STATUS"
    echo "  ─────────────────────────────────────────────────────────────────"
    
    docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}" 2>/dev/null | tail -n +2 | while IFS= read -r line; do
        echo "  $line"
    done
}

# ─── Watch Process for Memory Leaks ───────────────────────────────────────────
watch_process() {
    local target="$1"
    
    echo -e "${CYAN}${BOLD}  👁️ Watching '${target}' for memory leaks...${NC}"
    echo -e "  ${DIM}Press Ctrl+C to stop${NC}"
    echo ""
    
    trap 'echo ""; echo "Stopped watching."; exit 0' INT TERM
    
    local prev_rss=0
    local leak_count=0
    
    while true; do
        local pid rss
        
        # Find PID by name or use directly
        if [[ "$target" =~ ^[0-9]+$ ]]; then
            pid="$target"
        else
            pid=$(pgrep -x "$target" 2>/dev/null | head -1)
        fi
        
        if [[ -z "$pid" ]]; then
            echo -e "  ${RED}Process '${target}' not found${NC}"
            sleep 5
            continue
        fi
        
        rss=$(ps -p "$pid" -o rss= 2>/dev/null || echo "0")
        rss=$((rss / 1024))
        
        local diff=$((rss - prev_rss))
        local trend="→"
        local trend_color="$DIM"
        
        if [[ "$diff" -gt 10 ]]; then
            trend="↑ +${diff}MB"
            trend_color="$RED"
            leak_count=$((leak_count + 1))
        elif [[ "$diff" -lt -10 ]]; then
            trend="↓ ${diff}MB"
            trend_color="$GREEN"
            leak_count=0
        else
            trend="→ stable"
            trend_color="$GREEN"
            leak_count=0
        fi
        
        local timestamp
        timestamp=$(date '+%H:%M:%S')
        
        printf "  ${DIM}[%s]${NC} PID: %-8s RSS: ${WHITE}%-6s MB${NC} %b%s%b" \
            "$timestamp" "$pid" "$rss" "$trend_color" "$trend" "$NC"
        
        if [[ "$leak_count" -gt 5 ]]; then
            echo -e "  ${RED}⚠️  Possible memory leak detected!${NC}"
        else
            echo ""
        fi
        
        prev_rss=$rss
        sleep 5
    done
}
