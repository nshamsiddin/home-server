
Home Server Setup – Reproducible Architecture

⚠️ **This runbook is for reference only. For actual deployment, use Docker Compose setup in README.md**

Hardware
	•	HP EliteDesk 800 G2
	•	CPU: i7-6700
	•	GPU: Intel HD Graphics 530 (iGPU only)
	•	Discrete GPU: DO NOT USE
	•	GT 730 / OEM NVIDIA cards break UEFI, Secure Boot, WoL
	•	Remove permanently

⸻

1. Firmware / BIOS (Critical)

Required BIOS settings

Boot Mode:           UEFI ONLY
Legacy Support:      DISABLED
Secure Boot:         DISABLED  (do not re-enable)
PXE / Network Boot:  ENABLED but harmless (cannot be removed on G2 with WoL)
PXE Wait Time:       0 seconds
Boot Order:          OS Boot Manager first

Wake-on-LAN (WoL)
	•	Enabled in BIOS
	•	Accept that PXE flashes briefly (HP firmware quirk)
	•	This is expected and harmless

⚠️ Reality
EliteDesk G2 firmware will always re-enable PXE when WoL is active.
You cannot fix this — only neutralize it.

⸻

2. Operating System

OS
	•	Debian 13 (trixie)
	•	Minimal install
	•	No desktop environment

Networking
	•	Interface: eno1
	•	DHCP enabled
	•	Static IP via router DHCP reservation (recommended)

⸻

3. DNS (Critical – Router DNS is broken)

Do not use router DNS.

/etc/resolv.conf

nameserver 1.1.1.1
nameserver 8.8.8.8

Prevent DHCP from overwriting DNS

/etc/dhcpcd.conf

nohook resolv.conf

Restart:

sudo systemctl restart dhcpcd


⸻

4. Docker (Debian-native)

Install Docker

sudo apt update
sudo apt install -y docker.io docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker shams
# logout/login required

Verify:

docker run hello-world


⸻

5. Directory Layout (Data is Sacred)

/srv
├── media        # Plex media
├── plex         # Plex config (BACKUP THIS)
├── wireguard    # WireGuard config (BACKUP THIS)
├── gluetun      # VPN client config
├── qbittorrent  # Torrent client config
├── downloads    # Torrent data
└── backups      # Optional

Create:

sudo mkdir -p /srv/{media,plex,wireguard,gluetun,qbittorrent,downloads,backups}
sudo chown -R shams:shams /srv


⸻

6. Docker Management UI (Portainer)

docker volume create portainer_data

docker run -d \
  --name portainer \
  --restart unless-stopped \
  -p 9000:9000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce

Access:

http://SERVER_IP:9000

Mobile-friendly. Safe on LAN or via VPN only.

⸻

7. Plex (Docker, Intel iGPU)

docker run -d \
  --name plex \
  --restart unless-stopped \
  --network host \
  --device /dev/dri:/dev/dri \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Europe/Dublin \
  -v /srv/plex:/config \
  -v /srv/media:/media \
  plexinc/pms-docker

Notes:
	•	Uses Intel Quick Sync
	•	Hardware transcoding requires Plex Pass
	•	Discrete GPU is unnecessary and harmful

⸻

8. Dynamic DNS (DuckDNS)

DuckDNS updater (Docker)

docker run -d \
  --name duckdns \
  --restart unless-stopped \
  -e SUBDOMAINS=nshamsiddin \
  -e TOKEN=YOUR_DUCKDNS_TOKEN \
  lscr.io/linuxserver/duckdns

Verify:

dig nshamsiddin.duckdns.org @1.1.1.1

⚠️ ping is unreliable for DuckDNS — ignore ICMP failures.

⸻

9. WireGuard (Server – Docker)

Container

docker run -d \
  --name wireguard \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Europe/Dublin \
  -e SERVERURL=nshamsiddin.duckdns.org \
  -e SERVERPORT=51820 \
  -e PEERS=phone,laptop \
  -e PEERDNS=auto \
  -e INTERNAL_SUBNET=10.13.13.0 \
  -p 51820:51820/udp \
  -v /srv/wireguard:/config \
  -v /lib/modules:/lib/modules \
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
  --restart unless-stopped \
  lscr.io/linuxserver/wireguard

Router
	•	Port forward UDP 51820 → SERVER_IP:51820

⸻

10. WireGuard Clients (Important Concepts)

AllowedIPs (Server side)

10.13.13.2/32
10.13.13.3/32

This is:
	•	identity
	•	routing
	•	security
	•	not a firewall rule

Correct and intentional.

Client config

Edit peer_*.conf under /srv/wireguard:

Endpoint = nshamsiddin.duckdns.org:51820
PersistentKeepalive = 25

Import to phone via:

docker exec -it wireguard /app/show-peer phone


⸻

11. Torrent Client with VPN Kill-Switch (NordVPN)

Prerequisites
	•	NordVPN subscription active
	•	Service credentials: https://my.nordaccount.com/dashboard/nordvpn/manual-configuration/

Setup (Automated)

chmod +x setup-nordvpn.sh
./setup-nordvpn.sh

Check Status

./check-vpn.sh

Stop Services

./stop-vpn.sh

Access
	•	qBittorrent Web UI: http://SERVER_IP:8080
	•	Default login: admin / adminadmin (change immediately)

Architecture
	•	Gluetun: VPN client connected to NordVPN
	•	qBittorrent: Shares Gluetun's network namespace
	•	Guarantee: No VPN → no torrent traffic

⸻

12. Testing & Verification

Docker

docker ps

WireGuard

docker exec -it wireguard wg show

Look for:

latest handshake: X seconds ago

VPN Status

./check-vpn.sh

⸻

13. Backup Policy (Minimal but Correct)

Back up only:

/srv/plex
/srv/wireguard

Media is replaceable. Config is not.

⸻

14. Known Non-Fixable Truths
	•	HP EliteDesk G2 + WoL → PXE will always reappear
	•	GT 730 / OEM NVIDIA GPUs break UEFI
	•	Secure Boot should never be re-enabled
	•	Router DNS is unreliable
	•	ping is not a DNS test
	•	WireGuard AllowedIPs is routing + identity

⸻

Mental Model (Final)
	•	Host OS: boring, minimal
	•	Docker: isolation layer
	•	Portainer: control plane
	•	Plex: media service
	•	WireGuard: secure access to home
	•	Gluetun: secure access from home
	•	qBittorrent: jailed inside VPN
	•	DDNS: no static IP required
