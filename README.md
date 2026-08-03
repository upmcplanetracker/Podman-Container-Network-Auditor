Podman Container Network Auditor
================================

A lightweight, dependency-free shell script to audit running container network stacks for IPv6, Dual-Stack, and IPv4-only listeners.

* * *

What it does
------------

This script iterates through all running containers (Podman or Docker) and inspects their `/proc/net/tcp` and `/proc/net/tcp6` files. It identifies which containers are listening on ports and classifies them by their networking capability.

* * *

Features
--------

*   **Zero dependencies** - Uses only standard Linux tools (awk, sed, printf)
*   **Color-coded output** - Easy to read at a glance with bright, visible colors
*   **Smart wrapping** - Long listener lists wrap cleanly with proper indentation
*   **UDP detection** - Identifies UDP listeners alongside TCP
*   **Network mode display** - Shows bridge, pasta, host, container, etc.
*   **Published port info** - Shows host port mappings
*   **Summary mode** - Get quick statistics with `--summary`
*   **Container filtering** - Check specific containers by name
*   **Rootless & Rootful support** - Works with both user and system containers

* * *

Understanding the Output
------------------------

The script provides a status for each container:

| Status | Meaning |
|--------|---------|
| `[D]` | **Dual-Stack**: The container is listening on both IPv4 and IPv6 |
| `[6]` | **IPv6-Only**: The container is listening only on IPv6 |
| `[4]` | **IPv4-Only**: The container is listening only on IPv4 |
| `[✗]` | **No listeners**: The container is running but has no open ports (likely an outbound-only client) |
| `[!]` | **Access Denied**: The container's security profile prevents access to /proc/net |

The output includes:

*   **Container name** - The name of the container
*   **Network mode** - bridge, pasta, host, container, etc.
*   **Listeners** - IP addresses and ports the container is listening on
*   **Published ports** - Host port mappings (if any)

* * *

What it doesn't do
------------------

*   **External network scanning**: It checks the container's internal socket state, not external connectivity
*   **Configuration modification**: It's a read-only auditing tool
*   **Restricted containers**: Containers with hardened security profiles may block access to `/proc`

* * *

Usage
-----

### Prerequisites

The script requires standard Linux tools (awk, sed, printf) - available on almost all Linux distributions.

### Installation

    # Download the script
    wget https://github.com/upmcplanetracker/Podman-Container-Network-Auditor/blob/main/podman-network-audit
    
    # Make it executable
    chmod +x podman-network-audit
    
    # Optional: move to a directory in your PATH
    sudo mv podman-network-audit /usr/local/bin/
    

### Basic Usage

    # Audit all running containers (rootless)
    ./podman-network-audit
    
    # Audit rootful containers
    sudo ./podman-network-audit
    
    # Show summary statistics
    ./podman-network-audit --summary
    
    # Filter by container name
    ./podman-network-audit nginx
    
    # Filter with summary
    ./podman-network-audit nginx --summary
    
* * *

Sample Output
-------------

