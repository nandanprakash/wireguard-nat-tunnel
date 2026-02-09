#!/bin/bash
# =============================================================================
# WireGuard NAT Tunnel Configuration
# =============================================================================
# This file contains all the configuration needed to set up your VPN.
# Edit the values below to match your infrastructure.
#
# REQUIRED: Only change these minimal settings to get started:
#   1. RELAY_DOMAIN - Your relay server's public domain/IP
#   2. SSH credentials if different from defaults
# =============================================================================

# -----------------------------------------------------------------------------
# 1. DOMAIN CONFIGURATION (REQUIRED)
# -----------------------------------------------------------------------------
# Your relay server's public domain name or IP address
# This is what VPN clients will connect to
# Example: "vpn.example.com" or "203.0.113.45"
RELAY_DOMAIN="your-relay-server.com"

# -----------------------------------------------------------------------------
# 2. SSH CONFIGURATION
# -----------------------------------------------------------------------------
# SSH credentials for accessing both servers
SSH_USER="ubuntu"                   # SSH username for both servers
SSH_PASSWORD="YourSecurePassword"   # Change this! (or use SSH keys)
RELAY_SSH_PORT="22"                 # SSH port for relay server
VPN_SERVER_SSH_PORT="2222"          # SSH port for VPN server (forwarded through relay)

# -----------------------------------------------------------------------------
# 3. NETWORK CONFIGURATION (Advanced - defaults usually work fine)
# -----------------------------------------------------------------------------
# VPN Client Network: IP range for devices connecting to your VPN
# Default: 10.8.0.0/24 gives you 254 possible VPN clients
VPN_NETWORK="10.8.0.0/24"
VPN_GATEWAY="10.8.0.1"              # VPN server's IP in the client network

# Tunnel Network: Private network between relay and VPN server
# Default: 10.9.0.0/30 gives you 2 usable IPs (minimal)
TUNNEL_NETWORK="10.9.0.0/30"
TUNNEL_RELAY_IP="10.9.0.1"          # Relay server's tunnel IP
TUNNEL_VPN_IP="10.9.0.2"            # VPN server's tunnel IP

# -----------------------------------------------------------------------------
# 4. PORT CONFIGURATION (Advanced - defaults usually work fine)
# -----------------------------------------------------------------------------
WIREGUARD_PORT="51820"              # Port VPN clients connect to
WIREGUARD_TUNNEL_PORT="51821"       # Port for relay-to-VPN-server tunnel
SSH_FORWARD_PORT="2222"             # Port for SSH access to VPN server

# -----------------------------------------------------------------------------
# 5. DNS CONFIGURATION
# -----------------------------------------------------------------------------
# DNS servers that VPN clients will use
# Default: Google DNS (8.8.8.8, 8.8.4.4)
# Alternative: Cloudflare DNS (1.1.1.1, 1.0.0.1)
VPN_DNS_SERVERS="8.8.8.8, 8.8.4.4"

# -----------------------------------------------------------------------------
# 6. CLIENT CONFIGURATION (Optional)
# -----------------------------------------------------------------------------
# Default IP addresses for pre-configured clients
# These are used by the generate-phone-qr.sh script
CLIENT_PHONE_IP="10.8.0.5"
CLIENT_LAPTOP_IP="10.8.0.3"
CLIENT_TABLET_IP="10.8.0.4"

# -----------------------------------------------------------------------------
# 7. ADVANCED SETTINGS (Don't change unless you know what you're doing)
# -----------------------------------------------------------------------------
WIREGUARD_MTU="1420"                # WireGuard MTU (standard value)
PERSISTENT_KEEPALIVE="25"           # Keepalive interval in seconds

# Auto-detected settings (leave empty for auto-detection)
RELAY_INTERFACE=""                  # Network interface on relay (e.g., eth0)
RELAY_LOCAL_IP=""                   # Local IP of relay server
VPN_INTERFACE=""                    # Network interface on VPN server (e.g., eth0, wlan0)
VPN_LOCAL_IP=""                     # Local IP of VPN server

# =============================================================================
# CONFIGURATION GUIDE
# =============================================================================
#
# Minimal Setup (Quick Start):
# 1. Change RELAY_DOMAIN to your relay server's public domain/IP
# 2. Change SSH_PASSWORD to a secure password
# 3. Run relay-wireguard-setup.sh on your relay server
# 4. Run pi-wireguard-tunnel-setup.sh on your VPN server
# 5. Generate client configs with generate-phone-qr.sh
#
# Network Topology:
#   VPN Clients (anywhere)
#       ↓ connects to
#   Relay Server (public IP: RELAY_DOMAIN:51820)
#       ↓ tunnel via WireGuard
#   VPN Server (behind NAT: TUNNEL_VPN_IP)
#       ↓ NAT masquerade
#   Internet
#
# Port Forwarding Required on Relay Server's Router:
#   - UDP 51820 → Relay Server (for VPN clients)
#   - UDP 51821 → Relay Server (for VPN server tunnel)
#   - TCP 2222  → Relay Server (for SSH to VPN server)
#
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
