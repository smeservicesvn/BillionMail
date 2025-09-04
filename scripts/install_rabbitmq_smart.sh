#!/bin/bash
# Use set -e but with better error handling
set -e

# === Configurable variables ===
RABBIT_USER="smessvn"
RABBIT_PASS="befzeV-5nifhu-rawcuf"

# === Smart installation strategy ===
echo "🐇 Smart RabbitMQ Installer v2.0"
echo "=================================="

# Function to check network connectivity
check_connectivity() {
  local url=$1
  local timeout=${2:-10}
  if curl -fsSL --connect-timeout $timeout --max-time $timeout "$url" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Function to get Ubuntu version
get_ubuntu_version() {
  lsb_release -cs 2>/dev/null || echo "unknown"
}

# Function to check Erlang version (compatible with both sh and bash)
check_erlang_version() {
  if command -v erl >/dev/null 2>&1; then
    local version=$(erl -eval 'io:format("~s", [erlang:system_info(version)]), halt().' -noshell 2>/dev/null || echo "0.0")
    # Use sed instead of bash regex for compatibility
    local major_version=$(echo "$version" | sed -n 's/^\([0-9]*\)\..*/\1/p')
    if [ -n "$major_version" ] && [ "$major_version" -ge 0 ] 2>/dev/null; then
      echo "$major_version"
    else
      echo "0"
    fi
  else
    echo "0"
  fi
}

# Function to determine best installation strategy
determine_strategy() {
  local ubuntu_version=$(get_ubuntu_version)
  local erlang_version=$(check_erlang_version)
  
  echo ">>> System Analysis:"
  echo "   Ubuntu Version: $ubuntu_version"
  echo "   Current Erlang: $erlang_version"
  
  # Strategy 1: Use Docker (most reliable)
  if command -v docker >/dev/null 2>&1; then
    echo ">>> Strategy: Docker-based installation (recommended)"
    echo ">>> Docker found: $(which docker)"
    return 1
  else
    echo ">>> Docker not found, checking next strategy..."
  fi
  
  # Strategy 2: Use Snap (if available)
  if command -v snap >/dev/null 2>&1; then
    echo ">>> Strategy: Snap-based installation"
    echo ">>> Snap found: $(which snap)"
    return 2
  else
    echo ">>> Snap not found, checking next strategy..."
  fi
  
  # Strategy 3: Smart package installation
  if [ "$erlang_version" -ge 26 ] 2>/dev/null; then
    echo ">>> Strategy: Direct package installation (Erlang 26+ detected)"
    return 3
  else
    echo ">>> Strategy: Smart repository management"
    return 4
  fi
}

# Strategy 1: Docker installation
install_via_docker() {
  echo ">>> Installing RabbitMQ via Docker..."
  
  # Check if docker-compose is available
  if ! command -v docker-compose >/dev/null 2>&1; then
    echo ">>> Installing docker-compose..."
    sudo apt update -y || true
    sudo apt install -y docker-compose || true
  fi
  
  # Create docker-compose.yml
  cat > /tmp/rabbitmq-docker-compose.yml << 'EOF'
version: '3.8'
services:
  rabbitmq:
    image: rabbitmq:3.12-management
    container_name: rabbitmq
    restart: unless-stopped
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      - RABBITMQ_DEFAULT_USER=smessvn
      - RABBITMQ_DEFAULT_PASS=befzeV-5nifhu-rawcuf
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
      - rabbitmq_logs:/var/log/rabbitmq

volumes:
  rabbitmq_data:
  rabbitmq_logs:
EOF

  # Start RabbitMQ container
  echo ">>> Starting RabbitMQ container..."
  docker-compose -f /tmp/rabbitmq-docker-compose.yml up -d || {
    echo ">>> Docker installation failed, trying alternative method..."
    return 1
  }
  
  echo ">>> Docker installation complete!"
  echo ">>> Access management UI at: http://<server-ip>:15672"
  echo ">>> Login with: $RABBIT_USER / $RABBIT_PASS"
}

# Strategy 2: Snap installation
install_via_snap() {
  echo ">>> Installing RabbitMQ via Snap..."
  
  # Install Erlang snap first
  sudo snap install erlang --classic || {
    echo ">>> Erlang snap installation failed"
    return 1
  }
  
  # Install RabbitMQ snap
  sudo snap install rabbitmq-server || {
    echo ">>> RabbitMQ snap installation failed"
    return 1
  }
  
  # Enable management plugin
  sudo rabbitmq-plugins enable rabbitmq_management || true
  
  # Create user
  sudo rabbitmqctl add_user "$RABBIT_USER" "$RABBIT_PASS" || true
  sudo rabbitmqctl set_user_tags "$RABBIT_USER" administrator || true
  sudo rabbitmqctl set_permissions -p / "$RABBIT_USER" ".*" ".*" ".*" || true
  
  echo ">>> Snap installation complete!"
}

# Strategy 3: Direct package installation
install_via_packages() {
  echo ">>> Installing RabbitMQ via packages..."
  
  # Update system
  sudo apt update -y || true
  
  # Install RabbitMQ directly (Erlang 26+ already available)
  sudo apt install -y rabbitmq-server || {
    echo ">>> RabbitMQ package installation failed"
    return 1
  }
  
  # Configure and start
  sudo systemctl enable rabbitmq-server || true
  sudo systemctl start rabbitmq-server || true
  sudo rabbitmq-plugins enable rabbitmq_management || true
  
  # Create user
  sudo rabbitmqctl add_user "$RABBIT_USER" "$RABBIT_PASS" || true
  sudo rabbitmqctl set_user_tags "$RABBIT_USER" administrator || true
  sudo rabbitmqctl set_permissions -p / "$RABBIT_USER" ".*" ".*" ".*" || true
  
  echo ">>> Package installation complete!"
}

# Strategy 4: Smart repository management
install_via_smart_repos() {
  echo ">>> Installing RabbitMQ via smart repository management..."
  
  # Update system
  sudo apt update -y && sudo apt upgrade -y || true
  sudo apt install -y curl gnupg apt-transport-https lsb-release || true
  
  # Try multiple Erlang sources
  local erlang_installed=false
  
  # Source 1: Erlang Solutions (try multiple URLs)
  local erlang_urls="https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc http://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc"
  
  for url in $erlang_urls; do
    if check_connectivity "$url" 5; then
      echo ">>> Adding Erlang repository from: $url"
      if curl -fsSL "$url" | sudo gpg --dearmor -o /usr/share/keyrings/erlang.gpg; then
        echo "deb [signed-by=/usr/share/keyrings/erlang.gpg] https://packages.erlang-solutions.com/ubuntu $(get_ubuntu_version) contrib" | sudo tee /etc/apt/sources.list.d/erlang.list
        sudo apt update -y || true
        if sudo apt install -y esl-erlang; then
          erlang_installed=true
          break
        fi
      fi
    fi
  done
  
  # Source 2: Ubuntu backports (if available)
  if [ "$erlang_installed" = false ]; then
    echo ">>> Trying Ubuntu backports..."
    if sudo apt install -y -t $(get_ubuntu_version)-backports erlang; then
      erlang_installed=true
    fi
  fi
  
  # Source 3: Ubuntu main repositories
  if [ "$erlang_installed" = false ]; then
    echo ">>> Installing from Ubuntu main repositories..."
    if sudo apt install -y erlang-base erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key erlang-runtime-tools erlang-snmp erlang-ssl erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl; then
      erlang_installed=true
    fi
  fi
  
  if [ "$erlang_installed" = false ]; then
    echo ">>> Error: Could not install Erlang from any source"
    echo ">>> Trying alternative RabbitMQ installation methods..."
    return 1
  fi
  
  # Install RabbitMQ
  echo ">>> Adding RabbitMQ repository..."
  curl -fsSL https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/com.rabbitmq.gpg || true
  echo "deb [signed-by=/usr/share/keyrings/com.rabbitmq.gpg] https://packagecloud.io/rabbitmq/rabbitmq-server/ubuntu $(get_ubuntu_version) main" | sudo tee /etc/apt/sources.list.d/rabbitmq.list
  
  sudo apt update -y || true
  sudo apt install -y rabbitmq-server || {
    echo ">>> RabbitMQ installation failed"
    return 1
  }
  
  # Configure and start
  sudo systemctl enable rabbitmq-server || true
  sudo systemctl start rabbitmq-server || true
  sudo rabbitmq-plugins enable rabbitmq_management || true
  
  # Create user
  sudo rabbitmqctl add_user "$RABBIT_USER" "$RABBIT_PASS" || true
  sudo rabbitmqctl set_user_tags "$RABBIT_USER" administrator || true
  sudo rabbitmqctl set_permissions -p / "$RABBIT_USER" ".*" ".*" ".*" || true
  
  echo ">>> Smart repository installation complete!"
}

# Main installation logic
main() {
  echo ">>> Starting installation process..."
  
  # Determine best strategy
  determine_strategy
  local strategy=$?
  
  echo ">>> Selected strategy: $strategy"
  
  case $strategy in
    1)
      echo ">>> Executing Docker strategy..."
      install_via_docker || {
        echo ">>> Docker strategy failed, trying Snap..."
        install_via_snap || {
          echo ">>> Snap strategy failed, trying Smart repository..."
          install_via_smart_repos || {
            echo ">>> All strategies failed. Please check your system and try again."
            exit 1
          }
        }
      }
      ;;
    2)
      echo ">>> Executing Snap strategy..."
      install_via_snap || {
        echo ">>> Snap strategy failed, trying Smart repository..."
        install_via_smart_repos || {
          echo ">>> All strategies failed. Please check your system and try again."
          exit 1
        }
      }
      ;;
    3)
      echo ">>> Executing Direct package strategy..."
      install_via_packages || {
        echo ">>> Direct package strategy failed, trying Smart repository..."
        install_via_smart_repos || {
          echo ">>> All strategies failed. Please check your system and try again."
          exit 1
        }
      }
      ;;
    4)
      echo ">>> Executing Smart repository strategy..."
      install_via_smart_repos || {
        echo ">>> Smart repository strategy failed. Please check your system and try again."
        exit 1
      }
      ;;
    *)
      echo ">>> Error: Could not determine installation strategy (got: $strategy)"
      exit 1
      ;;
  esac
  
  # Configure firewall
  echo ">>> Configuring firewall..."
  sudo ufw allow 5672/tcp || true
  sudo ufw allow 15672/tcp || true
  
  echo ">>> RabbitMQ installation complete!"
  echo ">>> Access management UI at: http://<server-ip>:15672"
  echo ">>> Login with: $RABBIT_USER / $RABBIT_PASS"
}

# Run main function
main "$@"
