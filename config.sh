#!/bin/bash
# =============================================================================
# WireGuard NAT Tunnel Configuration
# =============================================================================
# Edit the values below to match your setup.
#
# REQUIRED CHANGES:
#   1. RELAY_DOMAIN - Your relay server's hostname or IP
#   2. SSH_PASSWORD - Change from default
#
# Everything else has sensible defaults.
# =============================================================================

# -----------------------------------------------------------------------------
# RELAY SERVER DOMAIN (REQUIRED)
# -----------------------------------------------------------------------------
# Your relay server's hostname or IP address
# VPN clients connect to this address
# Examples: "vpn.example.com" or "203.0.113.45"
RELAY_DOMAIN="your-relay-server.com"

# -----------------------------------------------------------------------------
# SSH CONFIGURATION
# -----------------------------------------------------------------------------
SSH_USER="ubuntu"                   # SSH username for both servers
SSH_PASSWORD="YourSecurePassword"   # CHANGE THIS! (or preferably use SSH keys)
RELAY_SSH_PORT="22"                 # Direct SSH port for relay
VPN_SERVER_SSH_PORT="2222"          # SSH to VPN server via relay:2222

# -----------------------------------------------------------------------------
# NETWORK CONFIGURATION (defaults work fine)
# -----------------------------------------------------------------------------
# VPN client network - IP range for devices connecting to your VPN
VPN_NETWORK="10.8.0.0/24"           # 254 possible clients
VPN_GATEWAY="10.8.0.1"              # VPN server IP

# Tunnel network - private link between relay and VPN server
TUNNEL_NETWORK="10.9.0.0/30"        # Just 2 IPs (relay and VPN server)
TUNNEL_RELAY_IP="10.9.0.1"
TUNNEL_VPN_IP="10.9.0.2"

# -----------------------------------------------------------------------------
# PORT CONFIGURATION (change if needed)
# -----------------------------------------------------------------------------
# These ports must be open/forwarded on your relay server
WIREGUARD_PORT="51820"              # VPN clients connect here
WIREGUARD_TUNNEL_PORT="51821"       # VPN server tunnel connects here
SSH_FORWARD_PORT="2222"             # SSH to VPN server via relay (optional)

# Change these if:
# - Default ports are blocked by your ISP
# - You want to run multiple VPN setups on same relay
# - Your relay already uses these ports for something else

# -----------------------------------------------------------------------------
# DNS CONFIGURATION
# -----------------------------------------------------------------------------
# DNS servers for VPN clients
# Google DNS (default) or Cloudflare (1.1.1.1, 1.0.0.1)
VPN_DNS_SERVERS="8.8.8.8, 8.8.4.4"

# -----------------------------------------------------------------------------
# CLIENT IPS (used by generate scripts)
# -----------------------------------------------------------------------------
CLIENT_PHONE_IP="10.8.0.5"
CLIENT_LAPTOP_IP="10.8.0.3"
CLIENT_TABLET_IP="10.8.0.4"

# -----------------------------------------------------------------------------
# ADVANCED (don't change unless needed)
# -----------------------------------------------------------------------------
WIREGUARD_MTU="1420"
PERSISTENT_KEEPALIVE="25"

# Leave empty for auto-detection
RELAY_INTERFACE=""
RELAY_LOCAL_IP=""
VPN_INTERFACE=""
VPN_LOCAL_IP=""

# =============================================================================
# QUICK START
# =============================================================================
# 1. Set RELAY_DOMAIN to your relay server's hostname
# 2. Change SSH_PASSWORD
# 3. (Optional) Customize ports if defaults don't work for you
# 4. Open/forward the configured ports on your relay server
# 5. Run relay-wireguard-setup.sh on relay server
# 6. Run pi-wireguard-tunnel-setup.sh on VPN server
# 7. Connect relay and VPN server (see README)
# 8. Generate client configs with generate-phone-qr.sh
#
# IMPORTANT: Open these ports on your relay server:
#   - WIREGUARD_PORT (default 51820/UDP) - for VPN clients
#   - WIREGUARD_TUNNEL_PORT (default 51821/UDP) - for VPN server tunnel
#   - SSH_FORWARD_PORT (default 2222/TCP) - for SSH access (optional)
# =============================================================================

# Export all variables for use in other scripts
export RELAY_DOMAIN SSH_USER SSH_PASSWORD RELAY_SSH_PORT VPN_SERVER_SSH_PORT
export VPN_NETWORK VPN_GATEWAY TUNNEL_NETWORK TUNNEL_RELAY_IP TUNNEL_VPN_IP
export WIREGUARD_PORT WIREGUARD_TUNNEL_PORT SSH_FORWARD_PORT
export VPN_DNS_SERVERS CLIENT_PHONE_IP CLIENT_LAPTOP_IP CLIENT_TABLET_IP
export WIREGUARD_MTU PERSISTENT_KEEPALIVE
export RELAY_INTERFACE RELAY_LOCAL_IP VPN_INTERFACE VPN_LOCAL_IP

echo "✓ Configuration loaded from config.sh"
echo "  Relay: $RELAY_DOMAIN"
echo "  VPN Network: $VPN_NETWORK"
