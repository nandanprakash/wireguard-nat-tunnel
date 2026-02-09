#!/bin/bash
# Diagnostic script for Pi VPN connectivity issues
# Run this on the Pi server to diagnose VPN problems

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Pi VPN Diagnostic Report"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "1. IP Forwarding Status:"
echo "-------------------------"
sysctl net.ipv4.ip_forward
echo ""

echo "2. WireGuard Interfaces:"
echo "-------------------------"
sudo wg show all
echo ""

echo "3. WireGuard Services Status:"
echo "-------------------------"
systemctl status wg-quick@wg0.service --no-pager || echo "wg0 service not active"
echo ""
systemctl status wg-quick@wg-tunnel.service --no-pager || echo "wg-tunnel service not active"
echo ""

echo "4. NAT/Masquerade Rules:"
echo "-------------------------"
sudo iptables -t nat -L POSTROUTING -n -v | grep MASQUERADE || echo "No MASQUERADE rules found!"
echo ""

echo "5. Forward Rules:"
echo "-------------------------"
sudo iptables -L FORWARD -n -v | grep wg0 || echo "No wg0 forward rules found!"
echo ""

echo "6. Network Interfaces:"
echo "-------------------------"
ip addr show | grep -E "^[0-9]+:|inet " | grep -E "wg0|wg-tunnel|eth0"
echo ""

echo "7. Tunnel Connectivity:"
echo "-------------------------"
ping -c 3 10.9.0.1 2>/dev/null && echo "✓ Tunnel to relay OK" || echo "✗ Cannot reach relay"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Recommendations:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "If IP forwarding is 0, run: echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf && sudo sysctl -p"
echo "If wg0 is down, run: sudo wg-quick up wg0 && sudo systemctl enable wg-quick@wg0"
echo "If no MASQUERADE rules, run: sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE"
echo ""
