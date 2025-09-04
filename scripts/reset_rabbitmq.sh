#!/bin/bash
set -e

# === Configurable variables ===
RABBIT_USER="smessvn"
RABBIT_PASS="befzeV-5nifhu-rawcuf"


echo ">>> Checking RabbitMQ service..."
if ! systemctl is-active --quiet rabbitmq-server; then
  echo "RabbitMQ is not running. Starting service..."
  sudo systemctl start rabbitmq-server
fi

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

echo ">>> RabbitMQ user configured successfully!"
echo ">>> Login with: $RABBIT_USER / $RABBIT_PASS"
