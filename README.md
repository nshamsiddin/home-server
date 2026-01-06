# Home Server - Docker Compose Setup

Production-grade home server setup with Docker Compose. Everything is version-controlled and reproducible.

## 🚀 Quick Start

### First Time Setup

1. **Clone this repository** on your server:
```bash
cd ~
git clone <your-repo-url> home-server
cd home-server
```

2. **Configure your credentials**:
```bash
cp env.example .env
nano .env
```

Fill in:
- `NORDVPN_USER` and `NORDVPN_PASSWORD` from https://my.nordaccount.com/dashboard/nordvpn/manual-configuration/
- `DUCKDNS_TOKEN` from https://www.duckdns.org/ (optional)

3. **Run setup**:
```bash
chmod +x setup.sh
./setup.sh
```

That's it! All services will start automatically.

### Existing Setup

```bash
cd ~/home-server
git pull
docker compose up -d
```

## 📦 Services

| Service | Port | Purpose |
|---------|------|---------|
| **Plex** | 32400 | Media server with hardware transcoding |
| **qBittorrent** | 8080 | Torrent client (VPN kill-switch enabled) |
| **Gluetun** | - | VPN client (NordVPN) |
| **WireGuard** | 51820 | VPN server for remote access |
| **DuckDNS** | - | Dynamic DNS updater |
| **Portainer** | 9000 | Docker management UI |

## 🌐 Access

- **Plex**: `http://YOUR_SERVER_IP:32400/web`
- **qBittorrent**: `http://YOUR_SERVER_IP:8080`
- **Portainer**: `http://YOUR_SERVER_IP:9000`

## 🔒 Security Features

✅ **VPN Kill-Switch**: qBittorrent shares Gluetun's network - if VPN drops, torrents stop  
✅ **Zero IP Leaks**: Container network isolation at kernel level  
✅ **Hardware Transcoding**: Intel Quick Sync for efficient Plex streaming  
✅ **Remote Access**: WireGuard VPN for secure access from anywhere  

## 📊 Management Commands

```bash
# View all service status
docker compose ps

# View logs
docker compose logs -f

# View specific service logs
docker compose logs -f gluetun
docker compose logs -f qbittorrent

# Restart all services
docker compose restart

# Restart specific service
docker compose restart plex

# Stop all services
docker compose down

# Update all services
docker compose pull
docker compose up -d

# Check VPN IP
docker exec gluetun wget -qO- https://ipinfo.io/json
```

## 🛠️ Troubleshooting

**VPN not connecting:**
```bash
docker compose logs gluetun
# Check credentials in .env file
```

**qBittorrent can't access internet:**
```bash
# Restart VPN first, then qBittorrent
docker compose restart gluetun
sleep 10
docker compose restart qbittorrent
```

**Services not starting after reboot:**
```bash
# All services have restart: unless-stopped
# They should auto-start. If not:
docker compose up -d
```

## 📁 Directory Structure

```
/srv/
├── plex/           # Plex config (BACKUP THIS)
├── wireguard/      # WireGuard config (BACKUP THIS)
├── gluetun/        # Gluetun config
├── qbittorrent/    # qBittorrent config
├── downloads/      # Temporary downloads
└── media/          # Symlink to /mnt/media

/mnt/media/         # 1TB HDD
├── Movies/
├── TV Shows/
└── Music/
```

## 🔄 Backup & Restore

**What to backup:**
- `/srv/plex` - Plex database and settings
- `/srv/wireguard` - WireGuard keys and configs
- `.env` file - Your credentials (store securely!)

**Restore:**
```bash
# Copy backed up files to /srv/
# Run setup again
./setup.sh
```

## 📚 Documentation

See `runbook.md` for detailed hardware setup and troubleshooting.


