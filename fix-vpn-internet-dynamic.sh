#!/bin/bash
# Fix VPN Internet Connectivity with Dynamic Interface Detection
# This script makes WireGuard automatically use whatever interface has internet
# Run on: Pi VPN server (port 2222)

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Fixing VPN Internet with Dynamic Interface"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

# Step 1: Detect active internet interface
echo "Step 1: Detecting active internet interface..."
DEFAULT_IFACE=$(ip route show default | awk '/default/ {print $5}')
if [ -z "$DEFAULT_IFACE" ]; then
  echo "✗ Error: No default route found!"
  exit 1
fi
echo "✓ Active interface: $DEFAULT_IFACE"
echo ""

# Step 2: Backup current config
echo "Step 2: Backing up current configuration..."
cp /etc/wireguard/wg0.conf /etc/wireguard/wg0.conf.backup.$(date +%Y%m%d_%H%M%S)
echo "✓ Backup created"
echo ""

# Step 3: Stop WireGuard to clean up rules
echo "Step 3: Stopping WireGuard to clean up old rules..."
wg-quick down wg0 2>/dev/null || true
echo "✓ WireGuard stopped"
echo ""

# Step 4: Clean up ALL old NAT and FORWARD rules
echo "Step 4: Cleaning up old iptables rules..."

# Remove all MASQUERADE rules
iptables -t nat -D POSTROUTING -o wlan0 -j MASQUERADE 2>/dev/null || true
iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || true
iptables -t nat -D POSTROUTING -o $DEFAULT_IFACE -j MASQUERADE 2>/dev/null || true

# Remove old FORWARD rules for wg0
iptables -D FORWARD -i wg0 -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -o wg0 -j ACCEPT 2>/dev/null || true

echo "✓ Old rules cleaned"
echo ""

# Step 5: Update wg0.conf with dynamic interface detection
echo "Step 5: Updating configuration with dynamic interface detection..."

# Remove old PostUp/PostDown lines
sed -i '/^PostUp/d' /etc/wireguard/wg0.conf
sed -i '/^PostDown/d' /etc/wireguard/wg0.conf

# Find the line with ListenPort to insert after it
sed -i "/^ListenPort/a\\
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o \$(ip route show default | awk '/default/ {print \$5}') -j MASQUERADE\\
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o \$(ip route show default | awk '/default/ {print \$5}') -j MASQUERADE" /etc/wireguard/wg0.conf

echo "✓ Configuration updated with dynamic interface detection"
echo ""

# Step 6: Enable IP forwarding
echo "Step 6: Ensuring IP forwarding is enabled..."
if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
  echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi
sysctl -w net.ipv4.ip_forward=1 > /dev/null
echo "✓ IP forwarding enabled"
echo ""

# Step 7: Restart WireGuard
echo "Step 7: Starting WireGuard with new configuration..."
wg-quick up wg0
systemctl enable wg-quick@wg0
echo "✓ WireGuard started"
echo ""

# Step 8: Verify the setup
echo "Step 8: Verifying configuration..."
sleep 2

echo ""
echo "Active interface: $DEFAULT_IFACE"
echo ""
echo "NAT/MASQUERADE rules:"
iptables -t nat -L POSTROUTING -n -v | grep MASQUERADE || echo "  No MASQUERADE rules found!"
echo ""
echo "FORWARD rules:"
iptables -L FORWARD -n -v | grep wg0 || echo "  No wg0 FORWARD rules found!"
echo ""

# Step 9: Test connectivity
echo "Step 9: Testing connectivity..."
echo -n "  Tunnel to relay: "
if ping -c 2 -W 3 10.9.0.1 &>/dev/null; then
  echo "✓ OK"
else
  echo "✗ FAILED"
fi

echo -n "  Internet (8.8.8.8): "
if ping -c 2 -W 3 8.8.8.8 &>/dev/null; then
  echo "✓ OK"
else
  echo "✗ FAILED"
fi

echo -n "  DNS (google.com): "
if ping -c 2 -W 3 google.com &>/dev/null; then
  echo "✓ OK"
else
  echo "✗ FAILED (DNS might need configuration)"
fi
echo ""

# Step 10: Show WireGuard status
echo "Step 10: WireGuard status..."
wg show wg0 | head -20
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Fix Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Configuration now uses dynamic interface detection."
echo "WireGuard will automatically use: $DEFAULT_IFACE (or any active interface)"
echo ""
echo "If you switch from ethernet to wifi (or vice versa), just restart:"
echo "  sudo wg-quick down wg0 && sudo wg-quick up wg0"
echo ""
echo "Test from phone now - connect to WireGuard VPN and try browsing."
echo ""
