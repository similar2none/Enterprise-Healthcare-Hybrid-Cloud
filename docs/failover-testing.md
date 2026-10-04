# VPN Failover Testing

## Objective

Validate that the redundant AWS Site-to-Site VPN design can maintain connectivity when the preferred VPN path becomes unavailable.

---

## Normal Routing

The AWS cloud network is:

```text
10.30.0.0/16
```

Normal routes:

```text
10.30.0.0/16 dev Tunnel1 metric 100
10.30.0.0/16 dev Tunnel2 metric 200
```

Because Tunnel1 has the lower metric, it is selected as the preferred path.

---

## Baseline Test

Connectivity was verified from:

```text
HC-Hospital-Test-Server
10.20.10.62
```

to:

```text
HC-Cloud-Test-Server
10.30.11.37
```

The baseline test returned successful ICMP replies.

---

## Simulated Primary Path Failure

The preferred Tunnel1 route was temporarily removed to simulate loss of the primary path.

```bash
sudo ip route del 10.30.0.0/16 dev Tunnel1 metric 100
```

The routing decision was checked:

```bash
ip route get 10.30.11.37
```

Traffic selected:

```text
Tunnel2
```

---

## Backup Path Validation

A packet capture was started against Tunnel2 while traffic was generated from the hospital test server.

Successful ICMP request and reply traffic traversed the backup tunnel.

This demonstrated that Tunnel2 could provide working connectivity when the preferred route was unavailable.

---

## Primary Path Restoration

The primary route was restored:

```bash
sudo ip route add 10.30.0.0/16 dev Tunnel1 metric 100
```

Linux again selected Tunnel1 as the preferred route.

---

# Automated Recovery Test

A second test validated automatic IPsec recovery.

Tunnel2's CHILD_SA was intentionally terminated.

The custom recovery timer detected:

```text
Tunnel2 CHILD_SA missing - initiating
```

The service automatically initiated the missing CHILD_SA.

No manual tunnel initiation was performed.

Tunnel2 subsequently returned to an operational state.

---

# Reboot Test

The VPN router was rebooted to validate persistence.

After startup:

- strongSwan returned to service
- Tunnel1 VTI was recreated
- Tunnel2 VTI was recreated
- Primary and backup routes returned
- The recovery timer became active
- IPsec security associations were restored
- AWS reported both tunnels UP
- Hospital-to-cloud connectivity succeeded

---

# Test Results

| Test | Result |
|---|---|
| Tunnel1 normal operation | PASS |
| Tunnel2 operational | PASS |
| Primary route metric 100 | PASS |
| Backup route metric 200 | PASS |
| Hospital-to-AWS connectivity | PASS |
| Tunnel2 failover | PASS |
| Primary route restoration | PASS |
| Automatic CHILD_SA recovery | PASS |
| VTI persistence after reboot | PASS |
| VPN recovery after reboot | PASS |

---

## Conclusion

The testing validated both **network-path redundancy** and **operational recovery**.

The final design provides a preferred Tunnel1 path, a functional Tunnel2 backup path, persistent VTI configuration, and automated recovery of missing IPsec CHILD_SAs.
