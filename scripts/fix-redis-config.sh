#!/bin/bash
# Fix Redis configuration

REDIS_PASSWORD="AntigravityCache2024!"

# Find the correct config file
if [ -f /etc/redis/redis.conf ]; then
    REDIS_CONF="/etc/redis/redis.conf"
elif [ -f /etc/redis.conf ]; then
    REDIS_CONF="/etc/redis.conf"
else
    echo "❌ Cannot find redis.conf"
    exit 1
fi

echo "📝 Updating $REDIS_CONF..."

# Remove any existing requirepass lines
sudo sed -i '/^requirepass/d' "$REDIS_CONF"
sudo sed -i '/^bind/d' "$REDIS_CONF"

# Add our configuration
sudo tee -a "$REDIS_CONF" > /dev/null <<EOF

# Antigravity Cache Configuration (Updated)
requirepass $REDIS_PASSWORD
bind 0.0.0.0
protected-mode yes
EOF

# Restart Redis
sudo systemctl restart redis-server 2>/dev/null || sudo systemctl restart redis

sleep 2

# Test
echo "🧪 Testing connection..."
redis-cli -a "$REDIS_PASSWORD" --no-auth-warning PING

echo ""
echo "✅ Redis is ready!"
echo "Connection: redis://10.10.1.53:6379"
echo "Password: $REDIS_PASSWORD"
