#!/bin/bash
# Fix relay to SNAT packets going to Pi so replies can come back
# Run on: Relay server (port 22)

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Adding SNAT for DNATed VPN packets"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

echo "Adding SNAT rule for packets going to 10.9.0.2:51820..."
# When packets are DNATed to 10.9.0.2:51820, also SNAT them so Pi sees relay IP
iptables -t nat -I POSTROUTING 1 -d 10.9.0.2 -p udp --dport 51820 -j SNAT --to-source 10.9.0.1
echo "✓ SNAT rule added"
echo ""

echo "Current POSTROUTING rules:"
iptables -t nat -L POSTROUTING -n -v | head -15
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Fix Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Packets to Pi VPN are now both DNATed and SNATed"
echo "This should fix the return path issue"
echo ""
echo "Disconnect and reconnect your phone VPN now!"
echo ""
