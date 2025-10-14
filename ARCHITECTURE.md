# Architecture & Design

Detailed architecture and design decisions for the WireGuard Static IP VPN solution.

## System Architecture

### High-Level Overview

```
┌────────────────────────────────────────────────────────────────────┐
│                         Internet/Cloud                              │
│                                                                     │
│  Cloud Services with IP-based Access Control:                      │
│  • SSH Servers (port 22) - Restricted to 92.5.92.62               │
│  • Web Admin Panels - Restricted to 92.5.92.62                    │
│  • Database Servers - Restricted to 92.5.92.62                    │
│  • API Endpoints - Restricted to 92.5.92.62                       │
│                                                                     │
└────────────────────────────┬───────────────────────────────────────┘
                             │ All traffic appears from VPS IP
                             │
              ┌──────────────┴──────────────┐
              │   WireGuard VPN Server      │
              │   (Ubuntu 24.04 VPS)        │
              │                             │
              │   Public IP: 92.5.92.62     │
              │   Port: 51820/UDP           │
              │                             │
              │   Network Interfaces:       │
              │   ├─ enp0s6: 10.0.0.5      │ (Physical)
              │   ├─ wt0: 100.66.82.231    │ (NetBird)
              │   └─ wg0: 10.10.10.1       │ (WireGuard)
              │                             │
              │   Services:                 │
              │   ├─ WireGuard VPN         │
              │   ├─ NetBird Mesh          │
              │   ├─ Docker Containers     │
              │   └─ NAT/Routing           │
              └──────────────┬──────────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
    ┌────┴─────┐      ┌──────┴──────┐      ┌────┴─────┐
    │  Router  │      │   Mobile    │      │ Laptop   │
    │          │      │   Devices   │      │ Desktop  │
    │10.10.10.2│      │10.10.10.3-5 │      │10.10.10.4│
    └────┬─────┘      └─────────────┘      └──────────┘
         │
         │ Routes entire home network
         │
    ┌────┴────────────────────────────┐
    │     Home Network Devices        │
    │  • Smart Home Devices           │
    │  • IoT Devices                  │
    │  • Computers                    │
    │  • Phones/Tablets               │
    │  • All get static VPS IP        │
    └─────────────────────────────────┘
```

### Network Topology

**VPS Network Segments:**
- **Physical Network**: 10.0.0.0/24 (enp0s6)
- **NetBird Mesh**: 100.66.0.0/16 (wt0)
- **WireGuard VPN**: 10.10.10.0/24 (wg0)
- **Docker Bridge**: 172.17.0.0/16, 172.18.0.0/16

**IP Allocation Scheme:**
```
10.10.10.0/24 - WireGuard VPN Subnet
├─ 10.10.10.1    - VPS WireGuard Server
├─ 10.10.10.2    - Home Router
├─ 10.10.10.3    - iOS Device
├─ 10.10.10.4    - macOS Device
├─ 10.10.10.5    - Windows Device
└─ 10.10.10.6-254 - Reserved for future devices
```

## Traffic Flow

### Outbound Internet Traffic

```
Client Device
    │
    │ 1. Packet: src=10.10.10.3, dst=8.8.8.8
    │
    ↓ Encrypted through WireGuard tunnel
    │
WireGuard Server (wg0)
    │
    │ 2. Decrypt packet
    │
    ↓ Check FORWARD rules
    │
iptables FORWARD Chain
    │
    │ 3. Accept (wg0 rule at top)
    │
    ↓ Route to physical interface
    │
iptables NAT/POSTROUTING
    │
    │ 4. MASQUERADE: Change src to VPS public IP
    │    New packet: src=92.5.92.62, dst=8.8.8.8
    │
    ↓ Send to internet
    │
Internet
    │
    │ 5. Response: src=8.8.8.8, dst=92.5.92.62
    │
    ↓ NAT tracks connection
    │
iptables NAT/POSTROUTING (connection tracking)
    │
    │ 6. Change dst back to client VPN IP
    │    New packet: src=8.8.8.8, dst=10.10.10.3
    │
    ↓ Encrypt and send through tunnel
    │
WireGuard Server (wg0)
    │
    │ 7. Encrypt packet
    │
    ↓ Send to client
    │
Client Device
    │
    └─ 8. Decrypt and deliver to application
```