Here's example output from a server running multiple containers:

    Container              Network      Listeners (Host Mapping)
    --------------------------------------------------------------------------------
    [4] airspy                 bridge       0.0.0.0:30005 0.0.0.0:80 
    [6] navidrome              bridge       [IPv6]:4533(4533/tcp->4533) 
    [D] paperless-redis        bridge       0.0.0.0:6379 [IPv6]:6379 
    [6] crowdsec               bridge       [IPv6]:6060 [IPv6]:8080(8080/tcp->8080) 
    [D] grocy                  bridge       0.0.0.0:443 0.0.0.0:80(80/tcp->9283) 
                                          127.0.0.1:9000 [IPv6]:443 
                                          [IPv6]:80(80/tcp->9283) 
    [D] immich-redis           bridge       0.0.0.0:6379 [IPv6]:6379 
    [6] convertx               pasta        [IPv6]:3000(3000/tcp->3002) 
    [D] vert                   pasta        0.0.0.0:80(80/tcp->3123) 
                                          [IPv6]:80(80/tcp->3123) 
    [6] audiobookshelf         bridge       [IPv6]:80(80/tcp->13378) 
    [6] immich-machine-learning bridge       [IPv6]:3003 
    [6] calibre-web            bridge       [IPv6]:8083(8083/tcp->8091) 
    [6] tdarr                  pasta        [IPv6]:8265(8265/tcp->8265) 
                                          [IPv6]:8266(8266/tcp->8266) 
    [6] homepage               pasta        [IPv6]:3000(3000/tcp->3000) 
    [D] musicbrainz            pasta        0.0.0.0:5800(5800/tcp->5800) 0.0.0.0:5900 
                                          127.0.0.1:8000 
                                          [IPv6]:5800(5800/tcp->5800) [IPv6]:5900 
    [D] calibre-gui            bridge       0.0.0.0:8080 0.0.0.0:8082 
                                          0.0.0.0:8181(8181/tcp->8090) [IPv6]:8080 
                                          [IPv6]:8181(8181/tcp->8090) 
    [D] ente-database          bridge       0.0.0.0:5432 [IPv6]:5432 
    [D] minuspod-transcriber   bridge       0.0.0.0:8001 [IPv6]:8001 
    [6] immich-power-tools     bridge       [IPv6]:3000(3000/tcp->8002) 
    [D] bentopdf               pasta        0.0.0.0:8080(8080/tcp->8084) 
                                          [IPv6]:8080(8080/tcp->8084) 
    [6] stirlingpdf            pasta        127.0.0.1:2003 127.0.0.1:2004 
                                          [IPv6]:8080(8080/tcp->8180) 
    [6] uptime-kuma            pasta        [IPv6]:3001(3001/tcp->3001) 
    [D] immich-postgres        bridge       0.0.0.0:5432 [IPv6]:5432 
    [✗] adsbhub                bridge       No listeners
    [4] pfclient               bridge       0.0.0.0:30053(30053/tcp->30053) 
                                          0.0.0.0:30054 
    [✗] opensky                bridge       No listeners
    [6] fr24                   bridge       [IPv6]:8754(8754/tcp->8754) 
    [D] radarvirtuel           bridge       0.0.0.0:30005 [IPv6]:30005 
    [D] piaware                bridge       0.0.0.0:30001 0.0.0.0:30002 0.0.0.0:30003 
                                          0.0.0.0:30004 0.0.0.0:30005 0.0.0.0:30104 
                                          0.0.0.0:80(80/tcp->8011) 0.0.0.0:8080 
                                          0.0.0.0:8978 [IPv6]:30105 [IPv6]:30106 
    [D] rbfeeder               bridge       0.0.0.0:32004 0.0.0.0:32008 0.0.0.0:32088 
                                          0.0.0.0:32457 0.0.0.0:32458 0.0.0.0:32459 
                                          [IPv6]:32004 [IPv6]:32008 [IPv6]:32457 
                                          [IPv6]:32458 [IPv6]:32459 
    [6] planewatch             bridge       127.0.0.1:12346 [IPv6]:30105 
    [6] ente-museum            bridge       [IPv6]:2112 [IPv6]:8080(8080/tcp->8085) 
    [D] ente-web               bridge       0.0.0.0:3000 0.0.0.0:3001 0.0.0.0:3002 
                                          0.0.0.0:3003(3003/tcp->3403) 0.0.0.0:3004 
                                          0.0.0.0:3005 0.0.0.0:3006 0.0.0.0:3008 
                                          0.0.0.0:3009 0.0.0.0:3010 [IPv6]:3000 
                                          [IPv6]:3001 [IPv6]:3002 
                                          [IPv6]:3003(3003/tcp->3403) [IPv6]:3004 
                                          [IPv6]:3005 [IPv6]:3006 [IPv6]:3008 
                                          [IPv6]:3009 [IPv6]:3010 
    [6] immich-server          bridge       [IPv6]:2283(2283/tcp->2283) [IPv6]:43987 
    [6] immich-googlephotos    bridge       [IPv6]:8087(8087/tcp->8087) 
    [6] immich-drop            bridge       [IPv6]:8080(8080/tcp->8079) 
    [6] immich-public-proxy    bridge       [IPv6]:3000(3000/tcp->3003) 
    [6] cloudflared            bridge       [IPv6]:20241 
    [6] plex                   bridge       127.0.0.1:32401 127.0.0.1:32600 
                                          127.0.0.1:37461 
                                          [IPv6]:32400(32400/tcp->32400) 
    [✗] kometa                 bridge       No listeners
    [6] tautulli               bridge       [IPv6]:8181(8181/tcp->8181) 
    [6] dozzle                 pasta        [IPv6]:8080(8080/tcp->8082) 
    [D] omnitools              pasta        0.0.0.0:8999(8999/tcp->8999) 
                                          [IPv6]:8999(8999/tcp->8999) 
    [D] ultrafeeder            bridge       0.0.0.0:30001 0.0.0.0:30002 
                                          0.0.0.0:30003(30003/tcp->30003) 
                                          0.0.0.0:30004 
                                          0.0.0.0:30005(30005/tcp->30005) 
                                          0.0.0.0:30006 0.0.0.0:30047 0.0.0.0:30104 
                                          0.0.0.0:30152 0.0.0.0:31003 0.0.0.0:31004 
                                          0.0.0.0:31005 0.0.0.0:31006 0.0.0.0:32006 
                                          0.0.0.0:32007 0.0.0.0:32008 0.0.0.0:32009 
                                          0.0.0.0:8081(8081/tcp->8081) [IPv6]:30001 
                                          [IPv6]:30002 
                                          [IPv6]:30003(30003/tcp->30003) 
                                          [IPv6]:30004 
                                          [IPv6]:30005(30005/tcp->30005) 
                                          [IPv6]:30006 [IPv6]:30047 [IPv6]:30104 
                                          [IPv6]:30152 [IPv6]:31003 [IPv6]:31004 
                                          [IPv6]:31005 [IPv6]:31006 [IPv6]:32006 
                                          [IPv6]:32007 [IPv6]:32008 [IPv6]:32009 
                                          [IPv6]:39000 [IPv6]:39001 [IPv6]:39002 
                                          [IPv6]:39003 [IPv6]:39004 [IPv6]:39005 
                                          [IPv6]:39006 [IPv6]:39008 
                                          [IPv6]:8081(8081/tcp->8081) 
    [6] minuspod               bridge       [IPv6]:8000(8000/tcp->9998) 
    [6] paperless-gotenberg    bridge       [IPv6]:3000 
    [6] paperless-webserver    bridge       [IPv6]:8000(8000/tcp->8000) 
    
