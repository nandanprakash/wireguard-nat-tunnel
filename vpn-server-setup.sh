#!/bin/bash
# WireGuard Site-to-Site Tunnel Setup for VPN Server
# Creates tunnel connection from VPN server to relay server
# Run on: VPN server (the one that will be behind NAT)

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/config.sh" ]; then
    source "$SCRIPT_DIR/config.sh"
else
    echo "Error: config.sh not found!"
    echo "Please create config.sh from config.sh.example"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "VPN Server Tunnel Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

# Get relay public key
echo "Step 1: Reading relay server public key..."
echo "Enter the relay server's public key (from relay setup):"
read -r RELAY_PUBLIC_KEY

if [ -z "$RELAY_PUBLIC_KEY" ]; then
    echo "Error: Relay public key is required!"
    exit 1
fi

echo "Using relay public key: $RELAY_PUBLIC_KEY"
echo ""

# Step 2: Generate VPN server tunnel keys
echo "Step 2: Generating WireGuard tunnel keys..."
VPN_PRIVATE=$(wg genkey)
VPN_PUBLIC=$(echo "$VPN_PRIVATE" | wg pubkey)

echo "VPN Server Public Key: $VPN_PUBLIC"
echo ""

# Step 3: Create site-to-site tunnel config
echo "Step 3: Creating tunnel configuration..."
cat > /etc/wireguard/wg-tunnel.conf << EOF
# Site-to-site tunnel to relay server
# This creates the connection through NAT
[Interface]
Address = $TUNNEL_VPN_IP/30
PrivateKey = $VPN_PRIVATE

# Relay server peer
[Peer]
PublicKey = $RELAY_PUBLIC_KEY
Endpoint = $RELAY_DOMAIN:$WIREGUARD_TUNNEL_PORT
AllowedIPs = $TUNNEL_RELAY_IP/32
PersistentKeepalive = $PERSISTENT_KEEPALIVE
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

  # Update PostUp/PostDown with dynamic interface detection
  sed -i '/^PostUp/d' /etc/wireguard/wg0.conf
  sed -i '/^PostDown/d' /etc/wireguard/wg0.conf

  # Add new routing rules with dynamic interface detection
  # Uses %i (wg0) to exclude VPN interface, masquerades on default route interface
  cat >> /etc/wireguard/wg0.conf << 'EOF'
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $(ip route show default | awk '/default/ {print $5}') -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $(ip route show default | awk '/default/ {print $5}') -j MASQUERADE
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
  ufw allow $WIREGUARD_PORT/udp comment 'WireGuard VPN server' 2>/dev/null || true
  echo "✓ Firewall configured (UFW)"
else
  echo "ℹ UFW not active, skipping firewall rules"
fi
echo ""

# Step 8: Test tunnel
echo "Step 8: Testing tunnel connectivity..."
sleep 2
if ping -c 2 -W 3 $TUNNEL_RELAY_IP &>/dev/null; then
  echo "✓ Tunnel is working! Can reach relay server"
else
  echo "⚠ Warning: Cannot ping relay server yet (this is normal if relay hasn't added our public key)"
fi
echo ""

# Step 9: Save keys
echo "Step 9: Saving configuration..."
mkdir -p /root/wireguard-tunnel
echo "$VPN_PUBLIC" > /root/wireguard-tunnel/vpn-public-key.txt
echo "$VPN_PRIVATE" > /root/wireguard-tunnel/vpn-private-key.txt
echo "$RELAY_PUBLIC_KEY" > /root/wireguard-tunnel/relay-public-key.txt
chmod 600 /root/wireguard-tunnel/*
echo "✓ Keys saved to /root/wireguard-tunnel/"
echo ""

# Step 10: Instructions
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ VPN Server Tunnel Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Your VPN Server Public Key (copy this for relay configuration):"
echo ""
echo "  $VPN_PUBLIC"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "NEXT STEP: Configure relay server with this VPN server's public key"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "On relay server ($RELAY_DOMAIN), run:"
echo ""
echo "  sudo sed -i 's/PLACEHOLDER_VPN_PUBLIC_KEY/$VPN_PUBLIC/' /etc/wireguard/wg-tunnel.conf"
echo "  sudo systemctl restart wg-quick@wg-tunnel"
echo "  sudo wg show wg-tunnel"
echo "  ping -c 3 $TUNNEL_VPN_IP"
echo ""
echo "Status:"
echo "  Tunnel:     wg-tunnel ($TUNNEL_VPN_IP) → $RELAY_DOMAIN:$WIREGUARD_TUNNEL_PORT"
echo "  VPN Server: wg0 ($VPN_GATEWAY)"
echo "  Public access: $RELAY_DOMAIN:$WIREGUARD_PORT → forwarded to VPN server"
echo ""
echo "Client config: Endpoint should be $RELAY_DOMAIN:$WIREGUARD_PORT"
echo ""