### Inbound Traffic (Not Allowed by Default)

WireGuard is configured for **outbound-only** traffic by default:
- Clients can initiate connections OUT to internet
- Internet cannot initiate connections IN to clients
- This provides NAT-level protection

To allow inbound traffic (advanced use case):
- Add port forwarding rules on VPS
- Configure destination NAT to specific client
- Open corresponding ports on client firewall

## Design Decisions

### 1. Why WireGuard?

**Compared to OpenVPN:**
- ✅ Much simpler configuration (few lines vs hundreds)
- ✅ Better performance (kernel-level implementation)
- ✅ Modern cryptography (ChaCha20, Curve25519)
- ✅ Smaller attack surface (4,000 vs 100,000+ lines of code)
- ✅ Better battery life on mobile devices
- ✅ Seamless roaming between networks

**Compared to IPsec:**
- ✅ Easier to configure and troubleshoot
- ✅ Better NAT traversal
- ✅ Cleaner codebase
- ✅ No complex certificate management

### 2. Why Full Tunnel (0.0.0.0/0)?

**Instead of split tunneling:**
- ✅ All traffic gets static IP (the goal)
- ✅ Simpler configuration
- ✅ No DNS leaks
- ✅ Consistent security posture

**Trade-offs:**
- ❌ All internet traffic goes through VPS (bandwidth)
- ❌ Potential latency increase
- ❌ VPS bandwidth costs

**Mitigation:**
- Use VPS in geographically close region
- Choose VPS with high bandwidth allowance
- Monitor bandwidth usage

### 3. Why Separate Subnet (10.10.10.0/24)?

**Instead of sharing NetBird subnet:**
- ✅ Clear separation of concerns
- ✅ Easy to manage and troubleshoot
- ✅ No routing conflicts
- ✅ Different use cases (mesh vs gateway)
- ✅ Can disable one without affecting other

### 4. Network Interface Selection

**Why enp0s6 for NAT?**
- This is the physical interface with internet access
- Default gateway routes through this interface
- Public IP is bound to this interface

**How to find your interface:**
```bash
ip route | grep default
# Output: default via 10.0.0.1 dev enp0s6 ...
#                                   ^^^^^^^
#                                   This is your interface
```

### 5. iptables Rule Order

**CRITICAL: Why INSERT (-I) instead of APPEND (-A)?**

```
Without -I (rules at bottom):
Chain FORWARD
1. Docker rules
2. NetBird rules
3. ...
4. REJECT all      ← Blocks everything first
5. ACCEPT wg0      ← Never reached!
6. ACCEPT wg0      ← Never reached!

With -I (rules at top):
Chain FORWARD
1. ACCEPT wg0      ← Processed first ✓
2. ACCEPT wg0      ← Processed first ✓
3. Docker rules
4. NetBird rules
5. ...
6. REJECT all      ← Only reached if not matched above
```

**Solution in config:**
```ini
PostUp = iptables -I FORWARD 1 -i wg0 -j ACCEPT
                  ^^         ^
                  INSERT     Position 1 (top)
```

### 6. Persistent Keepalive

**Why 25 seconds?**
- Keeps NAT mappings alive on home routers
- Most NAT timeouts are 30-60 seconds
- 25 seconds ensures connection stays alive
- Balance between reliability and battery/bandwidth

**Trade-offs:**
- ✅ Stable connection
- ✅ Fast reconnection after sleep
- ❌ Slightly higher battery usage
- ❌ Constant small data usage

## Security Model

### Threat Model

**Protected Against:**
- ✅ ISP tracking of browsing habits
- ✅ Geographic restrictions based on home IP
- ✅ IP-based attacks on home network
- ✅ DNS hijacking/snooping
- ✅ Man-in-the-middle on public WiFi
- ✅ Unauthorized access to cloud services