* * *

Summary Mode Example
--------------------

    $ ./podman-network-audit.sh --summary
    
    Generating summary...

    === Summary ===
    Dual-Stack:    16
    IPv6-Only:     25
    IPv4-Only:     2
    No Listeners:  3
    Host Network:  0  (excluded from IPv6 calc)

    IPv6 Capable:  89% of non‑host containers
    
* * *

Tips & Tricks
-------------

### Quick IPv6 Readiness Check

    # Check how many containers support IPv6
    ./podman-network-audit --summary | grep "IPv6 Capable"
    

### Monitor Specific Container

    # Watch a container's network status
    watch -n 5 './podman-network-audit my-container'
    

### Export for Reporting

    # Save output without colors
    ./podman-network-audit | sed 's/\x1b\[[0-9;]*m//g' > audit-report.txt

* * *

Troubleshooting
---------------

### "No containers found"

*   Make sure you have running containers: `podman ps`
*   Try with sudo for rootful containers
*   Check if you're in the correct user context

### "No network stack accessible"

*   Some containers have restricted `/proc` access
*   Check container security settings
*   May indicate a hardened container profile

### Missing colors

*   Some terminals may not support ANSI colors
*   Colors use bright variants (91-96) for better visibility

* * *

Contributing
------------

Contributions are welcome! Please submit issues and pull requests on GitHub.

* * *

### Development

*   The script aims to be POSIX-compliant
*   New features should maintain zero external dependencies
*   Test both rootless and rootful modes
