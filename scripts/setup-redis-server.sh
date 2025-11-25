#!/bin/bash
# Redis Server Setup Script for Antigravity Cache
# Target: 10.10.1.53

set -e

echo "🚀 Installing Redis Server..."

# Detect distro and install
if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y redis-server
elif command -v yum &> /dev/null; then
    sudo yum install -y redis
elif command -v dnf &> /dev/null; then
    sudo dnf install -y redis
else
    echo "❌ Unsupported package manager"
    exit 1
fi

echo "✅ Redis installed"

# Backup original config
sudo cp /etc/redis/redis.conf /etc/redis/redis.conf.backup 2>/dev/null || \
sudo cp /etc/redis.conf /etc/redis.conf.backup 2>/dev/null || true

# Configure Redis
REDIS_CONF="/etc/redis/redis.conf"
if [ ! -f "$REDIS_CONF" ]; then
    REDIS_CONF="/etc/redis.conf"
fi

echo "⚙️  Configuring Redis..."

# Set password
REDIS_PASSWORD="AntigravityCache2024!"

sudo tee -a "$REDIS_CONF" > /dev/null <<EOF

# Antigravity Cache Configuration
requirepass $REDIS_PASSWORD
bind 0.0.0.0
protected-mode yes
port 6379
maxmemory 256mb
maxmemory-policy allkeys-lru
appendonly yes
appendfilename "antigravity-cache.aof"
EOF

echo "✅ Configuration updated"

# Enable and start Redis
sudo systemctl enable redis-server 2>/dev/null || sudo systemctl enable redis
sudo systemctl restart redis-server 2>/dev/null || sudo systemctl restart redis

echo "✅ Redis server started"

# Test connection
sleep 2
redis-cli -a "$REDIS_PASSWORD" PING

echo ""
echo "🎉 Redis Setup Complete!"
echo ""
echo "Connection Details:"
echo "  Host: 10.10.1.53"
echo "  Port: 6379"
echo "  Password: $REDIS_PASSWORD"
echo ""
echo "Test from Windows:"
echo "  redis-cli -h 10.10.1.53 -a $REDIS_PASSWORD PING"
