#!/bin/bash
# Open Redis port 6379

echo "🔓 Opening port 6379 for Redis..."

# Check which firewall is in use
if command -v firewall-cmd &> /dev/null; then
    echo "Using firewalld..."
    sudo firewall-cmd --permanent --add-port=6379/tcp
    sudo firewall-cmd --reload
    echo "✅ Port 6379 opened in firewalld"
elif command -v iptables &> /dev/null; then
    echo "Using iptables..."
    sudo iptables -A INPUT -p tcp --dport 6379 -j ACCEPT
    sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
    echo "✅ Port 6379 opened in iptables"
else
    echo "⚠️  No firewall detected or already open"
fi

# Verify Redis is listening
echo ""
echo "📡 Redis listening status:"
sudo netstat -tlnp | grep 6379 || sudo ss -tlnp | grep 6379

echo ""
echo "✅ Firewall configuration complete"
