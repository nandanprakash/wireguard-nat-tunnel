#!/bin/bash
# Fix Pi routing to ensure VPN packets can reach internet
# Run on: Pi VPN server (port 2222)

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Fixing Pi VPN Routing and Forwarding"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

# Enable IP forwarding
echo "Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1 > /dev/null
sysctl -w net.ipv4.conf.all.forwarding=1 > /dev/null
sysctl -w net.ipv4.conf.wg0.forwarding=1 > /dev/null
echo "✓ IP forwarding enabled"
echo ""

# Disable reverse path filtering for wg0
echo "Disabling reverse path filtering for wg0..."
sysctl -w net.ipv4.conf.wg0.rp_filter=0 > /dev/null
sysctl -w net.ipv4.conf.all.rp_filter=0 > /dev/null
echo "✓ Reverse path filtering disabled"
echo ""

# Add explicit FORWARD rules with logging
echo "Adding explicit FORWARD rules..."
# Clear old rules
iptables -D FORWARD -i wg0 -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -o wg0 -j ACCEPT 2>/dev/null || true

# Add new rules at the top
iptables -I FORWARD 1 -i wg0 -o eth0 -j ACCEPT
iptables -I FORWARD 1 -i eth0 -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT
echo "✓ FORWARD rules added"
echo ""

# Ensure MASQUERADE is working
echo "Checking MASQUERADE rule..."
if ! iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null; then
    echo "Adding MASQUERADE rule..."
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    echo "✓ MASQUERADE added"
else
    echo "✓ MASQUERADE already exists"
fi
echo ""

# Test routing
echo "Testing routing from VPN network..."
DEFAULT_GW=$(ip route show default | awk '/default/ {print $3}')
echo "Default gateway: $DEFAULT_GW"
echo ""

echo "Current iptables summary:"
echo "  FORWARD rules:"
iptables -L FORWARD -n -v | head -6
echo ""
echo "  NAT POSTROUTING:"
iptables -t nat -L POSTROUTING -n -v | grep MASQUERADE
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Fix Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Try accessing the internet from your phone now!"
echo "Test by visiting: google.com or 8.8.8.8"
echo ""