**Not Protected Against:**
- ❌ Traffic analysis by VPS provider
- ❌ Compromise of VPS itself
- ❌ Application-level tracking (cookies, fingerprinting)
- ❌ Malware on client devices
- ❌ Physical access to devices

### Cryptographic Details

**Key Exchange:**
- Curve25519 for Diffie-Hellman key exchange
- 256-bit keys

**Encryption:**
- ChaCha20 for symmetric encryption
- Poly1305 for authentication
- AEAD (Authenticated Encryption with Associated Data)

**Hashing:**
- BLAKE2s for hashing
- SipHash for hashtable keys

### Trust Boundaries

```
┌─────────────────────────────────────────────┐
│           Fully Trusted                     │
│  • VPS (you control it)                     │
│  • Your devices (you own them)              │
│  • Private keys (you generated them)        │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│         Partially Trusted                   │
│  • Cloud provider (VPS host)                │
│  • Internet infrastructure                  │
│  • DNS providers (1.1.1.1, 8.8.8.8)        │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│            Untrusted                        │
│  • Public WiFi networks                     │
│  • ISP networks                             │
│  • Destination websites                     │
│  • Other internet users                     │
└─────────────────────────────────────────────┘
```

## Scalability

### Current Capacity

**Single VPS can handle:**
- 50-100 concurrent clients comfortably
- Limited by VPS CPU and bandwidth
- Each client adds minimal CPU overhead

**Bandwidth considerations:**
- If 10 clients each use 10 Mbps average
- Total: 100 Mbps required
- Choose VPS with adequate bandwidth allowance

### Horizontal Scaling

**To scale to more clients:**

1. **Multiple VPS servers:**
   ```
   Router 1 → VPS 1 (IP1)
   Router 2 → VPS 2 (IP2)
   Mobile devices → VPS 1 or VPS 2 (load balance)
   ```

2. **DNS round-robin:**
   ```
   vpn.example.com → IP1, IP2, IP3
   Clients randomly connect to one
   ```

3. **Load balancer (advanced):**
   ```
   Load Balancer (sticky sessions)
   ├─ VPS 1
   ├─ VPS 2
   └─ VPS 3
   ```

### Monitoring Capacity

```bash
# Check current load
sudo wg show wg0 | grep peer | wc -l
# Shows number of configured peers

# Check active connections
sudo wg show wg0 | grep "latest handshake" | grep -v "never"
# Shows peers with recent handshakes

# Monitor bandwidth per peer
sudo wg show wg0 | grep -A 3 "peer:"
# Shows transfer statistics
```

## Integration with Existing Infrastructure

### Coexistence with NetBird

**Network Separation:**
- NetBird: 100.66.0.0/16 (mesh network)
- WireGuard: 10.10.10.0/24 (gateway VPN)
- No routing between the two
- Different use cases, different tools

**Shared VPS Resources:**
- Both services run simultaneously
- Different network interfaces (wt0 vs wg0)
- Different ports (NetBird uses various, WireGuard uses 51820)
- No conflicts or interference

### Coexistence with Docker

**Docker Networks:**
- docker0: 172.17.0.0/16
- Custom bridges: 172.18.0.0/16+
- No overlap with WireGuard subnet

**iptables Interaction:**
- Docker adds its own FORWARD rules
- WireGuard rules inserted at top (position 1)
- Both work independently

**Port Conflicts:**
- Docker containers can use any ports
- WireGuard uses only 51820/UDP
- No conflicts as long as containers don't use 51820/UDP

## Performance Optimization

### VPS Selection

**Recommended specs:**
- **CPU**: 1-2 vCPU (more if >50 clients)
- **RAM**: 1-2 GB minimum
- **Storage**: 10 GB sufficient
- **Bandwidth**: 1-5 TB/month depending on usage
- **Network**: 100-1000 Mbps

**Geographic location:**
- Choose VPS near your physical location
- Closer = lower latency
- Check latency: `ping VPS_IP`

