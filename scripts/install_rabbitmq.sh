#!/bin/bash
set -e

# === Configurable variables ===
RABBIT_USER="smessvn"
RABBIT_PASS="befzeV-5nifhu-rawcuf"

echo ">>> Updating system..."
sudo apt update -y && sudo apt upgrade -y

echo ">>> Installing dependencies..."
sudo apt install -y curl gnupg apt-transport-https lsb-release

# === Add Erlang repository (required for RabbitMQ 3.12+) ===
if [ ! -f /usr/share/keyrings/erlang.gpg ]; then
  echo ">>> Adding Erlang signing key..."
  # Try multiple methods to get the Erlang key
  if curl -fsSL https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | sudo gpg --dearmor -o /usr/share/keyrings/erlang.gpg; then
    echo ">>> Erlang key added successfully via HTTPS"
  elif curl -fsSL http://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | sudo gpg --dearmor -o /usr/share/keyrings/erlang.gpg; then
    echo ">>> Erlang key added successfully via HTTP"
  else
    echo ">>> Warning: Could not download Erlang key. Trying alternative method..."
    # Alternative: Use Ubuntu's default Erlang package (may be older version)
    echo ">>> Installing Erlang from Ubuntu repositories..."
    sudo apt install -y erlang-base erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key erlang-runtime-tools erlang-snmp erlang-ssl erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl
    echo ">>> Erlang installed from Ubuntu repositories"
  fi
fi

if [ ! -f /etc/apt/sources.list.d/erlang.list ] && [ -f /usr/share/keyrings/erlang.gpg ]; then
  echo ">>> Adding Erlang repository..."
  echo "deb [signed-by=/usr/share/keyrings/erlang.gpg] https://packages.erlang-solutions.com/ubuntu $(lsb_release -cs) contrib" | sudo tee /etc/apt/sources.list.d/erlang.list
fi

# === Add RabbitMQ repo (idempotent) ===
if [ ! -f /usr/share/keyrings/com.rabbitmq.gpg ]; then
  echo ">>> Adding RabbitMQ signing key..."
  curl -fsSL https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/com.rabbitmq.gpg
fi

if [ ! -f /etc/apt/sources.list.d/rabbitmq.list ]; then
  echo ">>> Adding RabbitMQ repository..."
  echo "deb [signed-by=/usr/share/keyrings/com.rabbitmq.gpg] https://packagecloud.io/rabbitmq/rabbitmq-server/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/rabbitmq.list
fi

echo ">>> Updating package lists..."
sudo apt update -y

# === Install Erlang (if not already installed from Ubuntu repos) ===
if ! command -v erl &> /dev/null; then
  echo ">>> Installing Erlang 26.0+..."
  if sudo apt install -y esl-erlang; then
    echo ">>> Erlang 26.0+ installed successfully"
  else
    echo ">>> Warning: Could not install esl-erlang. Checking if Erlang is available..."
    if command -v erl &> /dev/null; then
      echo ">>> Erlang is already installed"
    else
      echo ">>> Error: Erlang installation failed. Please check your internet connection and try again."
      exit 1
    fi
  fi
else
  echo ">>> Erlang is already installed"
fi

echo ">>> Installing RabbitMQ..."
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
