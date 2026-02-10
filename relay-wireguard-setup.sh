#!/bin/bash
# WireGuard Relay Server Setup
# Replaces rathole with WireGuard site-to-site tunnel + port forwarding
# Run on: Relay server

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
echo "WireGuard Relay Server Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

# Step 1: Stop and remove rathole (if exists)
echo "Step 1: Removing rathole (if exists)..."
systemctl stop rathole-server 2>/dev/null || true
systemctl disable rathole-server 2>/dev/null || true
rm -f /etc/systemd/system/rathole-server.service
rm -f /usr/local/bin/rathole
rm -rf /etc/rathole
systemctl daemon-reload
echo "✓ Rathole removed"
echo ""

# Step 2: Install WireGuard
echo "Step 2: Installing WireGuard..."
apt-get update -qq
apt-get install -y wireguard wireguard-tools qrencode socat
echo "✓ WireGuard and socat installed"
echo ""

# Step 3: Generate keys
echo "Step 3: Generating WireGuard keys..."
RELAY_PRIVATE=$(wg genkey)
RELAY_PUBLIC=$(echo "$RELAY_PRIVATE" | wg pubkey)

echo "Relay Server Public Key: $RELAY_PUBLIC"
echo ""

# Step 4: Create WireGuard config for site-to-site tunnel
echo "Step 4: Creating WireGuard tunnel configuration..."
cat > /etc/wireguard/wg-tunnel.conf << EOF
# Site-to-site tunnel interface
# Relay server waits for VPN server to connect
[Interface]
Address = $TUNNEL_RELAY_IP/30
ListenPort = $WIREGUARD_TUNNEL_PORT
PrivateKey = $RELAY_PRIVATE

# VPN server peer (will connect to us)
[Peer]
# PublicKey will be added after VPN server setup
PublicKey = PLACEHOLDER_VPN_PUBLIC_KEY
AllowedIPs = $TUNNEL_PI_IP/32, $VPN_NETWORK
PersistentKeepalive = $PERSISTENT_KEEPALIVE
EOF

echo "✓ Tunnel config created at /etc/wireguard/wg-tunnel.conf"
echo ""

# Step 5: Enable IP forwarding
echo "Step 5: Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1 > /dev/null
grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "✓ IP forwarding enabled"
echo ""

# Step 6: Start tunnel (will error about missing peer, that's OK)
echo "Step 6: Starting tunnel interface..."
wg-quick up wg-tunnel 2>/dev/null || echo "Tunnel interface created (peer not configured yet)"
systemctl enable wg-quick@wg-tunnel
echo "✓ Tunnel interface enabled"
echo ""

# Step 7: Setup socat UDP forwarding for WireGuard VPN traffic
echo "Step 7: Setting up socat UDP forwarding..."
cat > /etc/systemd/system/wireguard-udp-forward.service << EOF
[Unit]
Description=WireGuard UDP Forwarding via socat
After=network.target wg-quick@wg-tunnel.service
Wants=wg-quick@wg-tunnel.service

[Service]
Type=simple
ExecStart=/usr/bin/socat -T 30 UDP4-LISTEN:$WIREGUARD_VPN_PORT,reuseaddr,fork UDP4:$TUNNEL_PI_IP:$WIREGUARD_VPN_PORT
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable wireguard-udp-forward.service
systemctl restart wireguard-udp-forward.service
echo "✓ socat UDP forwarding enabled"
echo ""

# Step 8: Configure firewall
echo "Step 8: Configuring firewall..."
if command -v ufw &> /dev/null; then
    ufw allow $WIREGUARD_VPN_PORT/udp comment 'WireGuard VPN port' 2>/dev/null || true
    ufw allow $WIREGUARD_TUNNEL_PORT/udp comment 'WireGuard tunnel port' 2>/dev/null || true
    ufw allow $SSH_FORWARD_PORT/tcp comment 'SSH to VPN server' 2>/dev/null || true
    echo "✓ UFW firewall configured"
else
    echo "ℹ UFW not installed, skipping firewall configuration"
fi
echo ""

# Step 9: Setup SSH port forwarding via iptables
echo "Step 9: Setting up SSH port forwarding..."
# Check if DNAT rule exists
if ! iptables -t nat -C PREROUTING -p tcp --dport $SSH_FORWARD_PORT -j DNAT --to-destination $TUNNEL_PI_IP:22 2>/dev/null; then
    iptables -t nat -A PREROUTING -p tcp --dport $SSH_FORWARD_PORT -j DNAT --to-destination $TUNNEL_PI_IP:22
    echo "✓ SSH DNAT rule added"
else
    echo "✓ SSH DNAT rule already exists"
fi

# Add FORWARD rules for tunnel traffic
iptables -I FORWARD 1 -i wg-tunnel -j ACCEPT 2>/dev/null || echo "FORWARD rule already exists"
iptables -I FORWARD 1 -o wg-tunnel -j ACCEPT 2>/dev/null || echo "FORWARD rule already exists"

# Add MASQUERADE for tunnel traffic
if ! iptables -t nat -C POSTROUTING -o wg-tunnel -j MASQUERADE 2>/dev/null; then
    iptables -t nat -A POSTROUTING -o wg-tunnel -j MASQUERADE
    echo "✓ MASQUERADE rule added"
else
    echo "✓ MASQUERADE rule already exists"
fi
echo ""

# Step 10: Save relay public key
echo "Step 10: Saving keys..."
mkdir -p /root/wireguard-relay
echo "$RELAY_PUBLIC" > /root/wireguard-relay/relay-public-key.txt
echo "$RELAY_PRIVATE" > /root/wireguard-relay/relay-private-key.txt
chmod 600 /root/wireguard-relay/*

echo "✓ Keys saved to /root/wireguard-relay/"
echo ""

# Step 11: Instructions
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Relay Server Setup Complete (Step 1 of 2)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Relay Server Public Key:"
echo "  $RELAY_PUBLIC"
echo ""
echo "IMPORTANT: Copy this public key!"
echo ""
echo "Next Steps:"
echo "  1. Run the VPN server setup script on your VPN server"
echo "  2. The script will give you its public key"
echo "  3. Come back here and run:"
echo "     sed -i 's/PLACEHOLDER_VPN_PUBLIC_KEY/<PI_PUBLIC_KEY>/' /etc/wireguard/wg-tunnel.conf"
echo "     systemctl restart wg-quick@wg-tunnel"
echo ""
echo "Configuration:"
echo "  - VPN Port: $WIREGUARD_VPN_PORT (forwarded via socat to VPN server)"
echo "  - Tunnel Port: $WIREGUARD_TUNNEL_PORT (VPN server connects here)"
echo "  - SSH Port: $SSH_FORWARD_PORT (forwarded to VPN server via DNAT)"
echo "  - Domain: $RELAY_DOMAIN"
echo ""
echo "Clients can connect to: $RELAY_DOMAIN:$WIREGUARD_PORT"
echo ""
