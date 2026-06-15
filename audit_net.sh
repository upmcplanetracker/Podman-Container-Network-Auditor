#!/bin/bash

# Podman Dual-Stack & Network Audit Script
echo -e "Status\t\tContainer\t\tDetails"
echo -e "------------------------------------------------------------"

podman ps --format "{{.ID}} {{.Names}}" | while read -r cid name; do
    
    # 1. Check if container is running
    is_running=$(podman inspect "$cid" --format '{{.State.Running}}' 2>/dev/null)
    if [ "$is_running" != "true" ]; then
        echo -e "\033[1;30m[ ] $name\033[0m: Stopped"
        continue
    fi

    # 2. Check if network stack is accessible
    if ! podman exec "$cid" test -d /proc/net 2>/dev/null; then
        echo -e "\033[1;33m[!] $name\033[0m: No network stack accessible"
        continue
    fi

    # 3. Parse IPv6 Listeners
    ipv6_listeners=$(podman exec "$cid" cat /proc/net/tcp6 2>/dev/null | awk '
        NR>1 && $2 ~ /^00000000000000000000000000000000:/ && $4 == "0A" {
            split($2, addr, ":");
            val = 0;
            for(i=1; i<=length(addr[2]); i++) {
                c = substr(addr[2], i, 1);
                n = index("0123456789ABCDEF", toupper(c)) - 1;
                val = (val * 16) + n;
            }
            print val;
        }
    ')

    # 4. Parse IPv4 Listeners (and associated PID)
    # $2 is local_address (hex port), $10 is uid/pid info
    ipv4_data=$(podman exec "$cid" cat /proc/net/tcp 2>/dev/null | awk '
        NR>1 && $4 == "0A" {
            split($2, addr, ":");
            val = 0;
            for(i=1; i<=length(addr[2]); i++) {
                c = substr(addr[2], i, 1);
                n = index("0123456789ABCDEF", toupper(c)) - 1;
                val = (val * 16) + n;
            }
            print val ":" $10;
        }
    ')

    # 5. Logic for reporting
    if [ -n "$ipv6_listeners" ] && [ -n "$ipv4_data" ]; then
        ports=$(echo "$ipv6_listeners" | xargs | sed 's/ /, /g')
        echo -e "\033[1;35m[D] $name\033[0m: Dual-Stack on: $ports"
    elif [ -n "$ipv6_listeners" ]; then
        ports=$(echo "$ipv6_listeners" | xargs | sed 's/ /, /g')
        echo -e "\033[1;32m[6] $name\033[0m: IPv6-Only on: $ports"
    elif [ -n "$ipv4_data" ]; then
        # Extract ports and PIDs for display
        ports=$(echo "$ipv4_data" | cut -d: -f1 | xargs | sed 's/ /, /g')
        pids=$(echo "$ipv4_data" | cut -d: -f2 | sort -u | xargs | sed 's/ /, /g')
        echo -e "\033[1;36m[4] $name\033[0m: IPv4-Only on: $ports (PIDs: $pids)"
    else
        echo -e "\033[1;31m[✗] $name\033[0m: No listeners (Client/Outbound only)"
    fi
done
