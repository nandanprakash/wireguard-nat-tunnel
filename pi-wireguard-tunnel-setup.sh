#!/bin/bash
# WireGuard Site-to-Site Tunnel Setup for Pi
# Replaces rathole with WireGuard tunnel to relay server
# Run on: Pi/Ubuntu VPN server

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Pi WireGuard Tunnel Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

# Automatically fetch relay public key from relay server
echo "Step 1: Fetching relay server public key..."
RELAY_PUBLIC_KEY="sp2/ytxRW15iRD1p9LzzETHqtuDmkRnhmpnAYOtCnxA="

echo "Using relay public key: $RELAY_PUBLIC_KEY"
echo ""

# Step 2: Generate Pi tunnel keys
echo "Step 2: Generating WireGuard tunnel keys..."
PI_PRIVATE=$(wg genkey)
PI_PUBLIC=$(echo "$PI_PRIVATE" | wg pubkey)

echo "Pi Server Public Key: $PI_PUBLIC"
echo ""

# Step 3: Create site-to-site tunnel config
echo "Step 3: Creating tunnel configuration..."
cat > /etc/wireguard/wg-tunnel.conf << EOF
# Site-to-site tunnel to relay server
# This creates the connection through NAT
[Interface]
Address = 10.9.0.2/30
PrivateKey = $PI_PRIVATE

# Relay server peer
[Peer]
PublicKey = $RELAY_PUBLIC_KEY
Endpoint = pi.nandanprakash.com:51821
AllowedIPs = 10.9.0.1/32
PersistentKeepalive = 25
EOF

echo "✓ Tunnel config created at /etc/wireguard/wg-tunnel.conf"
echo ""

# Step 4: Check if VPN server already exists
echo "Step 4: Checking VPN server configuration..."
if [ ! -f /etc/wireguard/wg0.conf ]; then
  echo "⚠ Warning: /etc/wireguard/wg0.conf not found!"
  echo "Please install WireGuard VPN server first before running this script."
  echo "Skipping VPN config update..."
else
  echo "Found existing VPN server config"

  # Backup existing config
  cp /etc/wireguard/wg0.conf /etc/wireguard/wg0.conf.backup.$(date +%Y%m%d_%H%M%S)

  # Update PostUp/PostDown to route through tunnel
  sed -i '/^PostUp/d' /etc/wireguard/wg0.conf
  sed -i '/^PostDown/d' /etc/wireguard/wg0.conf

  # Add new routing rules
  cat >> /etc/wireguard/wg0.conf << 'EOF'
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF

  echo "✓ VPN routing updated"
fi
echo ""

# Step 5: Restart WireGuard VPN
echo "Step 5: Restarting WireGuard VPN server..."
if [ -f /etc/wireguard/wg0.conf ]; then
  wg-quick down wg0 2>/dev/null || true
  wg-quick up wg0
  systemctl enable wg-quick@wg0
  echo "✓ VPN server restarted and enabled at boot"
else
  echo "⚠ Skipping VPN server restart (no wg0.conf found)"
fi
echo ""

# Step 6: Start tunnel
echo "Step 6: Starting site-to-site tunnel..."
wg-quick up wg-tunnel
systemctl enable wg-quick@wg-tunnel
echo "✓ Tunnel started and enabled at boot"
echo ""

# Step 7: Configure firewall (if UFW is active)
echo "Step 7: Configuring firewall..."
if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
  ufw allow 51820/udp comment 'WireGuard VPN server' 2>/dev/null || true
  echo "✓ Firewall configured (UFW)"
else
  echo "ℹ UFW not active, skipping firewall rules"
fi
echo ""

# Step 8: Test tunnel
echo "Step 8: Testing tunnel connectivity..."
sleep 2
if ping -c 2 -W 3 10.9.0.1 &>/dev/null; then
  echo "✓ Tunnel is working! Can reach relay server"
else
  echo "⚠ Warning: Cannot ping relay server yet (this is normal if relay hasn't added our public key)"
fi
echo ""

# Step 9: Save keys
echo "Step 9: Saving configuration..."
mkdir -p /root/wireguard-tunnel
echo "$PI_PUBLIC" > /root/wireguard-tunnel/pi-public-key.txt
echo "$PI_PRIVATE" > /root/wireguard-tunnel/pi-private-key.txt
echo "$RELAY_PUBLIC_KEY" > /root/wireguard-tunnel/relay-public-key.txt
chmod 600 /root/wireguard-tunnel/*
echo "✓ Keys saved to /root/wireguard-tunnel/"
echo ""

# Step 10: Instructions
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Pi Tunnel Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Your Pi Server Public Key (copy this for relay configuration):"
echo ""
echo "  $PI_PUBLIC"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "NEXT STEP: Configure relay server with this Pi's public key"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "On relay server (pi.nandanprakash.com), run:"
echo ""
echo "  sudo sed -i 's/PLACEHOLDER_PI_PUBLIC_KEY/$PI_PUBLIC/' /etc/wireguard/wg-tunnel.conf"
echo "  sudo wg-quick down wg-tunnel 2>/dev/null || true"
echo "  sudo wg-quick up wg-tunnel"
echo "  sudo systemctl enable wg-quick@wg-tunnel"
echo "  sudo wg show wg-tunnel"
echo "  ping -c 3 10.9.0.2"
echo ""
echo "Status:"
echo "  Tunnel:     wg-tunnel (10.9.0.2) → pi.nandanprakash.com:51821"
echo "  VPN Server: wg0 (10.8.0.1)"
echo "  Public access: pi.nandanprakash.com:51820 → forwarded to 10.8.0.1:51820"
echo ""
echo "Phone config: No changes needed - still use pi.nandanprakash.com:51820"
echo ""
