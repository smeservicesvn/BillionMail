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
ERLANG_KEY_ADDED=false

if [ ! -f /usr/share/keyrings/erlang.gpg ]; then
  echo ">>> Adding Erlang signing key..."
  # Try multiple methods to get the Erlang key
  if curl -fsSL https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | sudo gpg --dearmor -o /usr/share/keyrings/erlang.gpg; then
    echo ">>> Erlang key added successfully via HTTPS"
    ERLANG_KEY_ADDED=true
  elif curl -fsSL http://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | sudo gpg --dearmor -o /usr/share/keyrings/erlang.gpg; then
    echo ">>> Erlang key added successfully via HTTP"
    ERLANG_KEY_ADDED=true
  else
    echo ">>> Warning: Could not download Erlang key from Erlang Solutions repository."
    echo ">>> This may cause RabbitMQ installation to fail if Erlang 26.0+ is not available."
  fi
fi

if [ "$ERLANG_KEY_ADDED" = true ] && [ ! -f /etc/apt/sources.list.d/erlang.list ]; then
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

# === Install Erlang 26.0+ ===
echo ">>> Checking Erlang version requirements..."
if command -v erl &> /dev/null; then
  ERLANG_VERSION=$(erl -eval 'io:format("~s", [erlang:system_info(version)]), halt().' -noshell)
  echo ">>> Current Erlang version: $ERLANG_VERSION"
  
  # Check if version is >= 26.0
  if [[ "$ERLANG_VERSION" =~ ^([0-9]+)\.([0-9]+) ]]; then
    MAJOR_VERSION=${BASH_REMATCH[1]}
    MINOR_VERSION=${BASH_REMATCH[2]}
    
    if [ "$MAJOR_VERSION" -ge 26 ]; then
      echo ">>> Erlang $ERLANG_VERSION meets RabbitMQ requirements"
    else
      echo ">>> Erlang $ERLANG_VERSION is too old. Need 26.0+ for RabbitMQ 3.12+"
      echo ">>> Removing old Erlang packages..."
      sudo apt remove -y erlang-base erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key erlang-runtime-tools erlang-snmp erlang-ssl erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl || true
      sudo apt autoremove -y
    fi
  fi
fi

# Try to install esl-erlang (Erlang 26.0+)
ERLANG_NEEDS_UPDATE=false
if ! command -v erl &> /dev/null; then
  ERLANG_NEEDS_UPDATE=true
else
  # Check if current version is >= 26.0
  ERLANG_VERSION=$(erl -eval 'io:format("~s", [erlang:system_info(version)]), halt().' -noshell 2>/dev/null || echo "0.0")
  if [[ "$ERLANG_VERSION" =~ ^([0-9]+)\.([0-9]+) ]]; then
    MAJOR_VERSION=${BASH_REMATCH[1]}
    if [ "$MAJOR_VERSION" -lt 26 ]; then
      ERLANG_NEEDS_UPDATE=true
    fi
  else
    ERLANG_NEEDS_UPDATE=true
  fi
fi

if [ "$ERLANG_NEEDS_UPDATE" = true ]; then
  echo ">>> Installing Erlang 26.0+..."
  if sudo apt install -y esl-erlang; then
    echo ">>> Erlang 26.0+ installed successfully"
  else
    echo ">>> Error: Could not install esl-erlang (Erlang 26.0+)"
    echo ">>> This is required for RabbitMQ 3.12+"
    echo ">>> The Erlang Solutions repository may be experiencing issues (504 timeout)"
    echo ">>> Trying alternative installation methods..."
    
    # Try to install from Ubuntu's backports or other sources
    echo ">>> Attempting to install Erlang from alternative sources..."
    if sudo apt install -y erlang-base erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key erlang-runtime-tools erlang-snmp erlang-ssl erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl; then
      echo ">>> Erlang installed from Ubuntu repositories"
      echo ">>> Note: This may be an older version. If RabbitMQ installation fails,"
      echo ">>> you may need to install an older version of RabbitMQ or wait for"
      echo ">>> the Erlang Solutions repository to be available."
    else
      echo ">>> All installation methods failed."
      echo ">>> Please try again later when the Erlang Solutions repository is available, or:"
      echo ">>> 1. Install an older version of RabbitMQ that supports Erlang 25.x"
      echo ">>> 2. Manually install Erlang 26.0+ from source"
      echo ">>> 3. Use a different server or try again later"
      exit 1
    fi
  fi
  fi
else
  echo ">>> Erlang 26.0+ is already installed"
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
