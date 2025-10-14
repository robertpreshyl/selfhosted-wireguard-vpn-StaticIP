# Quick Start Guide

Get your WireGuard Static IP VPN running in 15 minutes!

## Prerequisites

- Ubuntu 24.04 VPS with public IP
- SSH access to VPS
- Cloud provider console access (for firewall rules)

## Installation

### 1. Install WireGuard (2 minutes)

```bash
ssh ubuntu@YOUR_VPS_IP
sudo apt update
sudo apt install -y wireguard wireguard-tools qrencode
```

### 2. Enable IP Forwarding (1 minute)

```bash
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### 3. Generate Keys (2 minutes)

```bash
cd /etc/wireguard
sudo sh -c 'umask 077 && wg genkey | tee server_private.key | wg pubkey > server_public.key'
sudo sh -c 'umask 077 && wg genkey | tee client_private.key | wg pubkey > client_public.key'
```

### 4. Create Server Config (3 minutes)

```bash
# Get your default interface
DEFAULT_IF=$(ip route | grep default | awk '{print $5}')

# Get keys
SERVER_PRIVATE=$(sudo cat server_private.key)
CLIENT_PUBLIC=$(sudo cat client_public.key)

# Create config
sudo tee /etc/wireguard/wg0.conf > /dev/null <<EOF
[Interface]
Address = 10.10.10.1/24
ListenPort = 51820
PrivateKey = $SERVER_PRIVATE

PostUp = iptables -I FORWARD 1 -i wg0 -j ACCEPT
PostUp = iptables -I FORWARD 1 -o wg0 -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o $DEFAULT_IF -j MASQUERADE

PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
PostDown = iptables -D FORWARD -o wg0 -j ACCEPT
PostDown = iptables -D nat -POSTROUTING -o $DEFAULT_IF -j MASQUERADE

[Peer]
PublicKey = $CLIENT_PUBLIC
AllowedIPs = 10.10.10.2/32
PersistentKeepalive = 25
EOF

sudo chmod 600 /etc/wireguard/wg0.conf
```

### 5. Configure Firewall (2 minutes)

```bash
# Local firewall
sudo iptables -I INPUT -p udp --dport 51820 -m conntrack --ctstate NEW -j ACCEPT
sudo apt install -y iptables-persistent
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

**IMPORTANT:** Add cloud provider firewall rule:
- Protocol: UDP
- Port: 51820
- Source: 0.0.0.0/0

### 6. Start WireGuard (1 minute)

```bash
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
sudo wg show
```

### 7. Create Client Config (2 minutes)

```bash
VPS_IP=$(curl -s ifconfig.me)
CLIENT_PRIVATE=$(sudo cat client_private.key)
SERVER_PUBLIC=$(sudo cat server_public.key)

cat > ~/client.conf <<EOF
[Interface]
Address = 10.10.10.2/24
PrivateKey = $CLIENT_PRIVATE
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = $SERVER_PUBLIC
Endpoint = $VPS_IP:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

# Generate QR code for mobile
qrencode -t ansiutf8 < ~/client.conf
```

### 8. Connect Client (2 minutes)

**iOS/Android:**
- Install WireGuard app
- Scan QR code
- Toggle ON

**macOS/Windows:**
- Install WireGuard app
- Import `client.conf`
- Activate

### 9. Verify (1 minute)

```bash
# On client device
curl ifconfig.me
# Should show VPS IP

ping 8.8.8.8
# Should work
```

## Done! 🎉

Your static IP VPN is ready. All traffic from connected devices now exits from your VPS IP.

## Next Steps

- Add more clients (see full README)
- Configure router (see Router Setup section)
- Set up monitoring
- Read security best practices

## Troubleshooting

**No internet on client?**
1. Check cloud firewall rule for UDP 51820
2. Verify FORWARD rules: `sudo iptables -L FORWARD -n -v`
3. Check NAT: `sudo iptables -t nat -L POSTROUTING -n -v`

**Can't connect?**
1. Check service: `sudo systemctl status wg-quick@wg0`
2. Verify port open: `sudo ss -ulnp | grep 51820`
3. Test from client: `nc -zvu VPS_IP 51820`

For detailed help, see the [full README](README.md) and [Troubleshooting Guide](TROUBLESHOOTING.md).
