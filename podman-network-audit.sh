#!/bin/bash

RED='\033[1;91m'      # Bright Red
GREEN='\033[1;92m'    # Bright Green
YELLOW='\033[1;93m'   # Bright Yellow
BLUE='\033[1;94m'     # Bright Blue
PURPLE='\033[1;95m'   # Bright Purple/Magenta
CYAN='\033[1;96m'     # Bright Cyan
GRAY='\033[0;90m'     # Dark Gray (for stopped containers)
NC='\033[0m'          # No Color

dual_count=0
v6_count=0
v4_count=0
none_count=0
error_count=0

SHOW_SUMMARY=false
FILTER_CONTAINER=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --summary) SHOW_SUMMARY=true ;;
        *) FILTER_CONTAINER="$1" ;;
    esac
    shift
done

hex_to_dec() {
    echo $((16#$1))
}

hex_ip_to_dec() {
    local hex=$1
    if [ ${#hex} -eq 8 ]; then
        printf "%d.%d.%d.%d" \
            $((16#${hex:6:2})) \
            $((16#${hex:4:2})) \
            $((16#${hex:2:2})) \
            $((16#${hex:0:2}))
    else
        echo "::"
    fi
}

wrap_text() {
    local text="$1"
    local width="$2"
    local prefix="$3"
    local first_line=true
    
    if [ ${#text} -le $width ]; then
        echo "$text"
        return
    fi
    
    local words=($text)
    local line=""
    local result=""
    
    for word in "${words[@]}"; do
        if [ ${#line} -eq 0 ]; then
            line="$word"
        elif [ $((${#line} + ${#word} + 1)) -le $width ]; then
            line="$line $word"
        else
            if [ "$first_line" = true ]; then
                result="$line"
                first_line=false
            else
                result="$result\n$prefix$line"
            fi
            line="$word"
        fi
    done
    
    # Add the last line
    if [ -n "$line" ]; then
        if [ "$first_line" = true ]; then
            result="$line"
        else
            result="$result\n$prefix$line"
        fi
    fi
    
    echo -e "$result"
}

printf "${GRAY}%-2s %-22s %-12s %-50s${NC}\n" " " "Container" "Network" "Listeners"
printf "${GRAY}%s${NC}\n" "--------------------------------------------------------------------------------"

if [ -n "$FILTER_CONTAINER" ]; then
    containers=$(podman ps --filter "name=$FILTER_CONTAINER" --format "{{.ID}} {{.Names}}" 2>/dev/null)
else
    containers=$(podman ps --format "{{.ID}} {{.Names}}" 2>/dev/null)
fi

if [ -z "$containers" ]; then
    echo -e "${RED}No containers found${NC}"
    exit 1
fi

while read -r cid name; do
    [ -z "$cid" ] && continue
    
    is_running=$(podman inspect "$cid" --format '{{.State.Running}}' 2>/dev/null)
    if [ "$is_running" != "true" ]; then
        printf "${GRAY}[ ]${NC} %-22s %-12s ${GRAY}Stopped${NC}\n" "$name" "-"
        ((error_count++))
        continue
    fi

    if ! podman exec "$cid" test -d /proc/net 2>/dev/null; then
        printf "${YELLOW}[!]${NC} %-22s %-12s ${YELLOW}No network stack${NC}\n" "$name" "-"
        ((error_count++))
        continue
    fi

    network_mode=$(podman inspect "$cid" --format '{{.HostConfig.NetworkMode}}' 2>/dev/null)
    case "$network_mode" in
        "host") net_mode="host" ;;
        "bridge") net_mode="bridge" ;;
        "none") net_mode="none" ;;
        "container:"*) net_mode="container" ;;
        "pasta") net_mode="pasta" ;;
        "slirp4netns") net_mode="slirp" ;;
        "") net_mode="default" ;;
        *) net_mode="${network_mode:0:8}" ;;
    esac

    published_full=$(podman inspect "$cid" --format '{{range $p, $conf := .NetworkSettings.Ports}}{{$p}}->{{(index $conf 0).HostPort}} {{end}}' 2>/dev/null | sed 's/ *$//')
    if [ -n "$published_full" ]; then
        pub_count=$(echo "$published_full" | tr ' ' '\n' | wc -l)
        if [ $pub_count -gt 3 ]; then
            pub_display=" ($pub_count ports published)"
        else
            pub_display=" ($published_full)"
        fi
    else
        pub_display=""
    fi

    ipv6_tcp=$(podman exec "$cid" cat /proc/net/tcp6 2>/dev/null | awk '
        NR>1 && $4 == "0A" {
            split($2, addr, ":");
            print addr[1] ":" addr[2];
        }
    ')

    ipv4_tcp=$(podman exec "$cid" cat /proc/net/tcp 2>/dev/null | awk '
        NR>1 && $4 == "0A" {
            split($2, addr, ":");
            print addr[1] ":" addr[2];
        }
    ')

    ipv6_udp=$(podman exec "$cid" cat /proc/net/udp6 2>/dev/null | awk '
        NR>1 && $4 == "0A" {
            split($2, addr, ":");
            print addr[1] ":" addr[2];
        }
    ')

    ipv4_udp=$(podman exec "$cid" cat /proc/net/udp 2>/dev/null | awk '
        NR>1 && $4 == "0A" {
            split($2, addr, ":");
            print addr[1] ":" addr[2];
        }
    ')

    has_v4=false
    has_v6=false
    
    listener_ports=""
    
    if [ -n "$ipv4_tcp" ]; then
        while IFS=':' read -r ip_hex port_hex; do
            port=$(hex_to_dec "$port_hex")
            if [ "$port" -ne 0 ]; then
                has_v4=true
                if [ "$ip_hex" = "00000000" ]; then
                    listener_ports="${listener_ports}0.0.0.0:${port} "
                elif [ "$ip_hex" = "0100007F" ] || [ "$ip_hex" = "7F000001" ]; then
                    listener_ports="${listener_ports}127.0.0.1:${port} "
                else
                    ip_dec=$(hex_ip_to_dec "$ip_hex")
                    listener_ports="${listener_ports}${ip_dec}:${port} "
                fi
            fi
        done <<< "$ipv4_tcp"
    fi
    
    if [ -n "$ipv6_tcp" ]; then
        while IFS=':' read -r ip_hex port_hex; do
            port=$(hex_to_dec "$port_hex")
            if [ "$port" -ne 0 ]; then
                has_v6=true
                if [ "$ip_hex" = "00000000000000000000000000000000" ]; then
                    listener_ports="${listener_ports}:::${port} "
                else
                    # Just show a shortened IPv6 address
                    listener_ports="${listener_ports}[${ip_hex:0:8}]:${port} "
                fi
            fi
        done <<< "$ipv6_tcp"
    fi
    
    if [ "$has_v4" = false ] && [ -n "$ipv4_udp" ]; then
        while IFS=':' read -r ip_hex port_hex; do
            port=$(hex_to_dec "$port_hex")
            if [ "$port" -ne 0 ]; then
                has_v4=true
                if [ "$ip_hex" = "00000000" ]; then
                    listener_ports="${listener_ports}UDP 0.0.0.0:${port} "
                else
                    listener_ports="${listener_ports}UDP ${port} "
                fi
                break # Just show first UDP port to keep it clean
            fi
        done <<< "$ipv4_udp"
    fi
    
    if [ "$has_v6" = false ] && [ -n "$ipv6_udp" ]; then
        while IFS=':' read -r ip_hex port_hex; do
            port=$(hex_to_dec "$port_hex")
            if [ "$port" -ne 0 ]; then
                has_v6=true
                listener_ports="${listener_ports}UDP :::${port} "
                break
            fi
        done <<< "$ipv6_udp"
    fi
    
    listener_display=$(echo "$listener_ports" | sed 's/ *$//')
    if [ -z "$listener_display" ]; then
        listener_display="No listeners"
    fi
    
    full_display="${listener_display}${pub_display}"
    
    status=""
    color=""
    if [ "$has_v4" = true ] && [ "$has_v6" = true ]; then
        status="D"
        color="$PURPLE"
        ((dual_count++))
    elif [ "$has_v6" = true ]; then
        status="6"
        color="$GREEN"
        ((v6_count++))
    elif [ "$has_v4" = true ]; then
        status="4"
        color="$BLUE"
        ((v4_count++))
    else
        status="✗"
        color="$RED"
        ((none_count++))
    fi
    
    if [ ${#full_display} -le 50 ]; then
        printf "${color}[${status}]${NC} %-22s %-12s %s\n" "$name" "$net_mode" "$full_display"
    else
        first_part="${full_display:0:50}"
        rest="${full_display:50}"
        
        if [[ "$first_part" =~ .*\ (.*)$ ]] && [ ${#first_part} -gt 20 ]; then
            break_pos=$(expr length "$first_part" - length "${BASH_REMATCH[1]}" - 1)
            first_part="${full_display:0:$break_pos}"
            rest="${full_display:$break_pos}"
            rest=$(echo "$rest" | sed 's/^ //')
        fi
        
        printf "${color}[${status}]${NC} %-22s %-12s %s\n" "$name" "$net_mode" "$first_part"
        
        indent="   $(printf '%*s' 22 '') $(printf '%*s' 12 '') "
        while [ -n "$rest" ]; do
            if [ ${#rest} -le 50 ]; then
                echo -e "$indent$rest"
                break
            else
                chunk="${rest:0:50}"
                if [[ "$chunk" =~ .*\ (.*)$ ]] && [ ${#chunk} -gt 20 ]; then
                    break_pos=$(expr length "$chunk" - length "${BASH_REMATCH[1]}" - 1)
                    chunk="${rest:0:$break_pos}"
                    rest="${rest:$break_pos}"
                    rest=$(echo "$rest" | sed 's/^ //')
                else
                    rest="${rest:50}"
                fi
                echo -e "$indent$chunk"
            fi
        done
    fi
done <<< "$containers"

if [ "$SHOW_SUMMARY" = true ]; then
    echo -e "\n${PURPLE}=== Summary ===${NC}"
    echo -e "Dual-Stack:  ${PURPLE}$dual_count${NC}"
    echo -e "IPv6-Only:   ${GREEN}$v6_count${NC}"
    echo -e "IPv4-Only:   ${BLUE}$v4_count${NC}"
    echo -e "No Listeners: ${RED}$none_count${NC}"
    echo -e "Errors:      ${YELLOW}$error_count${NC}"
    
    total=$((dual_count + v6_count + v4_count + none_count + error_count))
    if [ $total -gt 0 ]; then
        v6_percent=$(( (dual_count + v6_count) * 100 / total ))
        echo -e "\nIPv6 Capable: ${CYAN}${v6_percent}%${NC} of running containers"
        
        if [ $dual_count -eq 0 ] && [ $v6_count -eq 0 ] && [ $v4_count -gt 0 ]; then
            echo -e "${YELLOW}⚠️  No IPv6 listeners detected - consider IPv6 readiness${NC}"
        fi
    fi
fi
