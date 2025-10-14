#!/bin/bash

# WireGuard VPN Setup Verification Script
# This script verifies that all components of the WireGuard VPN are working correctly

# Don't exit on errors - we want to see all results
set +e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   WireGuard VPN - Comprehensive System Verification           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASS=0
FAIL=0
WARN=0

# Helper functions
print_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASS++))
}

print_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAIL++))
}

print_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARN++))
}

print_info() {
    echo -e "  $1"
}

# Test 1: Check if WireGuard is installed
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. WireGuard Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v wg &> /dev/null; then
    VERSION=$(wg --version | head -1)
    print_pass "WireGuard is installed: $VERSION"
else
    print_fail "WireGuard is not installed"
fi
echo

# Test 2: Check WireGuard service status
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. WireGuard Service Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if systemctl is-active --quiet wg-quick@wg0; then
    print_pass "WireGuard service is active"
    if systemctl is-enabled --quiet wg-quick@wg0; then
        print_pass "WireGuard service is enabled (auto-start on boot)"
    else
        print_warn "WireGuard service is not enabled for auto-start"
    fi
else
    print_fail "WireGuard service is not active"
fi
echo

# Test 3: Check if wg0 interface exists
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Network Interface Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ip addr show wg0 &> /dev/null; then
    print_pass "wg0 interface exists"
    WG0_IP=$(ip addr show wg0 | grep "inet " | awk '{print $2}')
    print_info "Interface IP: $WG0_IP"
else
    print_fail "wg0 interface does not exist"
fi
echo

# Test 4: Check if port 51820 is listening
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Port Listening Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if sudo ss -ulnp | grep -q ":51820"; then
    print_pass "WireGuard is listening on UDP port 51820"
else
    print_fail "WireGuard is not listening on port 51820"
fi
echo

# Test 5: Check IP forwarding
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. IP Forwarding Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
IP_FORWARD=$(sysctl -n net.ipv4.ip_forward)
if [ "$IP_FORWARD" = "1" ]; then
    print_pass "IP forwarding is enabled"
else
    print_fail "IP forwarding is disabled"
fi
echo

# Test 6: Check iptables INPUT rules
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. Firewall INPUT Rules"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if sudo iptables -L INPUT -n -v | grep -q "51820"; then
    print_pass "iptables allows UDP port 51820"
else
    print_fail "iptables does not allow UDP port 51820"
fi
echo

# Test 7: Check iptables FORWARD rules
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7. Firewall FORWARD Rules"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
FORWARD_RULES=$(sudo iptables -L FORWARD -n --line-numbers | grep wg0)
if [ -n "$FORWARD_RULES" ]; then
    print_pass "iptables FORWARD rules exist for wg0"
    
    # Check if wg0 rules are at the top (critical!)
    FIRST_WG0_LINE=$(sudo iptables -L FORWARD -n --line-numbers | grep wg0 | head -1 | awk '{print $1}')
    if [ "$FIRST_WG0_LINE" -le 3 ]; then
        print_pass "wg0 FORWARD rules are at top of chain (position $FIRST_WG0_LINE)"
    else
        print_warn "wg0 FORWARD rules are not at top (position $FIRST_WG0_LINE) - may cause issues"
    fi
else
    print_fail "iptables FORWARD rules missing for wg0"
fi
echo

# Test 8: Check NAT/POSTROUTING rules
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "8. NAT/Masquerading Rules"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if sudo iptables -t nat -L POSTROUTING -n -v | grep -q "MASQUERADE"; then
    print_pass "NAT/Masquerading is configured"
    NAT_PKTS=$(sudo iptables -t nat -L POSTROUTING -n -v | grep MASQUERADE | awk '{print $1}' | head -1)
    print_info "Packets masqueraded: $NAT_PKTS"
else
    print_fail "NAT/Masquerading is not configured"
fi
echo

# Test 9: Check WireGuard configuration
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "9. WireGuard Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f /etc/wireguard/wg0.conf ]; then
    print_pass "Configuration file exists"
    
    # Check permissions
    PERMS=$(stat -c %a /etc/wireguard/wg0.conf)
    if [ "$PERMS" = "600" ]; then
        print_pass "Configuration file has secure permissions (600)"
    else
        print_warn "Configuration file permissions are $PERMS (should be 600)"
    fi
else
    print_fail "Configuration file does not exist"
fi
echo

# Test 10: Check peers
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "10. Configured Peers"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
PEER_COUNT=$(sudo wg show wg0 peers 2>/dev/null | wc -l)
if [ "$PEER_COUNT" -gt 0 ]; then
    print_pass "$PEER_COUNT peer(s) configured"
    
    # Check for active handshakes
    ACTIVE_PEERS=$(sudo wg show wg0 | grep "latest handshake" | grep -v "never" | wc -l)
    if [ "$ACTIVE_PEERS" -gt 0 ]; then
        print_pass "$ACTIVE_PEERS peer(s) have active handshakes"
    else
        print_warn "No peers have active handshakes (no clients connected yet)"
    fi
else
    print_warn "No peers configured yet"
fi
echo

# Test 11: Check public IP
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "11. Public IP Address"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
PUBLIC_IP=$(curl -s --max-time 5 ifconfig.me)
if [ -n "$PUBLIC_IP" ]; then
    print_pass "Public IP: $PUBLIC_IP"
    print_info "Clients will use this IP as endpoint"
else
    print_warn "Could not determine public IP"
fi
echo

# Test 12: Check NetBird coexistence
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "12. NetBird Coexistence Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if systemctl is-active --quiet netbird 2>/dev/null; then
    print_pass "NetBird service is active (coexisting successfully)"
    if ip addr show wt0 &> /dev/null; then
        WT0_IP=$(ip addr show wt0 | grep "inet " | awk '{print $2}')
        print_info "NetBird interface (wt0): $WT0_IP"
    fi
else
    print_info "NetBird is not installed (not an issue if not using NetBird)"
fi
echo

# Summary
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                      Verification Summary                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo
echo -e "${GREEN}Passed:${NC} $PASS"
echo -e "${YELLOW}Warnings:${NC} $WARN"
echo -e "${RED}Failed:${NC} $FAIL"
echo

# Overall status
if [ $FAIL -eq 0 ]; then
    if [ $WARN -eq 0 ]; then
        echo -e "${GREEN}✓ All checks passed! Your WireGuard VPN is fully operational.${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠ Some warnings detected. VPN may work but review warnings above.${NC}"
        exit 0
    fi
else
    echo -e "${RED}✗ Some checks failed. Please review and fix the issues above.${NC}"
    exit 1
fi
