# 🔐 Raspberry Pi WireGuard VPN Server

**Production-ready WireGuard VPN accessible from anywhere via pi.nandanprakash.com**

Two-VM setup with WireGuard tunnel for secure remote access and VPN services.

---

## 🏗️ Architecture Overview

```
Phone/Client (anywhere)
   ↓ WireGuard VPN
   ↓ pi.nandanprakash.com:51820
   ↓
Relay Server (pi.nandanprakash.com:22)
   ↓ Port forward UDP 51820 → 10.8.0.1:51820 (VPN)
   ↓ Port forward TCP 2222 → 10.9.0.2:22 (SSH)
   ↓ WireGuard Tunnel (10.9.0.1 ←→ 10.9.0.2)
   ↓
Pi VPN Server (pi.nandanprakash.com:2222)
   ↓ VPN Server (10.8.0.1:51820)
   ↓ NAT Masquerade
   ↓
Internet Access
```

**Setup:**
- **Server 1 (Port 22)**: Relay server with WireGuard tunnel endpoint, forwards traffic via DNAT
- **Server 2 (Port 2222)**: Pi VPN server behind NAT, runs WireGuard VPN for phone clients
- **Connection**: Both accessible as ubuntu@pi.nandanprakash.com (different ports)

---

## 📦 Project Structure

```
raspberry-pi-vpn/
├── relay-wireguard-setup.sh         # Setup relay server (port 22)
├── pi-wireguard-tunnel-setup.sh     # Setup Pi VPN server (port 2222) - with dynamic interface
├── fix-vpn-internet-dynamic.sh      # Fix VPN with auto-interface detection (RECOMMENDED)
├── fix-pi-vpn-after-restart.sh      # Fix VPN issues (basic fix)
├── diagnose-pi-vpn.sh               # Diagnostic tool for VPN issues
├── README.md                         # This file
└── QUICK-START.md                    # Quick deployment guide
```

---

## 🚀 Quick Start

### Initial Setup (One Time)

**1. Setup Relay Server (Port 22):**
```bash
# Copy script to relay
scp relay-wireguard-setup.sh ubuntu@pi.nandanprakash.com:/tmp/

# SSH to relay and run
ssh ubuntu@pi.nandanprakash.com
sudo bash /tmp/relay-wireguard-setup.sh
# Copy the relay public key shown at the end
```

**2. Setup Pi VPN Server (Port 2222):**
```bash
# Copy script to Pi server
scp pi-wireguard-tunnel-setup.sh ubuntu@pi.nandanprakash.com:/tmp/

# SSH to Pi server and run
ssh -p 2222 ubuntu@pi.nandanprakash.com
sudo bash /tmp/pi-wireguard-tunnel-setup.sh
# Copy the Pi public key shown at the end
```

**3. Complete Relay Configuration:**
```bash
# SSH back to relay
ssh ubuntu@pi.nandanprakash.com

# Add Pi public key and restart
PI_KEY="<PASTE_PI_PUBLIC_KEY_HERE>"
sudo sed -i "s/PLACEHOLDER_PI_PUBLIC_KEY/$PI_KEY/" /etc/wireguard/wg-tunnel.conf
sudo wg-quick down wg-tunnel 2>/dev/null || true
sudo wg-quick up wg-tunnel
sudo systemctl enable wg-quick@wg-tunnel

# Verify
sudo wg show wg-tunnel
ping -c 3 10.9.0.2
```

See `QUICK-START.md` for detailed instructions.

---

## 🔧 Maintenance & Troubleshooting

### Check VPN Status
```bash
# SSH to Pi VPN server
ssh -p 2222 ubuntu@pi.nandanprakash.com

# Run diagnostic
./diagnose-pi-vpn.sh
```

