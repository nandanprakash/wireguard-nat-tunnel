# 🌐 WireGuard NAT Tunnel

**Deploy a VPN server at any remote location and access it from anywhere, without worrying about NAT, firewalls, or port forwarding.**

---

## 🎯 The Problem & Solution

### The Real-World Scenario

You want to access the internet **from a specific location** (home office, remote office, friend's house, IoT network):

1. **Deploy a VPN VM** at that location (behind their router/firewall)
2. **Leave it there** - it connects back to your relay server
3. **Connect from anywhere** - your phone/laptop connects to the relay
4. **Access internet** as if you were physically at that location

### Why This Is Needed

**The Challenge:**
- ❌ VPN server is behind NAT/firewall (no direct access)
- ❌ Can't configure port forwarding (not your router, or ISP CGNAT)
- ❌ Router admin password unknown (office, friend's network)
- ❌ Need to deploy multiple VPN servers at different locations
- ❌ Can't expose VPN server directly to internet

**The Solution: Reverse Tunnel**
- ✅ VPN server **initiates outbound connection** to relay (no inbound ports needed!)
- ✅ Relay has **stable public hostname/IP** (phones always connect here)
- ✅ **Deploy VPN server anywhere** - it automatically connects back
- ✅ **Move VPN server anytime** - just plug it in, it works
- ✅ **No configuration needed** at deployment location

### Perfect For

- 🏠 **Home Office VPN** - Access home network while traveling
- 🏢 **Remote Office Access** - Deploy at client site without network changes
- 🌍 **Multiple Locations** - Deploy VPN servers in different cities/countries
- 🔒 **IoT/Lab Networks** - Secure access to isolated networks
- 🚀 **Quick Deployments** - Ship pre-configured VPN server, plug & play

---

## 🏗️ How It Works

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    YOUR PHONE (Anywhere)                    │
│                   "I want VPN from Tokyo"                   │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ 1. Connects to relay.example.com:51820
                         │    (Your stable, known hostname)
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              RELAY SERVER (VPS - Fixed Location)            │
│                  relay.example.com (Public IP)              │
│  ☁️ aws/digitalocean/gcp                                     │
│                                                              │
│  • Always online, stable hostname                           │
│  • Forwards VPN traffic via socat                           │
│  • Forwards SSH via iptables DNAT                           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ 2. WireGuard Tunnel (REVERSE CONNECTION)
                         │    VPN Server → Relay (outbound only!)
                         │    Relay IP: 10.9.0.1 ↔ VPN IP: 10.9.0.2
                         ↓
┌─────────────────────────────────────────────────────────────┐
│         VPN SERVER (Physically at Target Location)          │
│              Tokyo Office (Behind Router/NAT)               │
│  🏠 Behind firewall, no port forwarding needed               │
│                                                              │
│  • Initiates tunnel to relay (outbound = works anywhere!)  │
│  • Runs WireGuard VPN for clients                           │
│  • Provides internet access from THIS location              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ 3. NAT Masquerade
                         │    Your traffic exits from Tokyo
                         ↓
                  🌍 Internet (Tokyo IP)
```

### Key Concepts

**🔄 Reverse Tunnel (The Secret Sauce):**
- VPN server makes **outbound connection** to relay
- No inbound ports needed on VPN server!
- Works through any NAT/firewall
- VPN server can be anywhere with internet

**📍 Fixed Relay, Mobile VPN:**
- **Relay:** Permanent VPS at fixed location (relay.example.com)
- **VPN Server:** Can be moved anywhere - auto-reconnects to relay
- **Your Phone:** Always connects to same hostname

**🚀 Deployment Workflow:**
1. **Setup once:** Configure relay server with stable hostname
2. **Deploy anywhere:** Move VPN server to target location
3. **Plug in:** VPN server auto-connects to relay via tunnel
4. **Connect:** Phone connects to relay, traffic goes through VPN server

### Traffic Flow Example

**When you browse from your phone:**
1. Phone → `relay.example.com:51820` (VPN connection)
2. Relay → Forwards via WireGuard tunnel to VPN server
3. VPN Server (Tokyo) → Masquerades traffic to internet
4. Internet sees request from Tokyo IP
5. Response follows reverse path back to your phone

**Result:** You browse internet as if you're in Tokyo!

---

## ✨ Features

### Core Capabilities
- ✅ **Reverse Tunnel** - VPN server initiates connection (no inbound ports!)
- ✅ **Deploy Anywhere** - Works through any NAT/firewall/router
- ✅ **Stable Hostname** - Relay server has fixed domain (phones always connect here)
- ✅ **Location-Based VPN** - Access internet from wherever VPN server is located
- ✅ **Plug & Play** - Pre-configure, ship, plug in - it works

### Technical Features
- ✅ **No Port Forwarding** - VPN server needs zero network configuration
- ✅ **Dynamic Interface Detection** - Auto-detects eth0/wlan0/any interface
- ✅ **Auto-Reconnect** - WireGuard PersistentKeepalive keeps tunnel alive
- ✅ **SSH Access** - Access VPN server remotely via `relay:2222`
- ✅ **Production Ready** - Systemd services, auto-start on boot
- ✅ **Easy Setup** - 2 scripts, 5 minutes, minimal config
- ✅ **Secure** - WireGuard encryption + no exposed ports on VPN server

---

## 💡 Real-World Use Cases

### 1. Remote Office Deployment
**Scenario:** Access client's network remotely without their IT changing anything.

**How:**
- Ship pre-configured VPN server to client site
- Client plugs it into their network (no router config needed!)
- VPN server tunnels back to your relay
- You connect from anywhere to access their network

**Benefit:** No IT tickets, no waiting, no router access needed.

---

### 2. Multi-Location Internet Access
**Scenario:** Need to access internet from different countries/cities.

**How:**
- Deploy VPN servers in NYC, London, Tokyo, etc.
- Each one tunnels back to same relay server
- Connect to different VPNs for different exit locations

**Benefit:** One relay, multiple VPN servers, access internet from anywhere.

---

### 3. Home Network Access While Traveling
**Scenario:** Access home network, NAS, IoT devices while away.

**How:**
- Deploy VPN server at home (behind your router)
- No port forwarding or router config needed
- Connect from anywhere to access home network

**Benefit:** Secure remote access without exposing services directly.

---

### 4. Quick Site-to-Site VPN
**Scenario:** Connect two offices securely.

**How:**
- Deploy VPN server at office B (behind their firewall)
- Office A users connect via relay
- Access office B resources as if local

**Benefit:** No firewall changes at office B, instant setup.

---

### 5. IoT/Lab Network Access
**Scenario:** Secure access to isolated IoT/test network.

**How:**
- Deploy VPN server on isolated network
- Reverse tunnel to relay (outbound firewall usually allows)
- Access devices remotely

**Benefit:** Secure access without opening inbound holes.

---

## 📋 Prerequisites

### Relay Server (VPS with Public IP)
- Ubuntu/Debian server with public IP
- Root/sudo access
- Ports available: 51820/UDP, 51821/UDP, 2222/TCP
- Router port forwarding configured (if behind router)

### VPN Server (Can be behind NAT)
- Ubuntu/Debian server (Raspberry Pi works great!)
- Root/sudo access
- Can reach internet (outbound connections)
- No inbound ports needed!

### Your Computer
- To run scripts and generate client configs

---

## 🚀 Quick Start (5 Minutes)

### Step 1: Configure

```bash
# Clone this repository
git clone https://github.com/nandanprakash/wireguard-nat-tunnel.git
cd wireguard-nat-tunnel

# Edit config.sh - ONLY 2 REQUIRED CHANGES:
nano config.sh
```

**Minimal config (only change these):**
```bash
RELAY_DOMAIN="your-relay-server.com"    # Your relay's domain/IP
SSH_PASSWORD="YourSecurePassword"       # Change this!
```

That's it! Defaults work for everything else.

### Step 2: Setup Relay Server

```bash
# Copy files to relay server
scp config.sh relay-wireguard-setup.sh user@your-relay-server.com:/tmp/

# SSH to relay and run setup
ssh user@your-relay-server.com
cd /tmp
sudo bash relay-wireguard-setup.sh

# ✅ Copy the relay public key shown at the end
```

### Step 3: Setup VPN Server

```bash
# Copy files to VPN server
scp config.sh pi-wireguard-tunnel-setup.sh user@vpn-server-local-ip:/tmp/

# SSH to VPN server and run setup
ssh user@vpn-server-local-ip
cd /tmp
sudo bash pi-wireguard-tunnel-setup.sh

# ✅ Copy the VPN server public key shown at the end
```

### Step 4: Connect Relay to VPN Server

```bash
# SSH back to relay server
ssh user@your-relay-server.com

# Add VPN server's public key
VPN_KEY="<paste_vpn_server_public_key_here>"
sudo sed -i "s/PLACEHOLDER_PI_PUBLIC_KEY/$VPN_KEY/" /etc/wireguard/wg-tunnel.conf
sudo systemctl restart wg-quick@wg-tunnel

# Verify tunnel is up
sudo wg show wg-tunnel
# Should show "latest handshake: X seconds ago"
```

### Step 5: Generate Client Config

```bash
# On your computer (or relay server)
./generate-phone-qr.sh

# Scan QR code with WireGuard app on your phone!
```

---

## 📱 Connecting Clients

### Mobile (iOS/Android)
1. Install [WireGuard app](https://www.wireguard.com/install/)
2. Scan QR code from `generate-phone-qr.sh`
3. Toggle VPN ON
4. ✅ All traffic routes through your VPN!

### Desktop (Windows/Mac/Linux)
1. Install [WireGuard](https://www.wireguard.com/install/)
2. Import config file generated by script
3. Activate connection

**Endpoint:** `your-relay-server.com:51820`

---

## 🔧 Configuration Reference

### Minimal Setup (Required)
```bash
RELAY_DOMAIN="vpn.example.com"      # Your relay server's public address
SSH_PASSWORD="SecurePassword123"    # SSH password for both servers
```

### Common Customizations
```bash
# Use different VPN network
VPN_NETWORK="10.200.0.0/24"
VPN_GATEWAY="10.200.0.1"

# Use different ports
WIREGUARD_PORT="8443"               # Change if 51820 is blocked
WIREGUARD_TUNNEL_PORT="8444"
SSH_FORWARD_PORT="2200"

# Use Cloudflare DNS instead of Google
VPN_DNS_SERVERS="1.1.1.1, 1.0.0.1"
```

---

## 🛠️ Management

### Check Status

**On Relay:**
```bash
sudo wg show wg-tunnel              # Tunnel status
sudo systemctl status wireguard-udp-forward  # socat status
```

**On VPN Server:**
```bash
sudo wg show wg0                    # VPN clients
sudo wg show wg-tunnel              # Tunnel to relay
./diagnose-pi-vpn.sh                # Full diagnostic
```

### Restart Services

**Relay:**
```bash
sudo systemctl restart wg-quick@wg-tunnel
sudo systemctl restart wireguard-udp-forward
```

**VPN Server:**
```bash
sudo systemctl restart wg-quick@wg0
sudo systemctl restart wg-quick@wg-tunnel
```

### Add More Clients

```bash
# Generate new client
./generate-phone-qr.sh

# Or manually add to VPN server's /etc/wireguard/wg0.conf
```

---

## 🐛 Troubleshooting

### VPN Connects But No Internet

**Check 1: Verify NAT is working**
```bash
# On VPN server
sudo iptables -t nat -L POSTROUTING -n -v | grep MASQUERADE
# Should show packets going through
```

**Check 2: Check forwarding**
```bash
# On VPN server
sudo iptables -L FORWARD -n -v | grep wg0
# Should show packets
```

**Check 3: Disable corporate VPN**
- Nested VPNs cause conflicts!
- Disconnect from work VPN before connecting to your VPN

### Can't Connect to VPN

**Check 1: Relay is reachable**
```bash
nc -zvu your-relay-server.com 51820
# Should say "succeeded"
```

**Check 2: Tunnel is up**
```bash
# On relay
sudo wg show wg-tunnel | grep handshake
# Should show recent handshake
```

**Check 3: socat is running**
```bash
# On relay
sudo systemctl status wireguard-udp-forward
# Should be "active (running)"
```

### SSH to VPN Server Not Working

```bash
# From anywhere
ssh -p 2222 user@your-relay-server.com

# If fails, check DNAT on relay
sudo iptables -t nat -L PREROUTING -n -v | grep 2222
```

---

## 📊 Network Details

### IP Ranges
- **VPN Client Network:** `10.8.0.0/24` (254 clients)
- **Tunnel Network:** `10.9.0.0/30` (2 IPs)
  - Relay: `10.9.0.1`
  - VPN Server: `10.9.0.2`

### Ports
- **51820/UDP:** VPN client connections (public)
- **51821/UDP:** Relay-to-VPN tunnel (public)
- **2222/TCP:** SSH to VPN server (public)

### Services
- **Relay:** `wg-tunnel`, `wireguard-udp-forward` (socat)
- **VPN Server:** `wg-tunnel`, `wg0`

---

## 🔐 Security Considerations

- ✅ WireGuard uses state-of-the-art cryptography (Noise protocol)
- ✅ All traffic encrypted end-to-end
- ✅ Change default SSH password in `config.sh`
- ✅ Consider using SSH keys instead of passwords
- ✅ Configure firewall (UFW) on both servers
- ✅ No WireGuard private keys in repository
- ⚠️ Relay server must be trusted (sees encrypted traffic)

---

## 🤝 Contributing

Contributions welcome! Please open an issue or pull request.

---

## 📄 License

MIT License - feel free to use for personal or commercial projects.

---

## 🙏 Acknowledgments

Built with:
- [WireGuard](https://www.wireguard.com/) - Fast, modern VPN
- [socat](http://www.dest-unreach.org/socat/) - Multipurpose relay

---

## 📚 Learn More

- [WireGuard Documentation](https://www.wireguard.com/quickstart/)
- [How NAT Traversal Works](https://en.wikipedia.org/wiki/NAT_traversal)
- [WireGuard Protocol Paper](https://www.wireguard.com/papers/wireguard.pdf)

---

**🎉 Enjoy your personal VPN accessible from anywhere!**
