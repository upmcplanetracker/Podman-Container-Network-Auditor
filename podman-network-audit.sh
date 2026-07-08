#!/bin/bash
set -u

# Colors and configuration
RED='\033[1;91m'; GREEN='\033[1;92m'; BLUE='\033[1;94m'; PURPLE='\033[1;95m'; GRAY='\033[0;90m'; NC='\033[0m'

# Allow passing a specific container as an argument
TARGET_CONTAINER=${1:-""}
SHOW_SUMMARY=false
[[ "${1:-}" == "--summary" ]] && SHOW_SUMMARY=true

if [ "$SHOW_SUMMARY" = true ]; then echo "Generating summary..."; fi

# Counters
dual_count=0; v6_count=0; v4_count=0; none_count=0; total_running=0

decode_ip() {
    local hex=$1
    if [ ${#hex} -eq 8 ]; then
        printf "%d.%d.%d.%d" $((16#${hex:6:2})) $((16#${hex:4:2})) $((16#${hex:2:2})) $((16#${hex:0:2}))
    else echo "::"; fi
}

if [ "$SHOW_SUMMARY" = false ]; then
    printf "${GRAY}%-22s %-12s %s${NC}\n" "Container" "Network" "Listeners (Host Mapping)"
    printf "${GRAY}%s${NC}\n" "--------------------------------------------------------------------------------"
fi

# Logic to filter by specific container or list all
if [ -n "$TARGET_CONTAINER" ] && [ "$SHOW_SUMMARY" = false ]; then
    PS_CMD="podman ps --filter name=^$TARGET_CONTAINER$ --format '{{.ID}} {{.Names}}'"
else
    PS_CMD="podman ps --format '{{.ID}} {{.Names}}'"
fi

while read -r cid name; do
    pid=$(podman inspect "$cid" --format '{{.State.Pid}}' 2>/dev/null)
    [ -z "$pid" ] || [ "$pid" == "0" ] && continue
    ((total_running++))

    mappings=$(podman inspect "$cid" --format '{{range $p, $conf := .NetworkSettings.Ports}}{{if $conf}}{{range $conf}}{{$p}}:{{.HostPort}} {{end}}{{end}}{{end}}' 2>/dev/null)
    net_mode=$(podman inspect "$cid" --format '{{.HostConfig.NetworkMode}}' 2>/dev/null)

    v4_active=$(awk 'NR>1 && $4=="0A" {split($2,a,":"); print a[1] ":" strtonum("0x"a[2])}' "/proc/$pid/net/tcp" 2>/dev/null | sort -u)
    v6_active=$(awk 'NR>1 && $4=="0A" {split($2,a,":"); print a[1] ":" strtonum("0x"a[2])}' "/proc/$pid/net/tcp6" 2>/dev/null | sort -u)

    has_v4=false; has_v6=false; port_string=""

    for entry in $v4_active $v6_active; do
        ip_hex=${entry%%:*}; port=${entry#*:}
        [ "$ip_hex" == "00000000" ] && has_v4=true
        [ "$ip_hex" == "00000000000000000000000000000000" ] && has_v6=true
        
        mapped_port=$(echo "$mappings" | grep -oE "$port/[a-z]+:[0-9]+" | cut -d: -f2 | head -n1)
        label="$(decode_ip "$ip_hex"):$port"
        [ -n "$mapped_port" ] && label="$label(${port}/tcp->${mapped_port})"
        port_string+="$label "
    done

    if [ "$has_v4" = true ] && [ "$has_v6" = true ]; then status="D"; color="$PURPLE"; ((dual_count++))
    elif [ "$has_v6" = true ]; then status="6"; color="$GREEN"; ((v6_count++))
    elif [ "$has_v4" = true ]; then status="4"; color="$BLUE"; ((v4_count++))
    else status="✗"; color="$RED"; ((none_count++)); port_string="No listeners"; fi

    if [ "$SHOW_SUMMARY" = false ]; then
        header=$(printf "${color}[${status}]${NC} %-22s %-12s " "$name" "$net_mode")
        echo "$port_string" | fold -s -w 42 | awk -v h="$header" 'NR==1 {print h $0} NR>1 {print "                                      " $0}'
    fi
done <<< "$(eval $PS_CMD)"

if [ "$total_running" -gt 0 ] && [ "$SHOW_SUMMARY" = true ]; then
    capable=$((dual_count + v6_count))
    percent=$(( (capable * 100) / total_running ))
    echo -e "\n=== Summary ==="
    echo "Dual-Stack:   $dual_count"
    echo "IPv6-Only:    $v6_count"
    echo "IPv4-Only:    $v4_count"
    echo "No Listeners: $none_count"
    echo -e "\nIPv6 Capable: $percent% of running containers"
fi