### Fix VPN Issues (No Internet on Phone)
```bash
# SSH to Pi VPN server
ssh -p 2222 ubuntu@pi.nandanprakash.com

# Run dynamic interface fix (RECOMMENDED - auto-detects active interface)
sudo bash /tmp/fix-vpn-internet-dynamic.sh

# OR run the basic fix
sudo bash /tmp/fix-pi-vpn-after-restart.sh
```

**Common Issues Fixed:**
- ✅ **Dynamic interface detection** - automatically uses eth0, wlan0, or any active interface
- ✅ Interface changes (wlan0 → eth0 or vice versa)
- ✅ Missing NAT/MASQUERADE rules
- ✅ Duplicate iptables rules cleanup
- ✅ IP forwarding disabled
- ✅ Services not starting after reboot

### Manual Service Management
```bash
# Restart WireGuard VPN
sudo wg-quick down wg0 && sudo wg-quick up wg0

# Restart tunnel
sudo wg-quick down wg-tunnel && sudo wg-quick up wg-tunnel

# Check status
sudo wg show all
sudo systemctl status wg-quick@wg0
sudo systemctl status wg-quick@wg-tunnel

# View logs
sudo journalctl -u wg-quick@wg0 -f
sudo journalctl -u wg-quick@wg-tunnel -f
```

---

## 🎯 Key Features

✅ **WireGuard Site-to-Site Tunnel** - Fast, secure connection through NAT
✅ **DNAT Port Forwarding** - Seamless VPN and SSH access
✅ **Works Behind NAT** - Pi server initiates connection
✅ **High Performance** - 50-100+ Mbps (vs 2-5 Mbps with rathole)
✅ **Auto-Recovery** - Services restart automatically at boot
✅ **Production Ready** - Tested and deployed

---

## 🔐 Security

- ✅ WireGuard encryption (Noise protocol)
- ✅ UFW firewall on both servers
- ✅ SSH key authentication recommended
- ✅ No direct inbound ports on Pi VPN server

---

## 📊 Network Details

### Relay Server (Port 22)
- **Tunnel IP**: 10.9.0.1/30
- **Listen Port**: 51821 (WireGuard tunnel)
- **Services**: wg-tunnel

### Pi VPN Server (Port 2222)
- **Tunnel IP**: 10.9.0.2/30
- **VPN Network**: 10.8.0.0/24
- **VPN Server IP**: 10.8.0.1
- **Services**: wg-tunnel, wg0

### Port Forwarding (on relay)
- **UDP 51820** → 10.8.0.1:51820 (VPN traffic)
- **TCP 2222** → 10.9.0.2:22 (SSH to Pi)
- **UDP 51821** → Tunnel endpoint

---

## 🆘 Quick Help

**SSH Credentials (both servers):**
- Username: `ubuntu`
- Password: `NandanPi2121`

**Access Relay Server:**
```bash
ssh ubuntu@pi.nandanprakash.com
```

**Access Pi VPN Server:**
```bash
ssh -p 2222 ubuntu@pi.nandanprakash.com
```

**Phone VPN Not Working?**
1. **Disconnect from any other VPN first!** (Corporate VPN, other VPN apps)
   - Nested VPNs cause routing conflicts
2. SSH to Pi server: `ssh -p 2222 ubuntu@pi.nandanprakash.com`
3. Run diagnostic: `sudo bash diagnose-pi-vpn.sh`
4. Run fix: `sudo bash fix-pi-vpn-after-restart.sh`
5. Reconnect from phone

**Get VPN Client Configs:**
```bash
ssh -p 2222 ubuntu@pi.nandanprakash.com
sudo cat /etc/wireguard/wg0.conf  # See existing peers
```

---

## 📝 Notes

- Previous rathole tunnel setup has been replaced with WireGuard tunnel for better performance
- Both servers run Ubuntu and have WireGuard installed
- Router must have port forwarding configured for UDP 51820, UDP 51821, and TCP 2222
- Services are enabled at boot for automatic recovery

---

**🎉 Production Ready!** See `QUICK-START.md` for deployment guide.
