#!/bin/bash
set -e

echo "=== Home Server Setup Script ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}❌ Don't run this as root. Run as your regular user.${NC}"
    exit 1
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env file not found!${NC}"
    echo ""
    echo "Creating .env from template..."
    cp env.example .env
    echo ""
    echo -e "${YELLOW}📝 Please edit .env file with your credentials:${NC}"
    echo "   nano .env"
    echo ""
    echo "Required:"
    echo "  - NORDVPN_USER and NORDVPN_PASSWORD"
    echo "  - DUCKDNS_TOKEN (if using DuckDNS)"
    echo ""
    read -p "Press Enter after editing .env file..."
fi

# Create required directories
echo -e "${GREEN}📁 Creating directory structure...${NC}"
sudo mkdir -p /srv/{plex,wireguard,gluetun,qbittorrent,downloads}
sudo mkdir -p /mnt/media/{Movies,TV\ Shows,Music}

# Set ownership
echo -e "${GREEN}🔐 Setting permissions...${NC}"
sudo chown -R $USER:$USER /srv/plex /srv/wireguard /srv/gluetun /srv/qbittorrent /srv/downloads
sudo chown -R $USER:$USER /mnt/media

# Create symlink for media
if [ ! -L "/srv/media" ]; then
    echo -e "${GREEN}🔗 Creating media symlink...${NC}"
    sudo ln -s /mnt/media /srv/media
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}🐳 Docker not found. Installing...${NC}"
    sudo apt update
    sudo apt install -y docker.io
    sudo systemctl enable --now docker
    sudo usermod -aG docker $USER
    echo ""
    echo -e "${YELLOW}⚠️  You need to logout and login again for Docker permissions to take effect.${NC}"
    echo "After logging back in, run this script again."
    exit 0
fi

# Check if user is in docker group
if ! groups | grep -q docker; then
    echo -e "${YELLOW}⚠️  Adding user to docker group...${NC}"
    sudo usermod -aG docker $USER
    echo ""
    echo -e "${YELLOW}⚠️  You need to logout and login again for Docker permissions to take effect.${NC}"
    echo "After logging back in, run this script again."
    exit 0
fi

# Stop any existing containers
echo -e "${GREEN}🛑 Stopping existing containers...${NC}"
docker compose down 2>/dev/null || true

# Pull latest images
echo -e "${GREEN}📥 Pulling Docker images...${NC}"
docker compose pull

# Start services
echo -e "${GREEN}🚀 Starting services...${NC}"
docker compose up -d

# Wait for services to start
echo -e "${GREEN}⏳ Waiting for services to initialize...${NC}"
sleep 10

# Check status
echo ""
echo -e "${GREEN}📊 Service Status:${NC}"
docker compose ps

echo ""
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo ""
echo "Access your services:"
echo "  - Plex:        http://$(hostname -I | awk '{print $1}'):32400/web"
echo "  - qBittorrent: http://$(hostname -I | awk '{print $1}'):8080"
echo "  - Portainer:   http://$(hostname -I | awk '{print $1}'):9000"
echo ""
echo "Check VPN status:"
echo "  docker logs gluetun --tail 20"
echo ""
echo "View all logs:"
echo "  docker compose logs -f"
echo ""
