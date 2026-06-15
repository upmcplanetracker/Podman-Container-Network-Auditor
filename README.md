# Podman Container Network Auditor

A lightweight, dependency-free shell script to audit running container network stacks for IPv6, Dual-Stack, and IPv4-only listeners.

## What it does
This script iterates through all running containers (Podman or Docker) and inspects their `/proc/net/tcp` and `/proc/net/tcp6` files. It identifies which containers are listening on ports and classifies them by their networking capability.

## Understanding the Output
The script provides a color-coded status for each container:

| Status | Meaning |
| :--- | :--- |
| **[D]** | **Dual-Stack:** The container is listening on both IPv4 and IPv6. |
| **[6]** | **IPv6-Only:** The container is listening only on IPv6. |
| **[4]** | **IPv4-Only:** The container is listening only on IPv4. |
| **[✗]** | **No listeners:** The container is running but has no open ports (likely an outbound-only client). |
| **[!]** | **Access Denied:** The container's security profile prevents access to `/proc/net`. |

*Note: For `[4]` status, the script also displays the **PIDs** of the processes binding to those ports to help with debugging.*

## What it doesn't do
* **It is not an external network scanner:** It does not test connectivity from the *outside*. It checks the container's internal socket state.
* **It does not modify configurations:** It is a read-only auditing tool.
* **It cannot see inside restricted containers:** Containers with hardened security profiles (like some versions of Portainer) may block access to the `/proc` filesystem.

## Usage

### Prerequisites
* The script requires `awk`, `sed`, and `xargs` (standard on almost all Linux distributions).

### Running with Podman
* Download the `audit_net.sh` script.
* Make it executable via `chmod +x /path/to/your/script/audit_net.sh`
* Find what directories are in your path via `echo $PATH`
* Move the script to whatever directory you want via `mv /path/to/your/script/audit_net.sh /path/to/new/home/audit_net.sh`
* By default, the script looks for `podman`. If you want to audit your **rootless/user** containers, run it as your standard user: `./audit_net.sh`
* If you want to audit your **rootful/system** containers, run it with sudo: `sudo ./audit_net.sh`

### Sample Output
This is from my server running lots of rootless containers:
```
Status    Container		Details
------------------------------------------------------------
[4] airspy: IPv4-Only on: 80, 30005 (PIDs: 39348, 41990)
[6] syncthing: IPv6-Only on: 22000, 8384
[6] audiobookshelf: IPv6-Only on: 80
[D] vert: Dual-Stack on: 80
[6] uptime-kuma: IPv6-Only on: 3001
[!] portainer: No network stack accessible
[D] calibre-gui: Dual-Stack on: 8181, 8080
[6] tdarr: IPv6-Only on: 8265, 8266
[D] omnitools: Dual-Stack on: 8999
[6] immich-machine-learning: IPv6-Only on: 3003
[6] homepage: IPv6-Only on: 3000
[D] paperless-webserver: Dual-Stack on: 8000, 6379
[D] stirlingpdf: Dual-Stack on: 8080
[6] calibre-web: IPv6-Only on: 8083
[D] plex: Dual-Stack on: 8181, 32400
[D] paperless-redis: Dual-Stack on: 8000, 6379
[D] ente-database: Dual-Stack on: 5432
[D] immich-postgres: Dual-Stack on: 5432
[D] immich-redis: Dual-Stack on: 6379
[6] convertx: IPv6-Only on: 3000
[D] bentopdf: Dual-Stack on: 8080
[6] immich-server: IPv6-Only on: 2283, 39961
[D] tautulli: Dual-Stack on: 8181, 32400
[6] minuspod: IPv6-Only on: 8000
[6] ente-museum: IPv6-Only on: 8080, 2112
[D] ente-web: Dual-Stack on: 3003, 3002, 3001, 3000, 3006, 3005, 3004, 3010, 3009, 3008
[D] ultrafeeder: Dual-Stack on: 31005, 31004, 31006, 31003, 32007, 32006, 32009, 32008, 30047, 30005, 30004, 30006, 30001, 30003, 30002, 30152, 30104, 39008, 39005, 39004, 39006, 39001, 39000, 39003, 39002, 8081
[6] fr24: IPv6-Only on: 8754
[✗] adsbhub: No listeners (Client/Outbound only)
[✗] opensky: No listeners (Client/Outbound only)
[D] piaware: Dual-Stack on: 30106, 30105
[4] pfclient: IPv4-Only on: 30053, 30054 (PIDs: 2307779, 2353186)
[D] radarvirtuel: Dual-Stack on: 30005
[D] planewatch: Dual-Stack on: 30105
[D] rbfeeder: Dual-Stack on: 32004, 32008, 32457, 32458, 32459
[6] immich-public-proxy: IPv6-Only on: 3000
[6] immich-googlephotos: IPv6-Only on: 8087
```

## Miscellaneous

### License
This is free to use under the GNU public license.

### Improvments, Comments, Questions, etc.
Submit a PR or issue. I'm always open to ideas.
