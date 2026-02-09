#!/bin/bash
# Fix relay server to properly forward VPN traffic
# The relay has a DROP policy on FORWARD chain, blocking VPN packets
# Run on: Relay server (port 22)

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Fixing Relay Server FORWARD Rules"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

echo "Current FORWARD policy:"
iptables -L FORWARD -n -v | head -1
echo ""

echo "Adding FORWARD rules for VPN traffic..."

# Allow forwarding for traffic to/from the VPN network
iptables -I FORWARD 1 -d 10.8.0.0/24 -j ACCEPT
iptables -I FORWARD 1 -s 10.8.0.0/24 -j ACCEPT

# Allow forwarding through wg-tunnel
iptables -I FORWARD 1 -i wg-tunnel -j ACCEPT
iptables -I FORWARD 1 -o wg-tunnel -j ACCEPT

echo "✓ FORWARD rules added"
echo ""

echo "New FORWARD chain (top rules):"
iptables -L FORWARD -n -v | head -10
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Fix Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "NOTE: These rules are NOT persistent across reboots."
echo "To make them persistent, you need to:"
echo "  1. Install iptables-persistent: apt-get install iptables-persistent"
echo "  2. Save rules: iptables-save > /etc/iptables/rules.v4"
echo "OR add them to the wg-tunnel PostUp in /etc/wireguard/wg-tunnel.conf"
echo ""
echo "Test from your phone now - VPN should have internet!"
echo ""
