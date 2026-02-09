#!/bin/bash
# Fix relay DNAT to forward to correct Pi IP
# Should forward to 10.9.0.2:51820 (Pi tunnel IP) not 10.8.0.1:51820 (VPN internal IP)
# Run on: Relay server (port 22)

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Fixing Relay DNAT Rule"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

echo "Current DNAT rule:"
iptables -t nat -L PREROUTING -n -v | grep 51820
echo ""

echo "Removing old DNAT rule..."
iptables -t nat -D PREROUTING -p udp --dport 51820 -j DNAT --to-destination 10.8.0.1:51820 2>/dev/null || echo "Old rule not found"
echo "✓ Old rule removed"
echo ""

echo "Adding correct DNAT rule (to 10.9.0.2:51820)..."
iptables -t nat -I PREROUTING 1 -p udp --dport 51820 -j DNAT --to-destination 10.9.0.2:51820
echo "✓ New rule added"
echo ""

echo "New DNAT rule:"
iptables -t nat -L PREROUTING -n -v | grep 51820
echo ""

echo "Also updating wg-tunnel.conf for persistence..."
sed -i 's/10\.8\.0\.1:51820/10.9.0.2:51820/g' /etc/wireguard/wg-tunnel.conf
echo "✓ Config file updated"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Fix Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "The DNAT now correctly forwards to:"
echo "  pi.nandanprakash.com:51820 → 10.9.0.2:51820 (Pi tunnel IP)"
echo ""
echo "Test from your phone now - disconnect and reconnect VPN!"
echo ""
