#!/bin/bash
# Remove SNAT and use MASQUERADE instead for relay forwarding
# Run on: Relay server (port 22)

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Fixing Relay NAT - Using MASQUERADE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

echo "Removing SNAT rule..."
iptables -t nat -D POSTROUTING -d 10.9.0.2 -p udp --dport 51820 -j SNAT --to-source 10.9.0.1 2>/dev/null || echo "SNAT rule not found"
echo "✓ SNAT removed"
echo ""

echo "Checking if MASQUERADE exists for forwarded packets..."
# Add MASQUERADE for packets going through wg-tunnel (if not exists)
if ! iptables -t nat -C POSTROUTING -o wg-tunnel -j MASQUERADE 2>/dev/null; then
    iptables -t nat -A POSTROUTING -o wg-tunnel -j MASQUERADE
    echo "✓ MASQUERADE added"
else
    echo "✓ MASQUERADE already exists"
fi
echo ""

echo "Current NAT rules:"
echo ""
echo "PREROUTING (DNAT):"
iptables -t nat -L PREROUTING -n -v | grep -E "51820|2222"
echo ""
echo "POSTROUTING (MASQUERADE):"
iptables -t nat -L POSTROUTING -n -v | grep -E "wg-tunnel|MASQUERADE" | head -5
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Fix Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "NAT configuration:"
echo "  - DNAT: pi.nandanprakash.com:51820 → 10.9.0.2:51820"
echo "  - MASQUERADE: Packets through wg-tunnel"
echo ""
echo "Disconnect and reconnect your phone VPN now!"
echo ""
