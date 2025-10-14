# Troubleshooting Guide

Comprehensive troubleshooting for WireGuard Static IP VPN setup.

## Table of Contents

- [Connection Issues](#connection-issues)
- [Internet Access Problems](#internet-access-problems)
- [Performance Issues](#performance-issues)
- [DNS Problems](#dns-problems)
- [Platform-Specific Issues](#platform-specific-issues)
- [Advanced Diagnostics](#advanced-diagnostics)

---

## Connection Issues

### Problem: Cannot Connect to VPN Server

**Symptoms:**
- Client shows "Connecting..." indefinitely
- Connection timeout error
- No handshake visible on server

**Diagnostic Steps:**

1. **Verify WireGuard service is running:**
   ```bash
   ssh ubuntu@YOUR_VPS_IP
   sudo systemctl status wg-quick@wg0
   ```
   
   Expected: `active (exited)` or `active (running)`

2. **Check if port is listening:**
   ```bash
   sudo ss -ulnp | grep 51820
   ```
   
   Expected output:
   ```
   UNCONN 0  0  0.0.0.0:51820  0.0.0.0:*
   UNCONN 0  0     [::]:51820     [::]:*
   ```

3. **Verify local firewall allows WireGuard:**
   ```bash
   sudo iptables -L INPUT -n -v | grep 51820
   ```
   
   Expected: Line showing ACCEPT for UDP port 51820

4. **Check cloud provider firewall:**
   - Log into cloud console (OCI/AWS/GCP/Azure)
   - Navigate to Security Groups/Lists
   - Verify ingress rule exists:
     - Protocol: UDP
     - Port: 51820
     - Source: 0.0.0.0/0 (or your IP range)

**Solutions:**

**If service not running:**
```bash
sudo systemctl start wg-quick@wg0
sudo systemctl enable wg-quick@wg0
```

**If port not listening:**
```bash
# Check config file
sudo cat /etc/wireguard/wg0.conf | grep ListenPort
# Should show: ListenPort = 51820

# Restart service
sudo systemctl restart wg-quick@wg0
```

**If local firewall blocking:**
```bash
sudo iptables -I INPUT -p udp --dport 51820 -m conntrack --ctstate NEW -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

**If cloud firewall missing:**
Add ingress rule in cloud console as described in README.

**Test connectivity from client:**
```bash
# Install nc (netcat) if needed
nc -zvu YOUR_VPS_IP 51820
```

---

## Internet Access Problems

### Problem: Connected but No Internet Access

**Symptoms:**
- WireGuard shows "Connected" status
- Server shows active handshake
- Cannot ping 8.8.8.8 or access websites
- `curl ifconfig.me` fails or times out

**This is the most common issue!**

**Diagnostic Steps:**

1. **Check if handshake is working:**
   ```bash
   # On server
   sudo wg show wg0
   ```
   
   Look for:
   - `latest handshake:` should show recent time (< 2 minutes)
   - `transfer:` should show data being sent/received

2. **Verify IP forwarding is enabled:**
   ```bash
   sysctl net.ipv4.ip_forward
   ```
   
   Expected: `net.ipv4.ip_forward = 1`

3. **Check FORWARD chain rules (CRITICAL):**
   ```bash
   sudo iptables -L FORWARD -n -v --line-numbers
   ```
   
   **KEY POINT:** WireGuard ACCEPT rules MUST appear BEFORE any REJECT/DROP rules.
   
   Example of CORRECT order:
   ```
   Chain FORWARD (policy ACCEPT)
   num   pkts bytes target     prot opt in     out     source    destination
   1        0     0 ACCEPT     all  --  wg0    *       0.0.0.0/0 0.0.0.0/0
   2        0     0 ACCEPT     all  --  *      wg0     0.0.0.0/0 0.0.0.0/0
   5        0     0 REJECT     all  --  *      *       0.0.0.0/0 0.0.0.0/0
   ```
   
   Example of WRONG order (rules after REJECT don't work):
   ```
   Chain FORWARD (policy ACCEPT)
   num   pkts bytes target     prot opt in     out     source    destination
   5        0     0 REJECT     all  --  *      *       0.0.0.0/0 0.0.0.0/0
   6        0     0 ACCEPT     all  --  wg0    *       0.0.0.0/0 0.0.0.0/0  ← TOO LATE!
   7        0     0 ACCEPT     all  --  *      wg0     0.0.0.0/0 0.0.0.0/0  ← TOO LATE!
   ```

4. **Check NAT/Masquerading:**
   ```bash
   sudo iptables -t nat -L POSTROUTING -n -v
   ```
   
   Expected: MASQUERADE rule for your network interface with increasing packet counts

**Solutions:**

**Fix IP forwarding:**
```bash
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

**Fix FORWARD chain rule order:**
```bash
# Remove existing rules
sudo iptables -D FORWARD -i wg0 -j ACCEPT
sudo iptables -D FORWARD -o wg0 -j ACCEPT

# Insert at TOP of chain (position 1)
sudo iptables -I FORWARD 1 -i wg0 -j ACCEPT
sudo iptables -I FORWARD 1 -o wg0 -j ACCEPT

# Save permanently
sudo iptables-save | sudo tee /etc/iptables/rules.v4

# Verify
sudo iptables -L FORWARD -n -v --line-numbers
```

**Fix NAT/Masquerading:**
```bash
# Get default interface
DEFAULT_IF=$(ip route | grep default | awk '{print $5}')
echo "Default interface: $DEFAULT_IF"

# Add masquerading rule
sudo iptables -t nat -A POSTROUTING -o $DEFAULT_IF -j MASQUERADE

# Save
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

**Update WireGuard config to use -I (insert) instead of -A (append):**
```bash
sudo nano /etc/wireguard/wg0.conf
```

Change:
```ini
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
PostUp = iptables -A FORWARD -o wg0 -j ACCEPT
```

To:
```ini
PostUp = iptables -I FORWARD 1 -i wg0 -j ACCEPT
PostUp = iptables -I FORWARD 1 -o wg0 -j ACCEPT
```

Then restart:
```bash
sudo systemctl restart wg-quick@wg0
```

**Test from client:**
```bash
# Should work now
ping 8.8.8.8

# Should show VPS IP
curl ifconfig.me

# Should load
curl https://www.google.com
```

---

## Performance Issues

### Problem: Slow Connection Speed

**Symptoms:**
- High latency (> 200ms)
- Slow downloads/uploads
- Buffering when streaming

**Diagnostic Steps:**

1. **Test basic connectivity:**
   ```bash
   # Ping VPN gateway
   ping -c 10 10.10.10.1
   
   # Ping external server
   ping -c 10 8.8.8.8
   ```

2. **Check server load:**
   ```bash
   top
   # Look for high CPU usage
   
   # Check bandwidth
   sudo iftop -i wg0
   ```

3. **Test without VPN:**
   ```bash
   # Disconnect VPN
   # Run speed test: fast.com or speedtest.net
   # Reconnect VPN
   # Run speed test again
   # Compare results
   ```

**Solutions:**

**Adjust MTU (Maximum Transmission Unit):**
```bash
# Add to client config [Interface] section:
MTU = 1420

# Or try:
MTU = 1380
```

**Optimize server settings:**
```bash
# Add to /etc/sysctl.conf
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_congestion_control = bbr

# Apply
sudo sysctl -p
```

**Check for packet loss:**
```bash
# Monitor for retransmissions
sudo tcpdump -i wg0 -n -vvv 'tcp[tcpflags] & tcp-syn != 0'
```

### Problem: Connection Drops Frequently

**Symptoms:**
- Must manually reconnect
- Connection works then stops after inactivity
- Handshake failures

**Solutions:**

**Verify PersistentKeepalive:**
```bash
# Check client config has:
PersistentKeepalive = 25

# Or try more aggressive:
PersistentKeepalive = 15
```

**Monitor handshakes:**
```bash
watch -n 5 'sudo wg show wg0 | grep "latest handshake"'
```

**Check for router/firewall UDP timeout:**
- Some NAT routers close UDP connections after 60 seconds
- Keepalive must be less than router timeout

---

## DNS Problems

### Problem: Cannot Resolve Hostnames

**Symptoms:**
- `ping 8.8.8.8` works (IP addresses)
- `ping google.com` fails (hostnames)
- `curl ifconfig.me` shows "Could not resolve host"

**Diagnostic Steps:**

1. **Check DNS in client config:**
   ```bash
   cat /etc/wireguard/wg0.conf | grep DNS
   # Or check WireGuard app settings
   ```

2. **Test DNS manually:**
   ```bash
   nslookup google.com 1.1.1.1
   # Should resolve successfully
   ```

3. **Check current DNS servers:**
   ```bash
   # Linux/macOS
   cat /etc/resolv.conf
   
   # Windows PowerShell
   Get-DnsClientServerAddress
   ```

**Solutions:**

**Add DNS to client config:**
```ini
[Interface]
DNS = 1.1.1.1, 8.8.8.8
```

**Test different DNS servers:**
```ini
# Cloudflare
DNS = 1.1.1.1, 1.0.0.1

# Google
DNS = 8.8.8.8, 8.8.4.4

# Quad9
DNS = 9.9.9.9, 149.112.112.112
```

**Manually set DNS (temporary testing):**
```bash
# macOS
sudo networksetup -setdnsservers "WireGuard" 1.1.1.1 8.8.8.8

# Linux
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf

# Windows (PowerShell as Admin)
Set-DnsClientServerAddress -InterfaceAlias "WireGuard" -ServerAddresses ("1.1.1.1","8.8.8.8")
```

---

## Platform-Specific Issues

### iOS Issues

**Problem: VPN connects then immediately disconnects**

Solution:
- Ensure "On Demand" is disabled in iOS settings
- Check iOS device has internet before connecting
- Verify endpoint IP is correct (not hostname)
- Try deleting and re-importing configuration

**Problem: Cannot import QR code**

Solution:
- Ensure QR code image is clear and visible
- Try importing via file instead
- Check camera permissions for WireGuard app

### macOS Issues

**Problem: DNS not working after connection**

Solution:
```bash
# Reset DNS
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# Check routing table
netstat -rn
```

**Problem: Connection works but some apps don't**

Solution:
- Some apps may bypass VPN
- Check "Exclude Private IPs" setting in WireGuard
- Ensure split tunneling is disabled if you want full tunnel

### Windows Issues

**Problem: "The requested operation requires elevation"**

Solution:
- Run WireGuard as Administrator
- Right-click → Run as Administrator

**Problem: Windows Defender blocks connection**

Solution:
- Add WireGuard to Windows Defender exceptions
- Allow through firewall

### Router Issues

**Problem: Router connects but home devices don't use VPN**

Solution:
- Enable "Redirect Internet traffic" in router VPN settings
- Check router routing table
- Ensure NAT is enabled on router
- Verify WireGuard is set as default gateway

---

## Advanced Diagnostics

### Complete Diagnostic Script

Run this on the server:

```bash
#!/bin/bash
echo "=== WireGuard Diagnostics ==="
echo
echo "1. Service Status:"
systemctl status wg-quick@wg0 --no-pager
echo
echo "2. Interface Status:"
sudo wg show wg0
echo
echo "3. Network Interfaces:"
ip addr show wg0
echo
echo "4. IP Forwarding:"
sysctl net.ipv4.ip_forward
echo
echo "5. Listening Port:"
sudo ss -ulnp | grep 51820
echo
echo "6. INPUT Chain:"
sudo iptables -L INPUT -n -v | grep 51820
echo
echo "7. FORWARD Chain:"
sudo iptables -L FORWARD -n -v --line-numbers | head -20
echo
echo "8. NAT Rules:"
sudo iptables -t nat -L POSTROUTING -n -v
echo
echo "9. Recent Logs:"
sudo journalctl -u wg-quick@wg0 -n 20 --no-pager
echo
echo "10. Route Table:"
ip route show
```

Save as `wireguard-diagnostics.sh`, make executable, and run:
```bash
chmod +x wireguard-diagnostics.sh
./wireguard-diagnostics.sh > diagnostics-output.txt
```

### Packet Capture

Capture WireGuard traffic for analysis:

```bash
# Capture 100 packets
sudo tcpdump -i wg0 -w wireguard-capture.pcap -c 100

# Capture with specific filter
sudo tcpdump -i wg0 -n 'host 10.10.10.2' -w client-capture.pcap

# Read capture
sudo tcpdump -r wireguard-capture.pcap
```

### Log Analysis

```bash
# View all WireGuard logs
sudo journalctl -u wg-quick@wg0 --no-pager

# Follow logs in real-time
sudo journalctl -u wg-quick@wg0 -f

# Filter for errors
sudo journalctl -u wg-quick@wg0 | grep -i error

# Last 24 hours
sudo journalctl -u wg-quick@wg0 --since "24 hours ago"
```

### Network Path Testing

```bash
# Traceroute from client
traceroute 8.8.8.8

# MTR (better than traceroute)
mtr -n 8.8.8.8

# Test specific port
nc -zv YOUR_VPS_IP 51820
```

---

## Getting Help

If you're still having issues:

1. **Gather diagnostics:**
   - Run diagnostic script above
   - Collect client-side logs
   - Note error messages

2. **Check existing issues:**
   - Search GitHub Issues
   - Check WireGuard documentation

3. **Open an issue:**
   - Include diagnostic output
   - Describe what you've tried
   - Specify your environment (OS, cloud provider, etc.)

4. **Community support:**
   - WireGuard mailing list
   - Reddit r/WireGuard
   - Stack Overflow

---

## Common Error Messages

### "Operation not permitted"
- Run with sudo
- Check file permissions

### "Cannot resolve host"
- DNS issue (see DNS Problems section)
- Check internet connectivity

### "Connection refused"
- Service not running
- Wrong port
- Firewall blocking

### "Handshake did not complete"
- Clock skew (time sync issue)
- Wrong keys
- Network issue

### "Invalid key"
- Key format incorrect
- Wrong key type (public vs private)
- Key file corrupted

---

**Remember:** 99% of issues are:
1. Cloud firewall not configured (UDP 51820)
2. FORWARD chain rule order wrong
3. IP forwarding not enabled
4. DNS not configured in client

Check these four things first!
