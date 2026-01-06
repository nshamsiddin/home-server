# Deployment Guide

## Prerequisites

1. **Fresh Debian 13 (trixie) installation**
2. **SSH access** to the server
3. **1TB HDD mounted** at `/mnt/media`
4. **NordVPN subscription** with service credentials

## Step-by-Step Deployment

### 1. Initial Server Setup

SSH into your server:
```bash
ssh shams@192.168.1.23
```

### 2. Install Git and Docker

```bash
sudo apt update
sudo apt install -y git docker.io docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

**Logout and login again** for Docker permissions to take effect.

### 3. Clone Repository

```bash
cd ~
git clone <your-repo-url> home-server
cd home-server
```

### 4. Configure Environment

```bash
cp env.example .env
nano .env
```

Fill in your credentials:
- `NORDVPN_USER` - From https://my.nordaccount.com/dashboard/nordvpn/manual-configuration/
- `NORDVPN_PASSWORD` - Your NordVPN access token
- `DUCKDNS_TOKEN` - From https://www.duckdns.org/ (optional)
- `DUCKDNS_SUBDOMAIN` - Your subdomain (e.g., `nshamsiddin`)

### 5. Run Setup Script

```bash
chmod +x setup.sh
./setup.sh
```

The script will:
- ✅ Create all required directories
- ✅ Set proper permissions
- ✅ Pull Docker images
- ✅ Start all services

### 6. Verify Deployment

```bash
# Check all services are running
docker-compose ps

# Check VPN connection
docker logs gluetun --tail 20

# Verify VPN IP
docker exec gluetun wget -qO- https://ipinfo.io/json
```

### 7. Access Services

- **Plex**: `http://192.168.1.23:32400/web`
- **qBittorrent**: `http://192.168.1.23:8080`
- **Portainer**: `http://192.168.1.23:9000`

## Post-Deployment Configuration

### Plex Setup

1. Open Plex Web UI
2. Sign in with your Plex account
3. Add libraries:
   - Movies: `/media/Movies`
   - TV Shows: `/media/TV Shows`
   - Music: `/media/Music`

### qBittorrent Setup

1. Open qBittorrent Web UI
2. Login with temporary password from logs:
   ```bash
   docker logs qbittorrent | grep password
   ```
3. Go to Settings → Web UI
4. Change password to something permanent
5. (Optional) Disable authentication for local network:
   - Enable "Bypass authentication for clients on localhost"
   - Add subnet: `192.168.1.0/24`

### WireGuard Setup

Get peer configs:
```bash
docker exec wireguard /app/show-peer phone
docker exec wireguard /app/show-peer laptop
```

Scan QR codes with WireGuard mobile app or copy config for desktop.

## Router Configuration

### Port Forwarding

Forward these ports to your server IP (192.168.1.23):

| Port | Protocol | Service |
|------|----------|---------|
| 51820 | UDP | WireGuard VPN |

### DHCP Reservation

Set static DHCP reservation for your server's MAC address to `192.168.1.23`

## Backup Strategy

### What to Backup

```bash
# On your server
sudo tar -czf backup-$(date +%Y%m%d).tar.gz \
  /srv/plex \
  /srv/wireguard \
  ~/home-server/.env
```

### Restore from Backup

```bash
# Extract backup
sudo tar -xzf backup-YYYYMMDD.tar.gz -C /

# Restart services
cd ~/home-server
docker-compose restart
```

## Updates

### Update All Services

```bash
cd ~/home-server
docker-compose pull
docker-compose up -d
```

### Update Single Service

```bash
docker-compose pull plex
docker-compose up -d plex
```

## Troubleshooting

### Services Not Starting

```bash
# Check logs
docker-compose logs

# Check specific service
docker-compose logs gluetun
```

### VPN Not Connecting

```bash
# Check Gluetun logs
docker logs gluetun --tail 50

# Verify credentials
cat .env | grep NORDVPN
```

### After Reboot

All services should auto-start. If not:
```bash
cd ~/home-server
docker-compose up -d
```

## Monitoring

### Check Service Status

```bash
docker-compose ps
```

### View Real-time Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f gluetun
```

### Check VPN IP

```bash
docker exec gluetun wget -qO- https://ipinfo.io/json
```

Should show NordVPN IP, not your home IP.

## Maintenance

### Clean Up Old Images

```bash
docker system prune -a
```

### Check Disk Usage

```bash
df -h
docker system df
```

### Restart All Services

```bash
docker-compose restart
```
