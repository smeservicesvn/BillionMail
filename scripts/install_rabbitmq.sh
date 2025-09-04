#!/bin/bash
set -e

# === Configurable variables ===
RABBIT_USER="smessvn"
RABBIT_PASS="befzeV-5nifhu-rawcuf"

echo ">>> Updating system..."
sudo apt update -y && sudo apt upgrade -y

echo ">>> Installing dependencies..."
sudo apt install -y curl gnupg apt-transport-https

# === Add RabbitMQ repo (idempotent) ===
if [ ! -f /usr/share/keyrings/com.rabbitmq.gpg ]; then
  echo ">>> Adding RabbitMQ signing key..."
  curl -fsSL https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/com.rabbitmq.gpg
fi

if [ ! -f /etc/apt/sources.list.d/rabbitmq.list ]; then
  echo ">>> Adding RabbitMQ repository..."
  echo "deb [signed-by=/usr/share/keyrings/com.rabbitmq.gpg] https://packagecloud.io/rabbitmq/rabbitmq-server/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/rabbitmq.list
fi

echo ">>> Installing RabbitMQ..."
sudo apt update -y
sudo apt install -y rabbitmq-server

echo ">>> Enabling and starting service..."
sudo systemctl enable rabbitmq-server
sudo systemctl start rabbitmq-server

echo ">>> Enabling management plugin..."
sudo rabbitmq-plugins enable rabbitmq_management || true

# === Create or update user ===
if sudo rabbitmqctl list_users | grep -q "$RABBIT_USER"; then
  echo ">>> Updating password for existing RabbitMQ user: $RABBIT_USER"
  sudo rabbitmqctl change_password "$RABBIT_USER" "$RABBIT_PASS"
else
  echo ">>> Creating RabbitMQ user: $RABBIT_USER"
  sudo rabbitmqctl add_user "$RABBIT_USER" "$RABBIT_PASS"
  sudo rabbitmqctl set_user_tags "$RABBIT_USER" administrator
  sudo rabbitmqctl set_permissions -p / "$RABBIT_USER" ".*" ".*" ".*"
fi

echo ">>> Allowing firewall ports..."
sudo ufw allow 5672/tcp || true
sudo ufw allow 15672/tcp || true

echo ">>> RabbitMQ installation & configuration complete!"
echo ">>> Access management UI at: http://<server-ip>:15672"
echo ">>> Login with: $RABBIT_USER / $RABBIT_PASS"
