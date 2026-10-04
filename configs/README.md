# Configuration Examples

This directory contains sanitized configuration examples from the Enterprise Healthcare Hybrid Cloud project.

Sensitive values including VPN pre-shared keys, credentials, and environment-specific authentication information have been removed.

## Files

- `swanctl-sanitized.conf` — strongSwan IPsec configuration for redundant AWS VPN tunnels
- `hc-tunnel1-example.sh` — Linux VTI configuration for the primary VPN tunnel
- `hc-tunnel2-example.sh` — Linux VTI configuration for the backup VPN tunnel
- `hc-vpn-recovery-example.sh` — Automated CHILD_SA monitoring and recovery

These files are provided for portfolio and educational purposes.