### Kernel Parameters

**For high performance:**
```bash
# Add to /etc/sysctl.conf
net.core.netdev_max_backlog = 5000
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq

sudo sysctl -p
```

### MTU Optimization

**Find optimal MTU:**
```bash
# From client, test different sizes
ping -M do -s 1472 10.10.10.1  # MTU 1500
ping -M do -s 1452 10.10.10.1  # MTU 1480
ping -M do -s 1392 10.10.10.1  # MTU 1420
# Use largest size that doesn't fragment
```

**Set in client config:**
```ini
[Interface]
MTU = 1420  # Typically safe value
```

## Disaster Recovery

### Backup Strategy

**What to backup:**
- `/etc/wireguard/` - All keys and configs
- `/etc/iptables/rules.v4` - Firewall rules
- `/etc/sysctl.conf` - Kernel parameters
- Client config files

**Backup script:**
```bash
#!/bin/bash
BACKUP_DIR="/root/wireguard-backup-$(date +%F)"
mkdir -p "$BACKUP_DIR"
cp -r /etc/wireguard/ "$BACKUP_DIR/"
cp /etc/iptables/rules.v4 "$BACKUP_DIR/"
cp /etc/sysctl.conf "$BACKUP_DIR/"
tar -czf wireguard-backup-$(date +%F).tar.gz "$BACKUP_DIR"
```

### Recovery Procedure

**If VPS is lost:**
1. Deploy new VPS with same IP (if possible)
2. Install WireGuard
3. Restore `/etc/wireguard/` directory
4. Restore firewall rules
5. Enable and start service
6. No client changes needed if IP is same

**If IP changes:**
1. Update all client configs with new endpoint IP
2. Redistribute configs to all clients
3. Update firewall rules on cloud services

### High Availability

**For critical use:**
- Deploy to multiple VPS in different regions
- Use DNS failover (health checks)
- Keep backup configs for all VPS
- Clients can have multiple profiles

## Cost Analysis

### VPS Costs (Monthly)

**Budget tier ($5-10/month):**
- 1 vCPU, 1GB RAM, 1TB bandwidth
- Suitable for: 1-10 clients, light usage
- Providers: DigitalOcean, Linode, Vultr

**Standard tier ($10-20/month):**
- 2 vCPU, 2GB RAM, 2TB bandwidth
- Suitable for: 10-50 clients, moderate usage
- Providers: All major providers

**Performance tier ($20-50/month):**
- 4 vCPU, 4GB RAM, 5TB bandwidth
- Suitable for: 50+ clients, heavy usage
- Dedicated CPU options

### Bandwidth Usage

**Typical usage per client:**
- Light (email, browsing): 10-20 GB/month
- Moderate (streaming music): 50-100 GB/month
- Heavy (video streaming): 200+ GB/month

**Example calculation:**
- 5 clients × 50 GB/month = 250 GB/month
- Most $10/month VPS include 1TB bandwidth
- Well within limits for typical usage

### Cost Comparison

**vs Commercial VPN:**
- Commercial: $10/month per device
- Self-hosted: $10/month unlimited devices
- Break-even at 2 devices

**vs Static ISP IP:**
- Business ISP plan: $50-200/month
- Self-hosted VPN: $10/month
- Savings: $40-190/month

## Future Enhancements

### Planned Features

1. **IPv6 Support:**
   - Dual-stack configuration
   - IPv6 routing through VPN
   - Modern network compatibility

2. **Automated Deployment:**
   - Ansible playbooks
   - Terraform templates
   - One-command setup

3. **Monitoring Dashboard:**
   - Grafana visualizations
   - Prometheus metrics
   - Real-time alerts

4. **Multi-Server Setup:**
   - Geographic load balancing
   - Automatic failover
   - High availability

5. **Advanced Routing:**
   - Split tunneling options
   - Per-app VPN routing
   - Policy-based routing

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to help improve this project!

---

**This architecture has been battle-tested and is running in production, handling multiple clients with 100% uptime.**
