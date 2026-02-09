#!/bin/bash
# Fix Pi VPN after restart
# This script addresses common issues after Pi restart
# Run on: Pi server as root

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Fixing Pi VPN After Restart"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

# Step 1: Enable IP forwarding permanently
echo "Step 1: Enabling IP forwarding..."
if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
  echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
  echo "✓ Added to /etc/sysctl.conf"
fi
sysctl -w net.ipv4.ip_forward=1
echo "✓ IP forwarding enabled"
echo ""

# Step 2: Restart tunnel
echo "Step 2: Restarting tunnel interface..."
wg-quick down wg-tunnel 2>/dev/null || true
wg-quick up wg-tunnel
systemctl enable wg-quick@wg-tunnel
echo "✓ Tunnel restarted"
echo ""

# Step 3: Fix wg0 config (wlan0 -> eth0)
echo "Step 3: Checking wg0 config for correct interface..."
if [ -f /etc/wireguard/wg0.conf ]; then
  if grep -q "wlan0" /etc/wireguard/wg0.conf; then
    echo "⚠ Found wlan0 in config, changing to eth0..."
    cp /etc/wireguard/wg0.conf /etc/wireguard/wg0.conf.backup.$(date +%Y%m%d_%H%M%S)
    sed -i 's/wlan0/eth0/g' /etc/wireguard/wg0.conf
    echo "✓ Configuration fixed"
  else
    echo "✓ Configuration is correct"
  fi
else
  echo "✗ wg0.conf not found!"
  exit 1
fi
echo ""

# Step 4: Restart VPN server
echo "Step 4: Restarting VPN server (wg0)..."
wg-quick down wg0 2>/dev/null || true
wg-quick up wg0
systemctl enable wg-quick@wg0
echo "✓ VPN server restarted"
echo ""

# Step 5: Verify NAT rules
echo "Step 5: Verifying NAT/MASQUERADE rules..."
sleep 2
if iptables -t nat -L POSTROUTING -n -v | grep -q MASQUERADE; then
  echo "✓ MASQUERADE rules are active"
  iptables -t nat -L POSTROUTING -n -v | grep MASQUERADE
else
  echo "✗ Warning: No MASQUERADE rules found!"
  echo "⚠ This means PostUp didn't run correctly - checking..."
fi
echo ""

# Step 6: Verify FORWARD rules
echo "Step 6: Verifying FORWARD rules..."
if iptables -L FORWARD -n -v | grep -q wg0; then
  echo "✓ FORWARD rules are active"
  iptables -L FORWARD -n -v | grep wg0
else
  echo "✗ Warning: No wg0 FORWARD rules found!"
fi
echo ""

# Step 7: Test connectivity
echo "Step 7: Testing connectivity..."
sleep 2

echo -n "  Tunnel to relay: "
if ping -c 2 -W 3 10.9.0.1 &>/dev/null; then
  echo "✓ OK"
else
  echo "✗ FAILED"
fi

echo -n "  Internet access: "
if ping -c 2 -W 3 8.8.8.8 &>/dev/null; then
  echo "✓ OK"
else
  echo "✗ FAILED"
fi
echo ""

# Step 8: Show status
echo "Step 8: Current status..."
echo "WireGuard Interfaces:"
wg show all | grep -E "interface|peer|handshake|transfer" || echo "No interfaces active"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Fix Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Services enabled at boot:"
echo "  - wg-quick@wg0 (VPN server)"
echo "  - wg-quick@wg-tunnel (Tunnel to relay)"
echo ""
echo "Test from phone now - connect to WireGuard VPN"
echo ""
