#!/bin/bash

echo "=== Setting up ogstun2 for UPF2 ==="

# 1. Create interface if missing
if ! ip link show ogstun2 >/dev/null 2>&1; then
    echo "[+] Creating ogstun2 interface"
    ip tuntap add name ogstun2 mode tun
else
    echo "[*] ogstun2 already exists"
fi

# 2. Assign IP if not present
if ! ip addr show ogstun2 | grep -q "10.46.0.1"; then
    echo "[+] Assigning IP 10.46.0.1/16"
    ip addr add 10.46.0.1/16 dev ogstun2
fi

# 3. Bring interface UP
echo "[+] Bringing ogstun2 UP"
ip link set ogstun2 up

# 4. Enable IPv4 forwarding
echo "[+] Enabling IP forwarding"
sysctl -w net.ipv4.ip_forward=1 >/dev/null

# 5. NAT rule
echo "[+] Adding NAT for 10.46.0.0/16"
iptables -t nat -C POSTROUTING -s 10.46.0.0/16 ! -o ogstun2 -j MASQUERADE 2>/dev/null
if [ $? -ne 0 ]; then
    iptables -t nat -A POSTROUTING -s 10.46.0.0/16 ! -o ogstun2 -j MASQUERADE
fi

# 6. Forwarding rules
iptables -C FORWARD -i ogstun2 -j ACCEPT 2>/dev/null
if [ $? -ne 0 ]; then
    iptables -A FORWARD -i ogstun2 -j ACCEPT
fi

iptables -C FORWARD -o ogstun2 -j ACCEPT 2>/dev/null
if [ $? -ne 0 ]; then
    iptables -A FORWARD -o ogstun2 -j ACCEPT
fi

echo "=== ogstun2 setup completed ==="
