#!/bin/bash
#
# AWS Site-to-Site VPN Self-Healing
# Sanitized Portfolio Example
#
# Checks both strongSwan CHILD_SAs and automatically
# initiates a tunnel if its CHILD_SA is missing.
#

SWANCTL="/usr/sbin/swanctl"
LOGGER="/usr/bin/logger"

# Retrieve current IPsec SA state
SAS="$($SWANCTL --list-sas 2>/dev/null)"

# Check primary tunnel
if ! echo "$SAS" | grep -q "Tunnel1-child"; then

    $LOGGER -t hc-vpn-recovery \
        "Tunnel1 CHILD_SA missing - initiating"

    $SWANCTL --initiate \
        --child Tunnel1-child \
        >/dev/null 2>&1
fi

# Refresh SA state
SAS="$($SWANCTL --list-sas 2>/dev/null)"

# Check backup tunnel
if ! echo "$SAS" | grep -q "Tunnel2-child"; then

    $LOGGER -t hc-vpn-recovery \
        "Tunnel2 CHILD_SA missing - initiating"

    $SWANCTL --initiate \
        --child Tunnel2-child \
        >/dev/null 2>&1
fi

exit 0
