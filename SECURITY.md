# Security Policy

## 🔐 Reporting Security Vulnerabilities

We take the security of this project seriously. If you discover a security vulnerability, please follow responsible disclosure practices.

### How to Report

**DO NOT** create a public GitHub issue for security vulnerabilities.

Instead, please report security issues via:
1. **GitHub Security Advisories**: https://github.com/robertpreshyl/selfhosted-wireguard-vpn-StaticIP/security/advisories/new
2. **Email**: Contact the maintainer privately

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested remediation (if applicable)

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 5 business days
- **Fix & Disclosure**: Coordinated with reporter

---

## 🛡️ Security Best Practices

### Key Management

- **NEVER** commit private keys to version control
- Store keys with `600` permissions (owner read/write only)
- Use unique key pairs for each device
- Rotate keys periodically (recommended: every 6-12 months)
- Backup keys securely offline

### Server Hardening

```bash
# Disable password authentication (use SSH keys only)
sudo nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no

# Enable firewall
sudo ufw enable
sudo ufw allow 22/tcp
sudo ufw allow 51820/udp

# Automatic security updates
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

### Monitoring

```bash
# Monitor WireGuard connections
sudo wg show wg0

# Check for suspicious iptables modifications
sudo iptables -L -n -v

# Monitor failed authentication attempts
sudo journalctl -u wg-quick@wg0 -f
```

### Regular Maintenance

- Keep WireGuard updated: `sudo apt update && sudo apt upgrade wireguard`
- Review peer list monthly: `sudo wg show wg0 peers`
- Audit firewall rules: `sudo iptables -L -n -v`
- Check for unauthorized configuration changes

---

## 🚨 Known Security Considerations

### By Design
- **Full Tunnel**: All traffic routes through VPN (intended behavior)
- **Stateless Protocol**: WireGuard doesn't track sessions (feature, not bug)
- **No Authentication**: Uses cryptographic key verification only

### Deployment Considerations
- Cloud provider firewall rules must be configured correctly
- iptables rule order matters (ACCEPT rules before REJECT)
- PersistentKeepalive exposes connection patterns (disable if privacy-critical)
- DNS queries leak if not configured properly (ensure DNS is set in client config)

---

## 📋 Security Checklist

Before deploying to production, verify:

- [ ] All private keys have `600` permissions
- [ ] `/etc/wireguard/wg0.conf` has `600` permissions
- [ ] SSH key-based authentication enabled
- [ ] Password authentication disabled
- [ ] Firewall configured (ufw/iptables)
- [ ] OCI/Cloud provider firewall configured
- [ ] Automatic security updates enabled
- [ ] Monitoring/logging enabled
- [ ] Backup keys stored securely offline
- [ ] Test failover procedures
- [ ] Document emergency rollback procedures

---

## 🔄 Supported Versions

| Version | Supported          | Notes |
| ------- | ------------------ | ----- |
| 1.0.x   | :white_check_mark: | Current stable release |
| < 1.0   | :x:                | Beta versions not supported |

---

## 📚 Additional Resources

- [WireGuard Security Whitepaper](https://www.wireguard.com/papers/wireguard.pdf)
- [NIST Cryptographic Standards](https://csrc.nist.gov/)
- [OWASP Security Guidelines](https://owasp.org/)
- [CIS Ubuntu Hardening Benchmark](https://www.cisecurity.org/)

---

*Last Updated: October 2025*
