#!/bin/bash
# Configuration file for Pi VPN Router
# Edit these variables to match your setup

# ============================================
# Domain & Network Configuration
# ============================================
DOMAIN_NAME="pi.nandanprakash.com"
RELAY_PUBLIC_IP=""  # Leave empty to auto-detect

# ============================================
# SSH Configuration
# ============================================
SSH_USER="ubuntu"
SSH_PASSWORD="NandanPi2121"  # Consider using SSH keys instead
RELAY_SSH_PORT="22"
PI_SSH_PORT="2222"

# ============================================
# Network Configuration
# ============================================
# VPN Client Network (for phones/laptops connecting to VPN)
VPN_NETWORK="10.8.0.0/24"
VPN_GATEWAY="10.8.0.1"

# Tunnel Network (between Relay and Pi)
TUNNEL_NETWORK="10.9.0.0/30"
TUNNEL_RELAY_IP="10.9.0.1"
TUNNEL_PI_IP="10.9.0.2"

# ============================================
# Port Configuration
# ============================================
WIREGUARD_VPN_PORT="51820"      # Port for VPN clients (phones/laptops)
WIREGUARD_TUNNEL_PORT="51821"   # Port for relay-to-Pi tunnel
SSH_FORWARD_PORT="2222"         # Port for SSH access to Pi through relay

# ============================================
# DNS Configuration
# ============================================
VPN_DNS_SERVERS="8.8.8.8, 8.8.4.4"  # DNS servers for VPN clients

# ============================================
# Client Configuration
# ============================================
# Default client IPs (for pre-configured clients)
CLIENT_PHONE_IP="10.8.0.5"
CLIENT_LAPTOP_IP="10.8.0.3"
CLIENT_TABLET_IP="10.8.0.4"

# ============================================
# Advanced Configuration
# ============================================
WIREGUARD_MTU="1420"
PERSISTENT_KEEPALIVE="25"  # seconds

# ============================================
# Relay Server Configuration
# ============================================
# These will be detected automatically if not set
RELAY_INTERFACE=""  # e.g., eth0, ens3 (auto-detected if empty)
RELAY_LOCAL_IP=""   # e.g., 192.168.86.115 (auto-detected if empty)

# ============================================
# Pi Server Configuration
# ============================================
# These will be detected automatically if not set
PI_INTERFACE=""     # e.g., eth0, wlan0 (auto-detected if empty)
PI_LOCAL_IP=""      # e.g., 192.168.0.104 (auto-detected if empty)

# ============================================
# Export all variables
# ============================================
export DOMAIN_NAME SSH_USER SSH_PASSWORD RELAY_SSH_PORT PI_SSH_PORT
export VPN_NETWORK VPN_GATEWAY TUNNEL_NETWORK TUNNEL_RELAY_IP TUNNEL_PI_IP
export WIREGUARD_VPN_PORT WIREGUARD_TUNNEL_PORT SSH_FORWARD_PORT
export VPN_DNS_SERVERS CLIENT_PHONE_IP CLIENT_LAPTOP_IP CLIENT_TABLET_IP
export WIREGUARD_MTU PERSISTENT_KEEPALIVE
export RELAY_INTERFACE RELAY_LOCAL_IP PI_INTERFACE PI_LOCAL_IP RELAY_PUBLIC_IP

echo "✓ Configuration loaded from config.sh"
