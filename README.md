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
    wget https://github.com/upmcplanetracker/Podman-Container-Network-Auditor/blob/main/audit_net.sh
    
    # Make it executable
    chmod +x podman-network-audit.sh
    
    # Optional: move to a directory in your PATH
    sudo mv podman-network-audit.sh /usr/local/bin/
    

### Basic Usage

    # Audit all running containers (rootless)
    ./podman-network-audit.sh
    
    # Audit rootful containers
    sudo ./podman-network-audit.sh
    
    # Show summary statistics
    ./podman-network-audit.sh --summary
    
    # Filter by container name
    ./podman-network-audit.sh nginx
    
    # Filter with summary
    ./podman-network-audit.sh nginx --summary
    
* * *

Sample Output
-------------

Here's example output from a server running multiple containers:

    Status Container                Network      Listeners
    --------------------------------------------------------------------------------
    [6] audiobookshelf             pasta        :::80 (80/tcp->13378)
    [4] airspy                     bridge       0.0.0.0:30005 0.0.0.0:80 (30005/tcp->)
    [D] bentopdf                   pasta        0.0.0.0:8080 :::8080 (8080/tcp->8084)
    [6] syncthing                  pasta        :::22000 :::8384 (4 ports published)
    [D] immich-redis               bridge       0.0.0.0:6379 :::6379 (6379/tcp->)
    [D] omnitools                  pasta        0.0.0.0:8999 :::8999 (80/tcp->)
    [6] homepage                   pasta        :::3000 (3000/tcp->3000)
    [D] vert                       pasta        0.0.0.0:80 :::80 (80/tcp->3123)
    [6] convertx                   pasta        :::3000 (3000/tcp->3002)
    [D] calibre-gui                pasta        0.0.0.0:8082 0.0.0.0:8080 0.0.0.0:8181 :::8080
                                               :::8181 (3000/tcp->)
    [6] uptime-kuma                pasta        :::3001 (3001/tcp->3001)
    [6] tdarr                      pasta        :::8265 :::8266 (8265/tcp->8265 8266/tcp->8266
                                               8267/tcp->8267)
    [D] stirlingpdf                pasta        127.0.0.1:2004 127.0.0.1:2003 :::8080
                                               (8080/tcp->8180)
    [6] immich-machine-learning   bridge       :::3003
    [D] ente-database             bridge       0.0.0.0:5432 :::5432 (5432/tcp->)
    [D] paperless-webserver       pasta        0.0.0.0:6379 :::8000 :::6379 (8000/tcp->8000)
    [D] ultrafeeder               bridge       0.0.0.0:31003 0.0.0.0:31005 0.0.0.0:31004
                                              0.0.0.0:31006 0.0.0.0:32007 0.0.0.0:32006
                                              0.0.0.0:32009 0.0.0.0:32008 0.0.0.0:30001
                                              0.0.0.0:30003 0.0.0.0:30002 0.0.0.0:30005
                                              0.0.0.0:30004 0.0.0.0:30006 0.0.0.0:30047
                                              0.0.0.0:30104 0.0.0.0:30152 0.0.0.0:8081 :::31003
                                              :::31005 :::31004 :::31006 :::32007 :::32006
                                              :::32009 :::32008 :::30001 :::30003 :::30002
                                              :::30005 :::30004 :::30006 :::30047 :::30104
                                              :::30152 :::39001 :::39000 :::39003 :::39002
                                              :::39005 :::39004 :::39006 :::39008 :::8081
                                              (30003/tcp->30003 30005/tcp->30005 80/tcp->)
    [D] paperless-redis           container   0.0.0.0:6379 :::8000 :::6379 (8000/tcp->8000)
    [6] calibre-web               pasta        :::8083 (8083/tcp->8091)
    [✗] opensky                   bridge       No listeners
    [6] fr24                      bridge       :::8754 (30003/tcp->)
    [D] radarvirtuel              bridge       0.0.0.0:30005 :::30005
    [4] pfclient                  bridge       0.0.0.0:30054 0.0.0.0:30053 (30053/tcp->30053
                                              30054/tcp->)
    [D] rbfeeder                  bridge       0.0.0.0:32457 0.0.0.0:32458 0.0.0.0:32459
                                              0.0.0.0:32088 0.0.0.0:32004 0.0.0.0:32008
                                              :::32457 :::32458 :::32459 :::32004 :::32008
                                              (30105/tcp->)
    [✗] adsbhub                   bridge       No listeners
    [6] immich-server             bridge       :::34019 :::2283 (2283/tcp->2283)
    [D] piaware                   bridge       0.0.0.0:30005 0.0.0.0:30004 0.0.0.0:30001
                                              0.0.0.0:30003 0.0.0.0:30002 0.0.0.0:30104
                                              0.0.0.0:8978 0.0.0.0:80 0.0.0.0:8080 :::30105
                                              :::30106 (30003/tcp->)
    [D] planewatch                bridge       127.0.0.1:12346 :::30105
    [6] ente-museum               bridge       :::2112 :::8080 (8080/tcp->8085)
    [D] ente-web                  bridge       0.0.0.0:3009 0.0.0.0:3008 0.0.0.0:3010
                                              0.0.0.0:3005 0.0.0.0:3004 0.0.0.0:3006
                                              0.0.0.0:3001 0.0.0.0:3000 0.0.0.0:3003
                                              0.0.0.0:3002 :::3009 :::3008 :::3010 :::3005
                                              :::3004 :::3006 :::3001 :::3000 :::3003 :::3002
                                              (3000/tcp->)
    [D] plex                      pasta        127.0.0.1:46333 127.0.0.1:32600 127.0.0.1:32401
                                              :::8181 :::32400 (1900/udp->)
    [6] immich-public-proxy       bridge       :::3000 (3000/tcp->3003)
    [6] minuspod                  pasta        :::8000 (8000/tcp->9998)
    [D] immich-postgres           bridge       0.0.0.0:5432 :::5432 (5432/tcp->)
    [D] tautulli                  container    127.0.0.1:46333 127.0.0.1:32600 127.0.0.1:32401
                                              :::8181 :::32400 (32400/tcp->32400 8181/tcp->8181)
    
* * *

Summary Mode Example
--------------------

    $ ./podman-network-audit.sh --summary
    
    === Summary ===
    Dual-Stack:  15
    IPv6-Only:   12
    IPv4-Only:   2
    No Listeners: 2
    Errors:      0
    
    IPv6 Capable: 93% of running containers
    
* * *

Tips & Tricks
-------------

### Quick IPv6 Readiness Check

    # Check how many containers support IPv6
    ./podman-network-audit.sh --summary | grep "IPv6 Capable"
    

### Monitor Specific Container

    # Watch a container's network status
    watch -n 5 './podman-network-audit.sh my-container'
    

### Export for Reporting

    # Save output without colors
    ./podman-network-audit.sh | sed 's/\x1b\[[0-9;]*m//g' > audit-report.txt

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

* * *

License
-------

This project is licensed under the GNU General Public License v3.0 - see the LICENSE file for details.

* * *

Author
------

Maintained by the community. For questions, suggestions, or improvements, please open an issue or submit a pull request.
