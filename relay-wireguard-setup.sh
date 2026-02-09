#!/bin/bash
# WireGuard Relay Server Setup
# Replaces rathole with WireGuard site-to-site tunnel + port forwarding
# Run on: pi.nandanprakash.com

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "WireGuard Relay Server Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 1: Stop and remove rathole
echo "Step 1: Removing rathole..."
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
apt-get install -y wireguard wireguard-tools qrencode
echo "✓ WireGuard installed"
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
# Relay server waits for Pi to connect
[Interface]
Address = 10.9.0.1/30
ListenPort = 51821
PrivateKey = $RELAY_PRIVATE

# Pi server peer (will connect to us)
[Peer]
# PublicKey will be added after Pi setup
PublicKey = PLACEHOLDER_PI_PUBLIC_KEY
AllowedIPs = 10.9.0.2/32, 10.8.0.0/24
PersistentKeepalive = 25
EOF

echo "✓ Tunnel config created at /etc/wireguard/wg-tunnel.conf"
echo ""

# Step 5: Enable IP forwarding
echo "Step 5: Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1
grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "✓ IP forwarding enabled"
echo ""

# Step 6: Update WireGuard config with port forwarding
echo "Step 6: Creating tunnel config with port forwarding..."
cat > /etc/wireguard/wg-tunnel.conf << EOF
# Site-to-site tunnel interface
# Relay server waits for Pi to connect
[Interface]
Address = 10.9.0.1/30
ListenPort = 51821
PrivateKey = $RELAY_PRIVATE
PostUp = iptables -t nat -A PREROUTING -p udp --dport 51820 -j DNAT --to-destination 10.8.0.1:51820; iptables -t nat -A PREROUTING -p tcp --dport 2222 -j DNAT --to-destination 10.9.0.2:22; iptables -A FORWARD -i wg-tunnel -j ACCEPT; iptables -A FORWARD -o wg-tunnel -j ACCEPT; iptables -t nat -A POSTROUTING -o wg-tunnel -j MASQUERADE
PostDown = iptables -t nat -D PREROUTING -p udp --dport 51820 -j DNAT --to-destination 10.8.0.1:51820; iptables -t nat -D PREROUTING -p tcp --dport 2222 -j DNAT --to-destination 10.9.0.2:22; iptables -D FORWARD -i wg-tunnel -j ACCEPT; iptables -D FORWARD -o wg-tunnel -j ACCEPT; iptables -t nat -D POSTROUTING -o wg-tunnel -j MASQUERADE

# Pi server peer (will connect to us)
[Peer]
# PublicKey will be added after Pi setup
PublicKey = PLACEHOLDER_PI_PUBLIC_KEY
AllowedIPs = 10.9.0.2/32, 10.8.0.0/24
PersistentKeepalive = 25
EOF

echo "✓ Tunnel config created"
echo ""

# Step 7: Configure firewall
echo "Step 7: Configuring firewall..."
ufw allow 51820/udp comment 'WireGuard VPN port'
ufw allow 51821/udp comment 'WireGuard tunnel port'
ufw allow 2222/tcp comment 'SSH to remote Pi'
echo "✓ Firewall configured"
echo ""

# Step 8: Save relay public key for Pi setup
echo "Step 8: Saving keys..."
mkdir -p /root/wireguard-relay
echo "$RELAY_PUBLIC" > /root/wireguard-relay/relay-public-key.txt
echo "$RELAY_PRIVATE" > /root/wireguard-relay/relay-private-key.txt
chmod 600 /root/wireguard-relay/*

echo "✓ Keys saved to /root/wireguard-relay/"
echo ""

# Step 9: Instructions
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
echo "  1. Run the Pi setup script on ubuntu@192.168.86.126"
echo "  2. The Pi script will give you its public key"
echo "  3. Come back here and run:"
echo "     sed -i 's/PLACEHOLDER_PI_PUBLIC_KEY/<PI_PUBLIC_KEY>/' /etc/wireguard/wg-tunnel.conf"
echo "     wg-quick up wg-tunnel"
echo "     systemctl enable wg-quick@wg-tunnel"
echo ""
echo "Port Forwarding Configured:"
echo "  51820/udp → 10.8.0.1:51820 (Phone VPN traffic)"
echo "  51821/udp → Listening (Pi tunnel)"
echo "  2222/tcp  → 10.9.0.2:22 (SSH to Pi)"
echo ""
echo "Router Port Forwarding Required:"
echo "  Forward UDP 51820 to this server"
echo "  Forward UDP 51821 to this server"
echo "  Forward TCP 2222 to this server"
echo ""
