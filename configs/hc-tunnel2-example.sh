#!/bin/bash
#
# Backup AWS VPN VTI - Sanitized Portfolio Example
# Enterprise Healthcare Hybrid Cloud Architecture
#

set -e

TUNNEL="Tunnel2"
LOCAL_IP="<CUSTOMER_GATEWAY_PRIVATE_IP>"
REMOTE_IP="<AWS_TUNNEL_2_OUTSIDE_IP>"
LOCAL_INSIDE="<TUNNEL_2_LOCAL_INSIDE_IP>/30"
REMOTE_INSIDE="<TUNNEL_2_AWS_INSIDE_IP>/30"
MARK="200"
CLOUD_NETWORK="10.30.0.0/16"

# Remove stale interface if present
ip link del "$TUNNEL" 2>/dev/null || true

# Create Virtual Tunnel Interface
ip link add "$TUNNEL" type vti \
    local "$LOCAL_IP" \
    remote "$REMOTE_IP" \
    key "$MARK"

# Configure AWS inside-tunnel addressing
ip addr add "$LOCAL_INSIDE" \
    remote "$REMOTE_INSIDE" \
    dev "$TUNNEL"

# Configure interface
ip link set "$TUNNEL" mtu 1419
ip link set "$TUNNEL" up

# VTI kernel settings
sysctl -w net.ipv4.conf."$TUNNEL".rp_filter=2
sysctl -w net.ipv4.conf."$TUNNEL".disable_policy=1

# Backup route to AWS
ip route replace "$CLOUD_NETWORK" \
    dev "$TUNNEL" \
    metric 200

exit 0
