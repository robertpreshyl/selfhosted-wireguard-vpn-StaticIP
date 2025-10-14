<div align="center">

# 🔐 WireGuard Static IP VPN Server

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![WireGuard](https://img.shields.io/badge/WireGuard-1.0.20210914-blue.svg)](https://www.wireguard.com/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04_LTS-orange.svg)](https://ubuntu.com/)
[![Platform](https://img.shields.io/badge/Platform-VPS%20%7C%20Cloud-green.svg)]()
[![Security](https://img.shields.io/badge/Security-Analyst_Approved-red.svg)]()

**Self-hosted WireGuard VPN providing static IP addresses for secure cloud access**

[Features](#-features) • [Quick Start](#-quick-start) • [Documentation](#-documentation) • [Architecture](#-solution-architecture) • [Support](#-troubleshooting)

---

</div>

## 🎯 Overview

This project provides a **production-ready WireGuard VPN server** designed for security professionals and enthusiasts who need **static IP addresses** for secure cloud infrastructure access.

> 💡 **Perfect for:** Security analysts, DevOps engineers, homelab enthusiasts, and anyone needing reliable static IPs without expensive commercial VPN services.

### 🎪 Use Case

As a security professional, restricting cloud services (SSH servers, admin panels, databases) to known, trusted IP addresses is **critical** for reducing attack surface. However:
- 🏠 Home ISPs provide **dynamic IPs** that change frequently
- 🌐 Commercial VPN services **rotate IPs** constantly  
- 💰 Static IP VPN services cost **$50-200/month**

**This solution provides:**
- ✅ Static, stable IP address (`$10/month VPS`)
- ✅ Multiple device support (router, mobile, desktop)
- ✅ Self-hosted control (no third-party dependencies)
- ✅ Coexistence with other infrastructure (NetBird, Docker)
- ✅ Enterprise-grade security posture

---

## 📋 Table of Contents

- [🎯 Overview](#-overview)
- [🔒 Problem Statement](#-problem-statement)
- [🏗️ Solution Architecture](#️-solution-architecture)
- [✨ Features](#-features)
- [⚡ Quick Start](#-quick-start)
- [📚 Documentation](#-documentation)
- [🔧 Prerequisites](#-prerequisites)
- [📥 Installation Guide](#-installation-guide)
- [⚙️ Configuration](#️-configuration)
- [📱 Client Setup](#-client-setup)
- [🐛 Troubleshooting](#-troubleshooting)
- [🔐 Security Considerations](#-security-considerations)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)
- [⭐ Star History](#-star-history)

---

## ⚡ Quick Start

> **🚀 Get up and running in 15 minutes!**

```bash
# 1. Install WireGuard
sudo apt update && sudo apt install -y wireguard wireguard-tools qrencode

# 2. Generate server keys
wg genkey | sudo tee /etc/wireguard/server_private.key | wg pubkey | sudo tee /etc/wireguard/server_public.key

# 3. Enable IP forwarding
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# 4. Configure WireGuard (use template from examples/server-template.conf)
sudo nano /etc/wireguard/wg0.conf

# 5. Start VPN
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
```

📖 **Full installation guide:** [Installation Guide](#-installation-guide) | **Need help?** [Troubleshooting](#-troubleshooting)

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| **[QUICKSTART.md](QUICKSTART.md)** | 15-minute setup guide |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | System design and technical decisions |
| **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** | Common issues and solutions |
| **[CONTRIBUTING.md](CONTRIBUTING.md)** | How to contribute to this project |
| **[CHANGELOG.md](CHANGELOG.md)** | Version history and updates |

---

## 🔒 Problem Statement

### Challenges:
1. **Dynamic Home IPs**: ISPs change residential IPs frequently
2. **Commercial VPN IP Rotation**: Traditional VPN services constantly change exit IPs
3. **Security Posture**: Need to restrict cloud services to specific, trusted IPs
4. **Attack Surface Reduction**: Limit SSH, admin panels, and services to home network only
5. **Stability**: Require consistent, predictable IP for firewall rules

### Traditional Solutions (Inadequate):
- ❌ Commercial VPNs: IPs change frequently, expensive for static IPs
- ❌ Home ISP Static IP: Expensive business plans, still exposes home network
- ❌ Multiple per-device VPNs: Complex to manage, inconsistent IPs
- ❌ Cloud bastion hosts: Additional complexity, doesn't solve home network issue

---

## 🏗️ Solution Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Internet/Cloud                           │
│  (SSH servers, admin panels, cloud services restricted      │
│   to static IP: 92.5.92.62)                                 │
└────────────────────────┬────────────────────────────────────┘
                         │
         ┌───────────────┴────────────────┐
         │   WireGuard VPN Server (VPS)   │
         │   Public IP: 92.5.92.62        │
         │   Interface: wg0               │
         │   VPN Subnet: 10.10.10.0/24    │
         │                                │
         │   Also runs:                   │
         │   - NetBird mesh (wt0)         │
         │   - Docker services            │
         └───────────────┬────────────────┘
                         │
         ┌───────────────┴────────────────┐
         │                                │
    ┌────┴─────┐  ┌──────┴──────┐  ┌─────┴──────┐  ┌────┴─────┐
    │  Router  │  │   iOS       │  │   macOS    │  │ Windows  │
    │10.10.10.2│  │ 10.10.10.3  │  │ 10.10.10.4 │  │10.10.10.5│
    └────┬─────┘  └─────────────┘  └────────────┘  └──────────┘
         │
    ┌────┴──────────────────────┐
    │   Home Network Devices    │
    │   (All appear from VPS IP)│
    └───────────────────────────┘
```

### Traffic Flow:
1. Home Router connects to WireGuard VPN (gets 10.10.10.2)
2. All home devices route through router → VPN → Internet
3. All traffic appears from VPS IP: 92.5.92.62
4. Individual devices (mobile, laptop) can also connect directly
5. Cloud services see only static VPS IP in firewall logs

---

## ✨ Features

### Core Features:
- ✅ **Static IP Address**: All traffic exits from VPS public IP
- ✅ **Multi-Device Support**: Router + iOS + macOS + Windows configurations
- ✅ **Full Tunnel**: All internet traffic routed through VPN
- ✅ **Auto-Reconnect**: Persistent keepalive maintains connections
- ✅ **QR Code Setup**: Easy mobile device configuration
- ✅ **Coexistence**: Works alongside NetBird mesh network
- ✅ **Zero Downtime**: No interruption to existing services

### Security Features:
- 🔐 **Modern Encryption**: ChaCha20-Poly1305 cipher suite
- 🔐 **Unique Keys**: Each device has individual private/public key pair
- 🔐 **Separate Subnets**: WireGuard (10.10.10.0/24) isolated from other networks
- 🔐 **Minimal Attack Surface**: Only UDP port 51820 exposed
- 🔐 **IP Forwarding**: Secure NAT/masquerading configuration

### Operational Features:
- 📊 **Easy Monitoring**: Real-time connection status via `wg show`
- 📊 **Transfer Statistics**: Per-device bandwidth tracking
- 📊 **Handshake Tracking**: Connection health visibility
- 📊 **Auto-Start**: Systemd service enables on boot
- 📊 **Persistent Rules**: iptables rules saved across reboots

---

## 📦 Prerequisites

### Server Requirements:
- **VPS/Cloud Server**: Ubuntu 24.04 LTS (arm64 or x86_64)
- **Public IP**: Static public IPv4 address
- **Resources**: Minimum 1 vCPU, 1GB RAM, 10GB storage
- **Network**: UDP port 51820 accessible from internet
- **Access**: SSH root or sudo access

### Client Requirements:
- **Router**: ASUS router with WireGuard client support (or similar)
- **iOS**: WireGuard app from App Store (iOS 12+)
- **macOS**: WireGuard app from App Store (macOS 10.14+)
- **Windows**: WireGuard installer from wireguard.com (Windows 10+)

### Technical Requirements:
- Basic Linux command line knowledge
- Understanding of networking concepts (NAT, routing, subnets)
- Access to cloud provider console (for firewall rules)
- SSH client for VPS access

---

## 🚀 Installation Guide

### Phase 1: Pre-Installation Assessment

1. **SSH into your VPS:**
   ```bash
   ssh ubuntu@YOUR_VPS_IP
   ```

2. **Check system information:**
   ```bash
   # Verify OS version
   lsb_release -a
   
   # Check network interfaces
   ip addr show
   
   # Get public IP
   curl -s ifconfig.me
   
   # Check available disk space
   df -h
   ```

3. **Create backup directory:**
   ```bash
   BACKUP_DIR="/root/backup-wireguard-$(date +%F)"
   sudo mkdir -p "$BACKUP_DIR"
   
   # Backup existing iptables
   sudo iptables-save > "$BACKUP_DIR/iptables-before.txt"
   ```

### Phase 2: Install WireGuard

1. **Update package list:**
   ```bash
   sudo apt update
   ```

2. **Install WireGuard and tools:**
   ```bash
   sudo apt install -y wireguard wireguard-tools qrencode
   ```

3. **Verify installation:**
   ```bash
   wg --version
   # Should output: wireguard-tools v1.0.20210914 or newer
   ```

### Phase 3: Enable IP Forwarding

1. **Check current setting:**
   ```bash
   sysctl net.ipv4.ip_forward
   ```

2. **Enable permanently:**
   ```bash
   echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
   sudo sysctl -p
   ```

3. **Verify:**
   ```bash
   sysctl net.ipv4.ip_forward
   # Should output: net.ipv4.ip_forward = 1
   ```

### Phase 4: Generate Keys

1. **Create server keys:**
   ```bash
   sudo sh -c 'cd /etc/wireguard && umask 077 && \
   wg genkey | tee server_private.key | wg pubkey > server_public.key'
   ```

2. **Create router keys:**
   ```bash
   sudo sh -c 'cd /etc/wireguard && umask 077 && \
   wg genkey | tee router_private.key | wg pubkey > router_public.key'
   ```

3. **Create iOS keys:**
   ```bash
   sudo sh -c 'cd /etc/wireguard && umask 077 && \
   wg genkey | tee ios_private.key | wg pubkey > ios_public.key'
   ```

4. **Create macOS keys:**
   ```bash
   sudo sh -c 'cd /etc/wireguard && umask 077 && \
   wg genkey | tee macos_private.key | wg pubkey > macos_public.key'
   ```

5. **Create Windows keys:**
   ```bash
   sudo sh -c 'cd /etc/wireguard && umask 077 && \
   wg genkey | tee windows_private.key | wg pubkey > windows_public.key'
   ```

6. **Verify keys created:**
   ```bash
   sudo ls -lh /etc/wireguard/*.key
   ```

### Phase 5: Configure WireGuard Server

1. **Get default network interface:**
   ```bash
   DEFAULT_IF=$(ip route | grep default | awk '{print $5}')
   echo "Default interface: $DEFAULT_IF"
   ```

2. **Read generated keys:**
   ```bash
   SERVER_PRIVATE=$(sudo cat /etc/wireguard/server_private.key)
   ROUTER_PUBLIC=$(sudo cat /etc/wireguard/router_public.key)
   IOS_PUBLIC=$(sudo cat /etc/wireguard/ios_public.key)
   MACOS_PUBLIC=$(sudo cat /etc/wireguard/macos_public.key)
   WINDOWS_PUBLIC=$(sudo cat /etc/wireguard/windows_public.key)
   ```

3. **Create server configuration:**
   ```bash
   sudo tee /etc/wireguard/wg0.conf > /dev/null <<EOF
   [Interface]
   # WireGuard VPN Server - Static IP for Home Network
   Address = 10.10.10.1/24
   ListenPort = 51820
   PrivateKey = $SERVER_PRIVATE

   # PostUp: Enable NAT and routing (INSERT at top of chains)
   PostUp = iptables -I FORWARD 1 -i wg0 -j ACCEPT
   PostUp = iptables -I FORWARD 1 -o wg0 -j ACCEPT
   PostUp = iptables -t nat -A POSTROUTING -o $DEFAULT_IF -j MASQUERADE

   # PostDown: Clean up rules
   PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
   PostDown = iptables -D FORWARD -o wg0 -j ACCEPT
   PostDown = iptables -D nat -POSTROUTING -o $DEFAULT_IF -j MASQUERADE

   [Peer]
   # Home Router - Routes entire home network through VPN
   PublicKey = $ROUTER_PUBLIC
   AllowedIPs = 10.10.10.2/32
   PersistentKeepalive = 25

   [Peer]
   # iOS Device - Mobile phone/tablet
   PublicKey = $IOS_PUBLIC
   AllowedIPs = 10.10.10.3/32
   PersistentKeepalive = 25

   [Peer]
   # macOS Device - Laptop/desktop
   PublicKey = $MACOS_PUBLIC
   AllowedIPs = 10.10.10.4/32
   PersistentKeepalive = 25

   [Peer]
   # Windows Device - PC
   PublicKey = $WINDOWS_PUBLIC
   AllowedIPs = 10.10.10.5/32
   PersistentKeepalive = 25
   EOF
   ```

4. **Secure the configuration:**
   ```bash
   sudo chmod 600 /etc/wireguard/wg0.conf
   ```

### Phase 6: Create Client Configurations

**Note:** Replace `YOUR_VPS_PUBLIC_IP` with your actual VPS public IP.

1. **Router configuration:**
   ```bash
   ROUTER_PRIVATE=$(sudo cat /etc/wireguard/router_private.key)
   SERVER_PUBLIC=$(sudo cat /etc/wireguard/server_public.key)
   VPS_IP=$(curl -s ifconfig.me)

   cat > ~/router-wireguard.conf <<EOF
   [Interface]
   # Home Router WireGuard Client
   Address = 10.10.10.2/24
   PrivateKey = $ROUTER_PRIVATE
   DNS = 1.1.1.1, 8.8.8.8

   [Peer]
   # WireGuard VPN Server
   PublicKey = $SERVER_PUBLIC
   Endpoint = $VPS_IP:51820
   AllowedIPs = 0.0.0.0/0, ::/0
   PersistentKeepalive = 25
   EOF
   ```

2. **iOS configuration:**
   ```bash
   IOS_PRIVATE=$(sudo cat /etc/wireguard/ios_private.key)

   cat > ~/ios-device.conf <<EOF
   [Interface]
   # iOS Device WireGuard Client
   Address = 10.10.10.3/24
   PrivateKey = $IOS_PRIVATE
   DNS = 1.1.1.1, 8.8.8.8

   [Peer]
   # WireGuard VPN Server
   PublicKey = $SERVER_PUBLIC
   Endpoint = $VPS_IP:51820
   AllowedIPs = 0.0.0.0/0, ::/0
   PersistentKeepalive = 25
   EOF

   # Generate QR code for easy mobile import
   qrencode -t ansiutf8 < ~/ios-device.conf > ~/ios-device-qr.txt
   ```

3. **macOS configuration:**
   ```bash
   MACOS_PRIVATE=$(sudo cat /etc/wireguard/macos_private.key)

   cat > ~/macos-device.conf <<EOF
   [Interface]
   # macOS Device WireGuard Client
   Address = 10.10.10.4/24
   PrivateKey = $MACOS_PRIVATE
   DNS = 1.1.1.1, 8.8.8.8

   [Peer]
   # WireGuard VPN Server
   PublicKey = $SERVER_PUBLIC
   Endpoint = $VPS_IP:51820
   AllowedIPs = 0.0.0.0/0, ::/0
   PersistentKeepalive = 25
   EOF
   ```

4. **Windows configuration:**
   ```bash
   WINDOWS_PRIVATE=$(sudo cat /etc/wireguard/windows_private.key)

   cat > ~/windows-device.conf <<EOF
   [Interface]
   # Windows Device WireGuard Client
   Address = 10.10.10.5/24
   PrivateKey = $WINDOWS_PRIVATE
   DNS = 1.1.1.1, 8.8.8.8

   [Peer]
   # WireGuard VPN Server
   PublicKey = $SERVER_PUBLIC
   Endpoint = $VPS_IP:51820
   AllowedIPs = 0.0.0.0/0, ::/0
   PersistentKeepalive = 25
   EOF
   ```

### Phase 7: Configure Firewall

1. **Add iptables rule for WireGuard:**
   ```bash
   sudo iptables -I INPUT -p udp --dport 51820 -m conntrack --ctstate NEW -j ACCEPT -m comment --comment "WireGuard VPN"
   ```

2. **Install iptables-persistent:**
   ```bash
   sudo apt install -y iptables-persistent
   ```

3. **Save iptables rules:**
   ```bash
   sudo mkdir -p /etc/iptables
   sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
   ```

4. **Configure cloud provider firewall (OCI/AWS/GCP/Azure):**
   
   **CRITICAL:** You must also add a security rule in your cloud provider's console:
   
   - **Protocol:** UDP
   - **Port:** 51820
   - **Source:** 0.0.0.0/0 (or restrict to your known IPs)
   - **Direction:** Ingress/Inbound
   
   **Example for OCI:**
   ```
   Navigate to: VCN → Security Lists → Add Ingress Rule
   
   Source Type: CIDR
   Source CIDR: 0.0.0.0/0
   IP Protocol: UDP
   Destination Port: 51820
   Description: WireGuard VPN
   ```

### Phase 8: Start WireGuard Service

1. **Enable WireGuard service:**
   ```bash
   sudo systemctl enable wg-quick@wg0
   ```

2. **Start WireGuard:**
   ```bash
   sudo systemctl start wg-quick@wg0
   ```

3. **Check status:**
   ```bash
   sudo systemctl status wg-quick@wg0
   ```

4. **Verify interface is up:**
   ```bash
   ip addr show wg0
   sudo wg show wg0
   ```

### Phase 9: Verification

1. **Check WireGuard status:**
   ```bash
   sudo wg show
   ```

2. **Verify interface:**
   ```bash
   ip addr show wg0
   # Should show: 10.10.10.1/24
   ```

3. **Check listening port:**
   ```bash
   sudo ss -ulnp | grep 51820
   # Should show WireGuard listening on UDP 51820
   ```

4. **Test IP forwarding:**
   ```bash
   sysctl net.ipv4.ip_forward
   # Should output: 1
   ```

5. **Verify NAT rules:**
   ```bash
   sudo iptables -t nat -L POSTROUTING -n -v
   # Should show MASQUERADE rule for your network interface
   ```

6. **Check FORWARD rules:**
   ```bash
   sudo iptables -L FORWARD -n -v | grep wg0
   # Should show ACCEPT rules for wg0 interface
   ```

---

## 📱 Client Setup

### Router Setup (ASUS)

1. **Access router admin panel** (typically http://router.asus.com or 192.168.1.1)

2. **Navigate to VPN section:**
   - Go to **VPN** → **VPN Client**
   - Select **WireGuard** tab

3. **Import configuration:**
   - Click **Add Profile** or **Import**
   - Upload `router-wireguard.conf`
   - Or manually enter configuration details

4. **Enable connection:**
   - Toggle **Enable** switch
   - Click **Connect**
   - Verify status shows "Connected"

5. **Configure routing (optional):**
   - To route ALL home devices through VPN:
   - Enable "Redirect Internet traffic" or similar option
   - Save and apply

6. **Verify connection:**
   - Check router's public IP: http://ifconfig.me
   - Should show VPS IP: 92.5.92.62 (your VPS IP)

### iOS Setup

**Method 1: QR Code (Easiest)**

1. **Download QR code from server:**
   ```bash
   # On your computer
   scp ubuntu@YOUR_VPS_IP:~/ios-device-qr.txt .
   cat ios-device-qr.txt
   ```

2. **Install WireGuard app:**
   - Open App Store
   - Search "WireGuard"
   - Install official WireGuard app

3. **Import configuration:**
   - Open WireGuard app
   - Tap **+** button
   - Select **Create from QR code**
   - Scan the QR code from terminal

4. **Connect:**
   - Toggle the connection switch ON
   - Allow VPN configuration when prompted

**Method 2: Configuration File**

1. **Download config file:**
   ```bash
   scp ubuntu@YOUR_VPS_IP:~/ios-device.conf .
   ```

2. **Transfer to iOS:**
   - Use AirDrop to send `ios-device.conf` to iPhone/iPad
   - Or email to yourself and open on iOS device

3. **Import in WireGuard:**
   - Tap the file
   - Select "Open with WireGuard"
   - Tap "Add Tunnel"

4. **Connect:**
   - Toggle connection ON

### macOS Setup

1. **Install WireGuard:**
   - Open App Store
   - Search "WireGuard"
   - Install official WireGuard app

2. **Download configuration:**
   ```bash
   scp ubuntu@YOUR_VPS_IP:~/macos-device.conf ~/Downloads/
   ```

3. **Import configuration:**
   - Open WireGuard app
   - Click **Import tunnel(s) from file**
   - Select `macos-device.conf`

4. **Connect:**
   - Select the tunnel
   - Click **Activate**

5. **Verify connection:**
   ```bash
   curl ifconfig.me
   # Should output: 92.5.92.62 (your VPS IP)
   
   ping 8.8.8.8
   # Should receive responses
   ```

### Windows Setup

1. **Download WireGuard:**
   - Visit: https://www.wireguard.com/install/
   - Download Windows installer
   - Run installer as Administrator

2. **Download configuration:**
   ```bash
   scp ubuntu@YOUR_VPS_IP:~/windows-device.conf C:\Users\YourName\Downloads\
   ```

3. **Import configuration:**
   - Open WireGuard application
   - Click **Import tunnel(s) from file**
   - Select `windows-device.conf`

4. **Connect:**
   - Click **Activate**

5. **Verify connection:**
   ```cmd
   curl ifconfig.me
   REM Should output: 92.5.92.62 (your VPS IP)
   
   ping 8.8.8.8
   REM Should receive responses
   ```

---

## 🔍 Troubleshooting

### Issue: Devices Connect but No Internet Access

**Symptoms:**
- WireGuard shows "Connected"
- Handshakes visible on server
- Cannot ping 8.8.8.8
- Websites don't load

**Solution:**

1. **Check if cloud firewall rule is added:**
   - Verify UDP port 51820 is open in your cloud provider's security group/list
   - OCI, AWS, GCP, Azure all require this

2. **Verify FORWARD chain rule order:**
   ```bash
   sudo iptables -L FORWARD -n -v --line-numbers
   ```
   
   WireGuard ACCEPT rules must come BEFORE any REJECT/DROP rules:
   ```bash
   # If needed, move rules to top:
   sudo iptables -D FORWARD -i wg0 -j ACCEPT
   sudo iptables -D FORWARD -o wg0 -j ACCEPT
   sudo iptables -I FORWARD 1 -i wg0 -j ACCEPT
   sudo iptables -I FORWARD 1 -o wg0 -j ACCEPT
   
   # Save rules
   sudo iptables-save | sudo tee /etc/iptables/rules.v4
   ```

3. **Verify NAT is working:**
   ```bash
   sudo iptables -t nat -L POSTROUTING -n -v
   # Should show MASQUERADE rule with packet counts increasing
   ```

4. **Check IP forwarding:**
   ```bash
   sysctl net.ipv4.ip_forward
   # Must be 1
   ```

### Issue: Cannot Connect to VPN

**Symptoms:**
- Connection times out
- No handshake on server
- Client shows "Connecting..." forever

**Solution:**

1. **Verify WireGuard is running:**
   ```bash
   sudo systemctl status wg-quick@wg0
   sudo ss -ulnp | grep 51820
   ```

2. **Check cloud provider firewall:**
   - Ensure UDP 51820 ingress rule exists
   - Verify rule is in correct security list/group
   - Check if there's a default DENY rule blocking it

3. **Verify correct endpoint in client config:**
   - Check `Endpoint =` line shows correct VPS public IP
   - Ensure port 51820 is specified

4. **Test connectivity to server:**
   ```bash
   # From client machine
   nc -zvu YOUR_VPS_IP 51820
   ```

### Issue: DNS Not Resolving

**Symptoms:**
- Can ping 8.8.8.8 (IP works)
- Cannot access websites by name
- `curl ifconfig.me` fails with "Could not resolve host"

**Solution:**

1. **Check DNS in client config:**
   ```ini
   [Interface]
   DNS = 1.1.1.1, 8.8.8.8
   ```

2. **Manually set DNS (temporary test):**
   ```bash
   # macOS/Linux
   echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
   
   # Windows (PowerShell as Admin)
   Set-DnsClientServerAddress -InterfaceAlias "WireGuard" -ServerAddresses ("1.1.1.1","8.8.8.8")
   ```

3. **Test DNS resolution:**
   ```bash
   nslookup google.com 1.1.1.1
   ```

### Issue: Slow Connection Speed

**Symptoms:**
- VPN connects successfully
- High latency
- Slow download/upload speeds

**Solution:**

1. **Check server load:**
   ```bash
   top
   htop
   ```

2. **Verify MTU settings:**
   ```bash
   # Add to [Interface] in client config:
   MTU = 1420
   ```

3. **Check for packet loss:**
   ```bash
   ping -c 100 10.10.10.1
   ```

4. **Monitor bandwidth:**
   ```bash
   sudo iftop -i wg0
   ```

### Issue: Connection Drops Frequently

**Symptoms:**
- Initial connection works
- Drops after period of inactivity
- Must manually reconnect

**Solution:**

1. **Verify PersistentKeepalive is set:**
   ```ini
   [Peer]
   PersistentKeepalive = 25
   ```

2. **Check for NAT timeout issues:**
   - Some routers/firewalls close UDP connections after inactivity
   - Reduce keepalive interval to 15 seconds if needed

3. **Monitor for handshake failures:**
   ```bash
   sudo wg show wg0
   # Check "latest handshake" timestamp
   # Should update every 25 seconds when traffic flows
   ```

### Diagnostic Commands

**Server-side diagnostics:**
```bash
# View all peers and connection status
sudo wg show wg0

# Monitor in real-time
watch -n 1 'sudo wg show wg0'

# Check logs
sudo journalctl -u wg-quick@wg0 -f

# Verify routing table
ip route show

# Check iptables rules
sudo iptables -L -n -v
sudo iptables -t nat -L -n -v
```

**Client-side diagnostics:**
```bash
# Check public IP (should show VPS IP)
curl ifconfig.me

# Test connectivity
ping 8.8.8.8
ping 10.10.10.1

# Check DNS
nslookup google.com

# Trace route
traceroute 8.8.8.8

# Check WireGuard interface (Linux/macOS)
ip addr show  # or ifconfig
```

---

## 🔐 Security Considerations

### Key Management

1. **Private Key Protection:**
   - Private keys are stored with 600 permissions (owner read/write only)
   - Never share private keys
   - Keep backups encrypted
   - Each device has unique key pair

2. **Key Rotation:**
   - Rotate keys annually or if compromised
   - Generate new keys: `wg genkey | tee privatekey | wg pubkey > publickey`
   - Update server and client configs
   - Restart services

### Network Security

1. **Firewall Configuration:**
   - Only UDP port 51820 exposed externally
   - All other services remain protected
   - Use cloud provider security groups for additional layer

2. **IP Whitelisting:**
   - Optionally restrict WireGuard port to known IP ranges
   - Balance between security and usability
   - Consider mobile device roaming

3. **Monitoring:**
   ```bash
   # Monitor failed connection attempts
   sudo journalctl -u wg-quick@wg0 | grep -i error
   
   # Check for unusual traffic patterns
   sudo iftop -i wg0
   
   # Monitor connected peers
   sudo wg show wg0 | grep endpoint
   ```

### Access Control

1. **Limit peer access:**
   - Only add trusted devices to server config
   - Remove unused peers immediately
   - Document each peer's purpose

2. **Separate subnets:**
   - WireGuard: 10.10.10.0/24
   - Home LAN: 192.168.x.0/24
   - NetBird mesh: 100.66.0.0/16
   - Prevents cross-network interference

### Best Practices

1. **Regular updates:**
   ```bash
   sudo apt update
   sudo apt upgrade wireguard wireguard-tools
   ```

2. **Backup configurations:**
   ```bash
   # Regular backups
   sudo tar -czf wireguard-backup-$(date +%F).tar.gz /etc/wireguard/
   ```

3. **Audit logs:**
   ```bash
   # Review weekly
   sudo journalctl -u wg-quick@wg0 --since "7 days ago"
   ```

4. **Test disaster recovery:**
   - Keep offline copy of configs
   - Document restoration procedure
   - Test failover scenarios

---

## 📊 Monitoring

### Real-time Monitoring

```bash
# Watch connection status
watch -n 1 'sudo wg show wg0'

# Monitor bandwidth
sudo iftop -i wg0

# View system resources
htop

# Check network traffic
sudo tcpdump -i wg0 -n
```

### Connection Health

```bash
# Check all peers
sudo wg show wg0 | grep -A 5 "peer:"

# Verify handshakes
sudo wg show wg0 | grep "latest handshake"

# Monitor data transfer
sudo wg show wg0 | grep "transfer"
```

### Log Analysis

```bash
# View recent logs
sudo journalctl -u wg-quick@wg0 -n 100

# Follow logs in real-time
sudo journalctl -u wg-quick@wg0 -f

# Search for errors
sudo journalctl -u wg-quick@wg0 | grep -i error

# Export logs
sudo journalctl -u wg-quick@wg0 --since "7 days ago" > wireguard-logs.txt
```

---

## 🔄 Maintenance

### Regular Tasks

**Weekly:**
- Check connection status of all peers
- Review logs for errors
- Verify backup integrity

**Monthly:**
- Update system packages
- Review and update documentation
- Test disaster recovery procedure

**Quarterly:**
- Audit peer list (remove unused)
- Review security configurations
- Update client software

### Updates

```bash
# Update WireGuard
sudo apt update
sudo apt upgrade wireguard wireguard-tools

# After update, restart service
sudo systemctl restart wg-quick@wg0

# Verify still working
sudo wg show wg0
```

### Backup and Restore

**Backup:**
```bash
# Create comprehensive backup
sudo tar -czf wireguard-backup-$(date +%F).tar.gz \
  /etc/wireguard/ \
  /etc/iptables/rules.v4 \
  /etc/sysctl.conf

# Copy to safe location
scp wireguard-backup-$(date +%F).tar.gz user@backup-server:~/backups/
```

**Restore:**
```bash
# Extract backup
sudo tar -xzf wireguard-backup-YYYY-MM-DD.tar.gz -C /

# Reload configurations
sudo systemctl restart wg-quick@wg0
sudo iptables-restore < /etc/iptables/rules.v4
sudo sysctl -p
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### How to Contribute

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Areas for Contribution

- Additional client platform guides (Linux, Android, etc.)
- Automation scripts
- Monitoring dashboards
- Security enhancements
- Performance optimizations
- Documentation improvements

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [WireGuard](https://www.wireguard.com/) - Fast, modern VPN protocol
- [NetBird](https://netbird.io/) - Mesh network platform (coexisting with this setup)
- Ubuntu community for excellent documentation
- Security community for best practices

---

## ⭐ Star History

If this project helped you secure your infrastructure, please consider giving it a star! ⭐

[![Star History Chart](https://api.star-history.com/svg?repos=robertpreshyl/selfhosted-wireguard-vpn-StaticIP&type=Date)](https://star-history.com/#robertpreshyl/selfhosted-wireguard-vpn-StaticIP&Date)

---

## 📊 Project Stats

![GitHub last commit](https://img.shields.io/github/last-commit/robertpreshyl/selfhosted-wireguard-vpn-StaticIP)
![GitHub issues](https://img.shields.io/github/issues/robertpreshyl/selfhosted-wireguard-vpn-StaticIP)
![GitHub stars](https://img.shields.io/github/stars/robertpreshyl/selfhosted-wireguard-vpn-StaticIP)
![GitHub forks](https://img.shields.io/github/forks/robertpreshyl/selfhosted-wireguard-vpn-StaticIP)

---

## 💬 Support & Community

- **Issues**: [GitHub Issues](https://github.com/robertpreshyl/selfhosted-wireguard-vpn-StaticIP/issues)
- **Discussions**: [GitHub Discussions](https://github.com/robertpreshyl/selfhosted-wireguard-vpn-StaticIP/discussions)
- **Security**: Report vulnerabilities via [Security Policy](SECURITY.md)

---

<div align="center">

**Made with ❤️ by Security Professionals, for Security Professionals**

*Secure your infrastructure. Control your network. Own your IP.*

[⬆ Back to Top](#-wireguard-static-ip-vpn-server)

</div>

## 📞 Support

- **Issues**: Please use GitHub Issues for bug reports and feature requests
- **Discussions**: Use GitHub Discussions for questions and community support
- **Security**: Report security vulnerabilities privately via email

---

## 🗺️ Roadmap

- [ ] Automated deployment scripts
- [ ] Docker container version
- [ ] Ansible playbook
- [ ] Monitoring dashboard (Grafana)
- [ ] IPv6 support
- [ ] Multi-server failover
- [ ] Load balancing across multiple VPS servers
- [ ] Android client guide
- [ ] Linux desktop client guide

---

## 📈 Project Status

**Current Version**: 1.0.0  
**Status**: Production Ready  
**Last Updated**: October 14, 2025

**Tested On:**
- Ubuntu 24.04 LTS (arm64)
- WireGuard Tools v1.0.20210914
- iOS 17+
- macOS 14+ (Sonoma)
- Windows 11

---

**Built with ❤️ for security professionals who need reliable, static IPs for their home networks**
