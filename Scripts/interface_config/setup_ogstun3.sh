#!/bin/bash

echo "=== Setting up ogstun3 for UPF2 ==="

# 1. Create interface if missing
if ! ip link show ogstun3 >/dev/null 2>&1; then
    echo "[+] Creating ogstun3 interface"
    ip tuntap add name ogstun3 mode tun
else
    echo "[*] ogstun3 already exists"
fi

# 2. Assign IP if not presentss
if ! ip addr show ogstun3 | grep -q "10.47.0.1"; then
    echo "[+] Assigning IP 10.47.0.1/16"
    ip addr add 10.47.0.1/16 dev ogstun3
fi

# 3. Bring interface UP
echo "[+] Bringing ogstun3 UP"
ip link set ogstun3 up

# 4. Enable IPv4 forwarding
echo "[+] Enabling IP forwarding"
sysctl -w net.ipv4.ip_forward=1 >/dev/null

# 5. NAT rule
echo "[+] Adding NAT for 10.47.0.0/16"
iptables -t nat -C POSTROUTING -s 10.47.0.0/16 ! -o ogstun3 -j MASQUERADE 2>/dev/null
if [ $? -ne 0 ]; then
    iptables -t nat -A POSTROUTING -s 10.47.0.0/16 ! -o ogstun3 -j MASQUERADE
fi

# 6. Forwarding rules
iptables -C FORWARD -i ogstun3 -j ACCEPT 2>/dev/null
if [ $? -ne 0 ]; then
    iptables -A FORWARD -i ogstun3 -j ACCEPT
fi

iptables -C FORWARD -o ogstun3 -j ACCEPT 2>/dev/null
if [ $? -ne 0 ]; then
    iptables -A FORWARD -o ogstun3 -j ACCEPT
fi

echo "=== ogstun3 setup completed ==="
