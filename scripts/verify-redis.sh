#!/bin/bash
# Complete Redis setup verification and firewall configuration

echo "=== Redis Configuration Check ==="
echo ""

# 1. Check if Redis is running
echo "1️⃣ Redis Service Status:"
sudo systemctl status redis-server --no-pager | head -10
echo ""

# 2. Check what IP Redis is bound to
echo "2️⃣ Redis Bind Configuration:"
grep "^bind" /etc/redis.conf 2>/dev/null || grep "^bind" /etc/redis/redis.conf 2>/dev/null
echo ""

# 3. Check if Redis is listening on the network
echo "3️⃣ Redis Network Listening:"
sudo ss -tlnp | grep 6379
echo ""

# 4. Test local connection
echo "4️⃣ Testing Local Connection:"
redis-cli -a "AntigravityCache2024!" PING 2>&1
echo ""

# 5. Open firewall (if needed)
echo "5️⃣ Firewall Configuration:"
if sudo iptables -L INPUT -n | grep -q "6379"; then
    echo "✅ Port 6379 already open in iptables"
else
    echo "Opening port 6379..."
    sudo iptables -I INPUT -p tcp --dport 6379 -j ACCEPT
    echo "✅ Port 6379 opened"
fi
echo ""

# 6. Show current iptables rules for port 6379
echo "6️⃣ Current Firewall Rules for Redis:"
sudo iptables -L INPUT -n | grep -E "6379|Chain INPUT"
echo ""

echo "=== Setup Complete ==="
echo "Test from Windows:"
echo "  redis-cli -h 10.10.1.53 -a AntigravityCache2024! PING"
