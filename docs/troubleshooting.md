# Hybrid VPN Troubleshooting Case Study

## Overview

During implementation of the healthcare hybrid-cloud environment, the IPsec VPN tunnels successfully established but workload traffic initially failed to reach the AWS cloud network.

This required troubleshooting across AWS networking, Linux routing, strongSwan, VTI interfaces, and policy routing.

---

# Incident 1 — VPN Up but Traffic Failing

## Symptom

The hospital workload:

```text
10.20.10.62
```

attempted to reach the AWS cloud workload:

```text
10.30.11.37
```

Testing resulted in:

```text
100% packet loss
```

The AWS VPN itself was operational, indicating that tunnel status alone was not sufficient to identify the problem.

---

## Packet Capture

`tcpdump` was used on the Ubuntu VPN router:

```bash
sudo tcpdump -ni any host 10.30.11.37
```

Packets from the hospital server successfully reached the VPN router.

However, traffic was initially leaving through the normal network interface instead of the expected VTI.

This narrowed the problem to the VPN router's routing behavior.

---

## Routing Investigation

The routing decision was inspected:

```bash
ip route get 10.30.11.37
```

The system returned a path through the normal `ens5` gateway rather than `Tunnel1`.

Linux policy routing was then inspected:

```bash
ip rule show
```

The output included:

```text
0:      from all lookup local
220:    from all lookup 220
32766:  from all lookup main
32767:  from all lookup default
```

This showed that routing table `220` was evaluated before the main routing table.

---

## Root Cause

Table 220 contained:

```text
default via 10.20.100.1 dev ens5
```

The main routing table correctly contained:

```text
10.30.0.0/16 dev Tunnel1 metric 100
```

However, because table 220 was evaluated first, the default route captured traffic destined for AWS before Linux reached the correct route in the main table.

---

## Resolution

The conflicting table-220 default route was removed.

The routing decision was checked again:

```bash
ip route get 10.30.11.37
```

Traffic now selected the VTI path.

---

## Verification

Another packet capture produced:

```text
ens5     IN    10.20.10.62 > 10.30.11.37
Tunnel1  OUT   10.20.10.62 > 10.30.11.37

Tunnel1  IN    10.30.11.37 > 10.20.10.62
ens5     OUT   10.30.11.37 > 10.20.10.62
```

The hospital server then received successful ICMP replies with:

```text
0% packet loss
```

---

# Incident 2 — VPN Tunnels Down After Extended Runtime

## Symptom

Several days after successful deployment, AWS reported both Site-to-Site VPN tunnels as DOWN.

The strongSwan service itself remained:

```text
active (running)
```

However:

```bash
swanctl --list-sas
```

did not show active security associations.

---

## Log Analysis

strongSwan logs were inspected using:

```bash
journalctl -u strongswan
```

The logs showed communication with the AWS peers, including Dead Peer Detection traffic.

The logs also showed CHILD_SA/IKE_SA deletion activity.

This indicated that basic network reachability to AWS still existed even though the IPsec security associations were no longer active.

---

## Recovery Test

The CHILD_SA was explicitly initiated:

```bash
sudo swanctl --initiate --child Tunnel1-child
```

The tunnel successfully re-established.

Tunnel2 was then restored in the same manner.

AWS subsequently reported both tunnels as UP.

---

## Long-Term Resolution

Rather than relying on manual recovery, a self-healing mechanism was implemented.

A script periodically checks:

```bash
swanctl --list-sas
```

If `Tunnel1-child` or `Tunnel2-child` is missing, the appropriate tunnel is initiated automatically.

A systemd timer runs the health check every 60 seconds.

---

# Lessons Learned

This troubleshooting process demonstrated several important principles:

1. An IPsec tunnel showing UP does not guarantee workload traffic is using the correct route.
2. Linux policy routing can override routes that appear correct in the main routing table.
3. `ip route get` is extremely useful for identifying the actual routing decision.
4. `tcpdump` provides packet-level proof of the traffic path.
5. Service status alone does not guarantee active IPsec security associations.
6. Operational recovery should be automated when a predictable failure mode is identified.

The troubleshooting process ultimately improved the architecture by adding both routing corrections and automated VPN recovery.
