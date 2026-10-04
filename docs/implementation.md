# Implementation Guide

## Enterprise Healthcare Hybrid Cloud Architecture

This document summarizes the implementation of a simulated healthcare hybrid-cloud environment connecting an on-premises hospital network to AWS through redundant Site-to-Site IPsec VPN tunnels.

---

## 1. Network Architecture

Two separate network environments were created.

### Simulated Hospital Environment

```text
VPC: 10.20.0.0/16
Hospital LAN: 10.20.10.0/24
Management/VPN Network: 10.20.100.0/24
```

Key systems:

```text
HC-Hospital-Test-Server
10.20.10.62

HC-OnPrem-VPN-Router
Ubuntu + strongSwan
```

### AWS Healthcare Cloud

```text
VPC: 10.30.0.0/16
Application Subnet: 10.30.11.0/24
Database Subnet: 10.30.12.0/24
```

Connectivity testing used:

```text
HC-Cloud-Test-Server
10.30.11.37
```

---

## 2. AWS Site-to-Site VPN

An AWS Site-to-Site VPN was configured between the simulated hospital network and the AWS healthcare cloud.

The VPN provides two redundant IPsec tunnels.

```text
Tunnel1 = Primary
Tunnel2 = Backup
```

Both tunnels were validated as operational in the AWS console.

---

## 3. strongSwan

The Ubuntu VPN router uses strongSwan for IPsec.

The configuration uses separate strongSwan connections for:

```text
Tunnel1
Tunnel2
```

Each connection uses a separate AWS VPN endpoint and pre-shared key.

Sensitive PSKs are intentionally excluded from this repository.

A sanitized configuration example is available at:

```text
configs/swanctl-sanitized.conf
```

---

## 4. Linux VTI Interfaces

Linux Virtual Tunnel Interfaces were created to provide route-based IPsec connectivity.

```text
Tunnel1
Tunnel2
```

The interfaces allow standard Linux routing to control which VPN tunnel carries traffic.

---

## 5. Primary and Backup Routing

The AWS cloud network is:

```text
10.30.0.0/16
```

Two routes were configured:

```text
10.30.0.0/16 dev Tunnel1 metric 100
10.30.0.0/16 dev Tunnel2 metric 200
```

The lower metric causes Tunnel1 to operate as the preferred path.

Tunnel2 remains available as the backup path.

---

## 6. Linux Forwarding

IPv4 forwarding was enabled on the VPN router:

```bash
net.ipv4.ip_forward = 1
```

This allows the Ubuntu system to forward traffic between the hospital network and the encrypted VPN path.

---

## 7. Persistent Configuration

Custom systemd services were used to recreate the VTI interfaces and routes after a system reboot.

The configuration restores:

- Tunnel1
- Tunnel2
- VTI addressing
- MTU configuration
- VTI kernel parameters
- Primary route
- Backup route

The environment was reboot-tested to confirm persistence.

---

## 8. Automated Recovery

A custom recovery script monitors the strongSwan CHILD_SAs.

If either CHILD_SA is missing, the script initiates the corresponding tunnel using `swanctl`.

A systemd timer executes the recovery check every 60 seconds.

Example:

```text
Tunnel2 CHILD_SA missing
        |
        v
Recovery service detects failure
        |
        v
swanctl --initiate --child Tunnel2-child
        |
        v
Tunnel restored
```

A sanitized version is available at:

```text
configs/hc-vpn-recovery-example.sh
```

---

## 9. Validation

The architecture was validated using:

```bash
ping
ip route
ip rule
swanctl
journalctl
tcpdump
systemctl
```

Successful testing demonstrated:

- Both AWS VPN tunnels operational
- Primary/backup routing
- End-to-end private connectivity
- Packet traversal through the VTI
- Tunnel2 failover
- VTI persistence after reboot
- Automated CHILD_SA recovery

---

## Result

The final architecture provides redundant encrypted connectivity between the simulated hospital network and AWS while demonstrating hybrid networking, Linux routing, VPN failover, troubleshooting, and operational automation.
