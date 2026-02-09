# Quick Start Guide - New Pi VPN Server Setup

**One-command setup** for deploying a new WireGuard VPN server that connects to your relay.

## Prerequisites

- ✅ Relay server configured at pi.nandanprakash.com (already done)
- ✅ Router port forwarding:
  - UDP 51820 → 192.168.86.115
  - UDP 51821 → 192.168.86.115
  - TCP 2222 → 192.168.86.115
- 🆕 New Raspberry Pi with Ubuntu 24.04 and WireGuard VPN server installed

## Current Relay Public Key

```
sp2/ytxRW15iRD1p9LzzETHqtuDmkRnhmpnAYOtCnxA=
```

## Setup Commands

### 1. On Your New Pi Server

**Fully automated - no user input required!**

```bash
# Copy script from your local machine
scp ~/playground/raspberry-pi-vpn/pi-wireguard-tunnel-setup.sh ubuntu@<NEW_PI_IP>:/tmp/

# SSH to new Pi
ssh ubuntu@<NEW_PI_IP>

# Run setup script (fully automated!)
sudo bash /tmp/pi-wireguard-tunnel-setup.sh
```

The script automatically:
- ✅ Uses hardcoded relay public key (sp2/ytxRW15iRD1p9LzzETHqtuDmkRnhmpnAYOtCnxA=)
- ✅ Generates unique Pi tunnel keys
- ✅ Configures tunnel to relay
- ✅ Updates VPN routing
- ✅ Configures firewall
- ✅ Enables services at boot

**Copy the Pi Public Key** shown at the end (you'll need it for step 2).

### 2. On Relay Server

```bash
# SSH to relay
ssh ubuntu@pi.nandanprakash.com

# Replace <PI_PUBLIC_KEY> with the key from step 1
PI_KEY="<PASTE_PI_PUBLIC_KEY_HERE>"

# Update relay config
sudo sed -i "s/PLACEHOLDER_PI_PUBLIC_KEY/$PI_KEY/" /etc/wireguard/wg-tunnel.conf

# Restart tunnel
sudo wg-quick down wg-tunnel 2>/dev/null || true
sudo wg-quick up wg-tunnel
sudo systemctl enable wg-quick@wg-tunnel

# Verify
sudo wg show wg-tunnel
ping -c 3 10.9.0.2
```

### 3. Test Everything

**From relay:**
```bash
sudo wg show wg-tunnel    # Should show "latest handshake"
ping 10.9.0.2             # Should work
ping 10.8.0.1             # Should work
```

**SSH to Pi through tunnel:**
```bash
ssh ubuntu@pi.nandanprakash.com -p 2222
# This connects to your remote Pi!
```

**Test from phone:**
- Connect to existing WireGuard VPN (endpoint: pi.nandanprakash.com:51820)
- Run speed test → should see 50-100+ Mbps!

## What the Script Does

**Pi Server Script (`pi-wireguard-tunnel-setup.sh`):**
1. ✅ Uses hardcoded relay public key (no manual input!)
2. ✅ Generates unique tunnel keys
3. ✅ Creates tunnel config (10.9.0.2)
4. ✅ Updates VPN server routing (if wg0.conf exists)
5. ✅ Configures firewall (UFW) automatically
6. ✅ Starts tunnel and enables at boot
7. ✅ Tests connectivity
8. ✅ Displays Pi public key for relay configuration

**Relay Server (already configured):**
- ✅ Listening on port 51821 for Pi tunnel
- ✅ Port forwarding: 51820 → VPN, 2222 → SSH
- ✅ Firewall configured
- ✅ Enabled at boot

## Deployment to Remote Location

Once tested, move your new Pi to its final location:

1. **Shutdown Pi:**
   ```bash
   sudo shutdown -h now
   ```

2. **Move to remote location** (different network, behind NAT)

3. **Power on** - Pi automatically connects to relay via internet!

4. **Verify from relay:**
   ```bash
   ssh ubuntu@pi.nandanprakash.com
   sudo wg show wg-tunnel    # Should show handshake
   ping 10.9.0.2             # Should work
   ```

5. **Phone VPN continues working** - no config changes needed!

## Troubleshooting One-Liners

**Check tunnel status:**
```bash
# On Pi
sudo wg show wg-tunnel | grep -E "handshake|transfer"

# On Relay
sudo wg show wg-tunnel | grep -E "handshake|transfer"
```

**Restart tunnel:**
```bash
sudo wg-quick down wg-tunnel && sudo wg-quick up wg-tunnel
```

**Check port forwarding:**
```bash
# On relay
sudo iptables -t nat -L PREROUTING -n -v | grep -E "51820|2222"
```

**Test from anywhere:**
```bash
# SSH to remote Pi
ssh ubuntu@pi.nandanprakash.com -p 2222

# Check if VPN port is open
nc -zvu pi.nandanprakash.com 51820
```

## Network Map

```
Phone → pi.nandanprakash.com:51820
          ↓ (port forward)
        Relay (10.9.0.1) @ 24.6.173.162
          ↓ (WireGuard tunnel)
        Pi (10.9.0.2) @ remote location
          ↓ (VPN server)
        VPN (10.8.0.1) → Internet
```

## Files & Keys

**Relay Server:**
- Config: `/etc/wireguard/wg-tunnel.conf`
- Keys: `/root/wireguard-relay/relay-public-key.txt`
- Public Key: `sp2/ytxRW15iRD1p9LzzETHqtuDmkRnhmpnAYOtCnxA=`

**Pi Server:**
- Tunnel: `/etc/wireguard/wg-tunnel.conf`
- VPN: `/etc/wireguard/wg0.conf`
- Keys: `/root/wireguard-tunnel/pi-public-key.txt`
- Public Key: Generated during setup (unique per Pi)

## Performance

- **Rathole (old)**: 2-5 Mbps
- **WireGuard Tunnel (new)**: 50-100+ Mbps
- **Speed increase**: 10-50x faster!

---

**That's it!** Your new Pi VPN server is ready for deployment.
