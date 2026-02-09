#!/bin/bash
# Generate fresh phone WireGuard config with QR code
# Run on: Pi VPN server (port 2222)

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Generating Fresh Phone VPN Config"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

# Get server public key
SERVER_PUBLIC_KEY=$(wg show wg0 public-key)
echo "Server Public Key: $SERVER_PUBLIC_KEY"
echo ""

# Generate new client keys
echo "Generating new keys for phone..."
PHONE_PRIVATE=$(wg genkey)
PHONE_PUBLIC=$(echo "$PHONE_PRIVATE" | wg pubkey)
PHONE_PRESHARED=$(wg genpsk)
echo "✓ Keys generated"
echo ""

# Create client config file
echo "Creating phone config..."
cat > /tmp/phone-new.conf << EOF
[Interface]
PrivateKey = $PHONE_PRIVATE
Address = 10.8.0.5/24
DNS = 8.8.8.8, 8.8.4.4

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
PresharedKey = $PHONE_PRESHARED
Endpoint = pi.nandanprakash.com:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

echo "✓ Config created at /tmp/phone-new.conf"
echo ""

# Add peer to running server
echo "Adding peer to WireGuard server..."
wg set wg0 peer "$PHONE_PUBLIC" preshared-key <(echo "$PHONE_PRESHARED") allowed-ips 10.8.0.5/32
echo "✓ Peer added to running server"
echo ""

# Make it persistent by adding to config
echo "Making peer persistent in config..."
cat >> /etc/wireguard/wg0.conf << EOF

[Peer]
PublicKey = $PHONE_PUBLIC
PresharedKey = $PHONE_PRESHARED
AllowedIPs = 10.8.0.5/32
EOF
echo "✓ Peer added to config file"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phone Config Details"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
cat /tmp/phone-new.conf
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "QR Code - Scan with WireGuard App"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
qrencode -t ansiutf8 < /tmp/phone-new.conf
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Phone IP: 10.8.0.5"
echo "Instructions:"
echo "  1. Delete old WireGuard connection from your phone"
echo "  2. Open WireGuard app"
echo "  3. Tap '+' to add tunnel"
echo "  4. Tap 'Create from QR code'"
echo "  5. Scan the QR code above"
echo "  6. Name it (e.g., 'Pi VPN')"
echo "  7. Toggle ON to connect"
echo ""
echo "Key Settings in Config:"
echo "  ✓ AllowedIPs = 0.0.0.0/0  (routes ALL traffic through VPN)"
echo "  ✓ DNS = 8.8.8.8, 8.8.4.4  (Google DNS)"
echo "  ✓ Endpoint = pi.nandanprakash.com:51820"
echo ""
echo "After connecting, you should have full internet access!"
echo ""
