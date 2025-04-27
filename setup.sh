#!/bin/bash

set -e

# --- Configuration ---
WIREGUARD_PORT=51820
UDP2RAW_PORT=4096
PASSWORD="your_secure_password"
SERVER_PUBLIC_IP="your.server.ip"

# --- Installation of Docker if not present ---
if ! command -v docker &> /dev/null
then
    echo "Docker not found. Installing Docker..."
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo systemctl enable --now docker
fi

# --- Create project directory ---
mkdir -p ~/wireguard-udp2raw
cd ~/wireguard-udp2raw

# --- Write docker-compose.yml ---
cat > docker-compose.yml <<EOF
version: '3.8'

services:
  udp2raw-server:
    image: ghcr.io/synox/docker-udp2raw:latest
    container_name: udp2raw-server
    restart: unless-stopped
    network_mode: "host"
    command: >
      -s
      -l0.0.0.0:${UDP2RAW_PORT}
      -r127.0.0.1:${WIREGUARD_PORT}
      --raw-mode faketcp
      --cipher-mode xor
      --auth-mode simple
      -k "${PASSWORD}"
    cap_add:
      - NET_ADMIN

  wireguard:
    image: linuxserver/wireguard
    container_name: wireguard
    restart: unless-stopped
    network_mode: "host"
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      - PUID=1000
      - PGID=1000
      - SERVERURL=${SERVER_PUBLIC_IP}
      - SERVERPORT=${WIREGUARD_PORT}
      - PEERS=1
      - PEERDNS=auto
      - INTERNAL_SUBNET=10.13.13.0
    volumes:
      - ./config:/config
      - /lib/modules:/lib/modules
EOF

echo "Docker Compose file created."

echo "Starting containers..."
sudo docker compose up -d

echo "Setup complete!"
echo "Check ~/wireguard-udp2raw/config/peer1/peer1.conf for your WireGuard client config."
