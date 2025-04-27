# WireGuard VPN with UDP2RAW (Obfuscation) - Fedora Edition

This project sets up a WireGuard VPN server protected by UDP2RAW to obfuscate the VPN traffic and bypass firewalls.

## Features
- WireGuard VPN server (dockerized)
- UDP2RAW server (dockerized) to bypass DPI/firewall
- Automatically deployable on Fedora
- Simple setup with a single script
- Client-side instructions included

## Requirements
- Fedora 38+ (or any recent Fedora) on server
- Linux, macOS, or Windows on client
- Root or sudo access
- Docker (auto-installed if missing on server)

## Installation on the Server

Clone this repository and run the setup script:

```bash
git clone https://github.com/sametcatakli/wireguard-tcp.git
cd wireguard-tcp
bash setup.sh
```

This will:
- Install Docker if missing
- Set up WireGuard and UDP2RAW with Docker Compose
- Generate WireGuard keys and client config

## Configuration

The main configuration parameters are inside the `setup.sh` file:

- `SERVER_PUBLIC_IP` — set this to your server's public IP address.
- `PASSWORD` — choose a strong shared password between the client and the server.
- `WIREGUARD_PORT` — internal WireGuard port (default: `51820`).
- `UDP2RAW_PORT` — external obfuscated port (default: `4096`).

After deployment, your WireGuard client configuration file will be located at:

```bash
~/wireguard-tcp/config/peer1/peer1.conf
```

Import it into your WireGuard app to connect.

## Client-Side Setup

You also need to tunnel your client's WireGuard traffic through UDP2RAW.

### Requirements

- Docker installed on your client machine
- WireGuard installed (CLI or GUI app)

### Running UDP2RAW Client

On your client machine, start the UDP2RAW client like this:

```bash
docker run --rm --network host ghcr.io/synox/docker-udp2raw \
  -c \
  -l127.0.0.1:51820 \
  -r<your_server_ip>:4096 \
  --raw-mode faketcp \
  --cipher-mode xor \
  --auth-mode simple \
  -k "your_secure_password"
```

Explanation:
- `-l127.0.0.1:51820` listens locally for WireGuard
- `-r<your_server_ip>:4096` connects to your server
- `-k "your_secure_password"` must match the server password
- `--raw-mode faketcp` makes the traffic look like regular TCP

### WireGuard Client Configuration

Edit your WireGuard client configuration (`peer1.conf`) and set:

```
[Peer]
Endpoint = 127.0.0.1:51820
```

This way, your WireGuard app connects **locally** to the udp2raw tunnel, which then connects to the server.

Then simply activate your WireGuard tunnel!

## How It Works

```
[ Client WireGuard App ] --(UDP)--> [ Local UDP2RAW Client ] --(FakeTCP)--> [ UDP2RAW Server ] --(UDP)--> [ WireGuard Server ]
```

- **UDP2RAW client** disguises your WireGuard UDP packets to bypass restrictive networks
- **UDP2RAW server** receives and restores the original WireGuard traffic

## Management Commands

On the server:

```bash
# Start the VPN server
sudo docker compose up -d

# Stop the VPN server
sudo docker compose down

# View logs
sudo docker compose logs -f
```

On the client:

```bash
# Start UDP2RAW client (replace with your server IP)
docker run --rm --network host ghcr.io/synox/docker-udp2raw \
  -c -l127.0.0.1:51820 -r<your_server_ip>:4096 --raw-mode faketcp --cipher-mode xor --auth-mode simple -k "your_secure_password"
```

WireGuard must be started **after** udp2raw is running.

## Notes

- UDP2RAW supports different obfuscation modes (`faketcp`, `icmp`, etc.) — currently using `faketcp`.
- The setup script automatically installs Docker if missing.
- You can change obfuscation settings by editing the `docker-compose.yml` or udp2raw client command.

## License

MIT License
