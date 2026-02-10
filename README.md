# WireGuard NAT Tunnel

Deploy a VPN server at any remote location and access it from anywhere, without worrying about NAT, firewalls, or port forwarding.

---

## The Problem

You want to run a VPN server somewhere behind a NAT/firewall (home network, friend's house, remote office), but you can't configure port forwarding. Maybe you don't have access to the router, maybe the ISP uses CGNAT, or maybe you just don't want to mess with firewall rules at every location you deploy.

Traditional VPN setups require you to:
- Open inbound ports on the VPN server's firewall
- Configure port forwarding on the router
- Have a static IP or dynamic DNS
- Deal with ISP restrictions

This is a pain when you're deploying VPNs at multiple locations, especially if you don't control the network infrastructure.

## The Solution

This project uses **reverse tunneling** to flip the problem around. Instead of clients connecting directly to your VPN server (which might be impossible), they connect to a relay server with a public IP. The VPN server initiates an outbound WireGuard tunnel to the relay, which then forwards traffic.

**What this means:**
- VPN server only makes outbound connections (works through any firewall)
- No port forwarding needed at the VPN server location
- Relay server has a stable hostname that clients always connect to
- Move your VPN server anywhere with internet access - it just works

### Perfect For

- **Home network access** - Deploy at home, access your network while traveling
- **Remote offices** - Drop a VPN server at a client site without touching their network
- **Multiple locations** - Run VPN servers in different cities/countries for regional internet access
- **IoT/Lab networks** - Secure access to isolated networks behind restrictive firewalls
- **Quick deployments** - Pre-configure a device, ship it, and it connects automatically when plugged in

---

## 🏗️ How It Works

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    YOUR PHONE (Anywhere)                    │
│                   "I want VPN from Tokyo"                   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ Connects to relay.example.com:51820
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              RELAY SERVER (VPS - Fixed Location)            │
│                  relay.example.com (Public IP)              │
│                                                              │
│  Ports open (configurable):                                 │
│  • 51820/UDP ← VPN clients connect here                     │
│  • 51821/UDP ← VPN server tunnel connects here              │
│  • 2222/TCP  ← SSH to VPN server (optional)                 │
│                                                              │
│  • Forwards VPN traffic via socat                           │
│  • Forwards SSH via iptables DNAT                           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ WireGuard Tunnel (REVERSE CONNECTION)
                         │ VPN Server → Relay (outbound only!)
                         │ Tunnel IPs: 10.9.0.1 ↔ 10.9.0.2
                         ↓
┌─────────────────────────────────────────────────────────────┐
│         VPN SERVER (Physically at Target Location)          │
│              Tokyo Office (Behind Router/NAT)               │
│                                                              │
│  NO inbound ports needed!                                   │
│  • Initiates tunnel to relay (outbound only)                │
│  • Runs WireGuard VPN for clients                           │
│  • Provides internet access from THIS location              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ NAT Masquerade - traffic exits here
                         ↓
                  🌍 Internet (Tokyo IP)
```

### Key Concepts

**Reverse Tunnel:** The VPN server initiates an outbound WireGuard tunnel to the relay. This means the VPN server doesn't need any inbound ports open - it just needs to reach the internet. The tunnel stays open with persistent keepalives.

**Fixed Relay:** You set up one relay server with a stable public IP/hostname. This could be a cheap VPS anywhere. Clients (phones, laptops) always connect to this relay.

**Mobile VPN Server:** The actual VPN server that provides internet access can be anywhere - behind NAT, behind a firewall, on different networks. It automatically connects back to the relay via the tunnel.

**Traffic Flow:** Client → Relay (port 51820) → Tunnel → VPN Server → Internet. The relay just forwards traffic; the VPN server does all the actual VPN work.

### Traffic Flow Example

**When you browse from your phone:**
1. Phone → `relay.example.com:51820` (VPN connection)
2. Relay → Forwards via WireGuard tunnel to VPN server
3. VPN Server (Tokyo) → Masquerades traffic to internet
4. Internet sees request from Tokyo IP
5. Response follows reverse path back to your phone

**Result:** You browse internet as if you're in Tokyo!

---

## Features

- **No port forwarding needed** - VPN server only makes outbound connections
- **Deploy anywhere** - Works through NAT, firewalls, CGNAT, everything
- **Stable endpoint** - Clients always connect to the same relay hostname
- **Location-based internet access** - Browse as if you're wherever the VPN server is
- **Auto-reconnect** - PersistentKeepalive keeps the tunnel alive
- **Dynamic interface detection** - Works with eth0, wlan0, or whatever interface you have
- **SSH access** - Reach your VPN server via the relay (port 2222)
- **Simple setup** - Two scripts, one config file, done in 5 minutes
- **Production ready** - Systemd services, auto-start on boot

---

## Use Cases

**Remote office access:** Ship a pre-configured VPN server to a client site. They plug it in, it connects back to your relay, and you can access their network without touching their router or firewall.

**Multi-location internet:** Deploy VPN servers in different cities or countries. Route your traffic through whichever location you need. Same relay, multiple VPN servers.

**Home network while traveling:** Access your home network, NAS, security cameras, etc. from anywhere without port forwarding or exposing services to the internet.

**Site-to-site VPN:** Connect two offices without firewall changes. Drop a VPN server at the remote site, it tunnels back, done.

**IoT/Lab access:** Get into isolated networks that have strict inbound firewall rules. Outbound connections usually work fine.

---

## Prerequisites

**Relay server:** Any VPS with a public IP (DigitalOcean, AWS, etc.). Needs Ubuntu/Debian and root access.

**Important - Ports on relay server:**

These ports (or whatever you configure in `config.sh`) must be open/forwarded to your relay server:
- **51820/UDP** (default `WIREGUARD_PORT`) - VPN clients connect here
- **51821/UDP** (default `WIREGUARD_TUNNEL_PORT`) - VPN server tunnel connects here
- **2222/TCP** (default `SSH_FORWARD_PORT`) - SSH to VPN server (optional)

**How to open ports:**
- If relay is behind a router: Configure port forwarding on the router
- If relay is a VPS: Open ports in firewall/security group settings
- If using UFW: The setup script handles this automatically

**VPN server:** Any Ubuntu/Debian machine (Raspberry Pi works great). Can be behind NAT/firewall. Just needs internet access. **No inbound ports or port forwarding required** - it only makes outbound connections.

**Your computer:** For running setup scripts and generating configs.

---

## Quick Start

### 1. Clone and configure

```bash
git clone https://github.com/nandanprakash/wireguard-nat-tunnel.git
cd wireguard-nat-tunnel
nano config.sh
```

Change these two lines in `config.sh`:
```bash
RELAY_DOMAIN="your-relay-server.com"
SSH_PASSWORD="YourSecurePassword"
```

### 2. Setup relay server

```bash
scp config.sh relay-wireguard-setup.sh user@relay-server:/tmp/
ssh user@relay-server
cd /tmp && sudo bash relay-wireguard-setup.sh
```

Copy the relay public key that's displayed at the end.

### 3. Setup VPN server

```bash
scp config.sh pi-wireguard-tunnel-setup.sh user@vpn-server:/tmp/
ssh user@vpn-server
cd /tmp && sudo bash pi-wireguard-tunnel-setup.sh
```

When prompted, paste the relay public key. Copy the VPN server public key that's displayed at the end.

### 4. Connect them

```bash
ssh user@relay-server
VPN_KEY="<paste_vpn_server_public_key>"
sudo sed -i "s/PLACEHOLDER_PI_PUBLIC_KEY/$VPN_KEY/" /etc/wireguard/wg-tunnel.conf
sudo systemctl restart wg-quick@wg-tunnel
sudo wg show wg-tunnel  # Should show recent handshake
```

### 5. Generate client config

```bash
ssh user@vpn-server
./generate-phone-qr.sh  # Scan with WireGuard app
```

---

## Connecting Clients

**Mobile (iOS/Android):**
1. Install WireGuard app
2. Scan QR code from `generate-phone-qr.sh`
3. Toggle ON

**Desktop (Windows/Mac/Linux):**
1. Install WireGuard
2. Import the generated config file
3. Connect

Clients connect to `your-relay-server.com:<WIREGUARD_PORT>` (default port 51820)

---

## Configuration

Edit `config.sh` before running the setup scripts. **Required changes:**

```bash
RELAY_DOMAIN="vpn.example.com"      # Your relay server's hostname or IP
SSH_PASSWORD="YourSecurePassword"   # Change this!
```

**Optional but common customizations:**

```bash
# Ports (change if defaults are blocked or already in use)
WIREGUARD_PORT="51820"              # VPN client port
WIREGUARD_TUNNEL_PORT="51821"       # Tunnel port
SSH_FORWARD_PORT="2222"             # SSH forwarding port

# Networks (change if they conflict with existing networks)
VPN_NETWORK="10.200.0.0/24"         # VPN client IP range
TUNNEL_NETWORK="10.9.0.0/30"        # Relay↔VPN server tunnel

# DNS servers
VPN_DNS_SERVERS="1.1.1.1, 1.0.0.1"  # Cloudflare instead of Google
```

Check the comments in `config.sh` for all available options.

---

## Management

**Check tunnel status:**
```bash
# On relay
sudo wg show wg-tunnel
sudo systemctl status wireguard-udp-forward

# On VPN server
sudo wg show wg0
sudo wg show wg-tunnel
```

**Restart services:**
```bash
# Relay
sudo systemctl restart wg-quick@wg-tunnel
sudo systemctl restart wireguard-udp-forward

# VPN server
sudo systemctl restart wg-quick@wg0
sudo systemctl restart wg-quick@wg-tunnel
```

**Add more clients:**
```bash
# On VPN server
./generate-phone-qr.sh
```

---

## Troubleshooting

**VPN connects but no internet:**
- Check NAT on VPN server: `sudo iptables -t nat -L POSTROUTING -n -v | grep MASQUERADE`
- Check forwarding rules: `sudo iptables -L FORWARD -n -v | grep wg0`
- Disconnect from any other VPNs (nested VPNs cause routing conflicts)

**Can't connect to VPN:**
- Test if relay is reachable: `nc -zvu your-relay-server.com 51820`
- Check tunnel handshake on relay: `sudo wg show wg-tunnel | grep handshake`
- Verify socat is running on relay: `sudo systemctl status wireguard-udp-forward`

**Can't SSH to VPN server:**
- Try: `ssh -p 2222 user@your-relay-server.com`
- Check DNAT on relay: `sudo iptables -t nat -L PREROUTING -n -v | grep 2222`

**Run the diagnostic script on VPN server:**
```bash
./diagnose-pi-vpn.sh
```

---

## Network Details

**IP ranges:**
- VPN clients: `10.8.0.0/24` (254 clients)
- Tunnel: `10.9.0.0/30` (relay: 10.9.0.1, VPN server: 10.9.0.2)

**Ports on relay (configurable in config.sh):**
- `WIREGUARD_PORT` (default 51820/UDP) - VPN client connections
- `WIREGUARD_TUNNEL_PORT` (default 51821/UDP) - VPN server tunnel
- `SSH_FORWARD_PORT` (default 2222/TCP) - SSH to VPN server

**Services:**
- Relay: `wg-tunnel`, `wireguard-udp-forward`
- VPN server: `wg-tunnel`, `wg0`

---

## Security

- Change the default SSH password in `config.sh` (or better: use SSH keys)
- Configure UFW on both servers to limit exposed ports
- The relay forwards encrypted WireGuard traffic but can see when/how much data flows
- Private keys are never committed to the repository - they're generated during setup
- WireGuard uses modern cryptography (Noise protocol, Curve25519, ChaCha20, Poly1305)

---

## Contributing

Issues and pull requests welcome!

## License

MIT - use it for whatever you want.

## Credits

Built with [WireGuard](https://www.wireguard.com/) and [socat](http://www.dest-unreach.org/socat/).
