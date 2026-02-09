#!/bin/bash
# Use socat for UDP forwarding instead of DNAT
# This properly forwards WireGuard packets without breaking the protocol
# Run on: Relay server (port 22)

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Setting up socat UDP forwarding for WireGuard"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

# Install socat if not present
if ! command -v socat &> /dev/null; then
    echo "Installing socat..."
    apt-get update -qq
    apt-get install -y socat
    echo "✓ socat installed"
else
    echo "✓ socat already installed"
fi
echo ""

# Remove old DNAT rule
echo "Removing old DNAT rule..."
iptables -t nat -D PREROUTING -p udp --dport 51820 -j DNAT --to-destination 10.9.0.2:51820 2>/dev/null || echo "No old DNAT rule"
echo "✓ DNAT removed"
echo ""

# Stop any existing socat process
echo "Stopping any existing socat processes..."
pkill -f "socat.*51820" || true
echo "✓ Old processes stopped"
echo ""

# Create systemd service for socat forwarding
echo "Creating systemd service for UDP forwarding..."
cat > /etc/systemd/system/wireguard-udp-forward.service << 'EOF'
[Unit]
Description=WireGuard UDP Forwarding via socat
After=network.target wg-quick@wg-tunnel.service
Wants=wg-quick@wg-tunnel.service

[Service]
Type=simple
ExecStart=/usr/bin/socat -T 30 UDP4-LISTEN:51820,reuseaddr,fork UDP4:10.9.0.2:51820
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable wireguard-udp-forward.service
systemctl restart wireguard-udp-forward.service
echo "✓ UDP forwarding service started"
echo ""

# Check status
sleep 2
echo "Service status:"
systemctl status wireguard-udp-forward.service --no-pager | head -10
echo ""

echo "Listening ports:"
ss -ulnp | grep 51820
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "socat is now forwarding UDP packets:"
echo "  0.0.0.0:51820 → 10.9.0.2:51820 (through wg-tunnel)"
echo ""
echo "This preserves WireGuard protocol integrity!"
echo ""
echo "Test from your phone now:"
echo "  1. Disconnect VPN"
echo "  2. Reconnect VPN"
echo "  3. Try browsing"
echo ""
