# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-14

### Added
- Initial release of WireGuard Static IP VPN setup
- Complete installation guide for Ubuntu 24.04 LTS
- Multi-device support (Router, iOS, macOS, Windows)
- QR code generation for mobile devices
- Comprehensive troubleshooting guide
- Security best practices documentation
- Coexistence with NetBird mesh network
- Automatic iptables rule configuration
- Persistent configuration across reboots
- Real-time monitoring commands
- Backup and restore procedures

### Fixed
- FORWARD chain rule ordering for proper internet access
- NAT masquerading configuration
- Cloud provider firewall integration (OCI security rules)
- DNS resolution in client configurations
- Persistent keepalive for stable connections

### Security
- Unique key pairs for each device
- Secure file permissions (600) for all keys and configs
- Minimal attack surface (only UDP 51820 exposed)
- Separate network subnets for isolation
- IP forwarding with secure NAT configuration

### Documentation
- Complete README with step-by-step instructions
- Troubleshooting guide for common issues
- Client setup guides for all platforms
- Security considerations and best practices
- Monitoring and maintenance procedures
- Contributing guidelines
- MIT License

### Tested
- Ubuntu 24.04 LTS (arm64)
- WireGuard Tools v1.0.20210914
- iOS 17+ (iPhone/iPad)
- macOS 14+ (Sonoma)
- Windows 11
- ASUS Router with WireGuard support
- Oracle Cloud Infrastructure (OCI)
- Coexistence with NetBird v0.59.0

## [Unreleased]

### Planned
- Automated deployment scripts (Ansible)
- Docker container version
- Monitoring dashboard (Grafana)
- IPv6 support
- Multi-server failover configuration
- Load balancing setup
- Android client guide
- Linux desktop client guide
- Terraform deployment templates
- Performance optimization guide

---

## Version History

- **1.0.0** (2025-10-14) - Initial production-ready release
