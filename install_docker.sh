#!/bin/bash

# BillionMail Docker Installation Script
# This script checks and sets up everything needed for Docker to run BillionMail

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root. This is not recommended for Docker."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Exiting. Please run as a regular user with sudo privileges."
            exit 1
        fi
    fi
}

# Check operating system
check_os() {
    log_info "Checking operating system..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$NAME
            VERSION=$VERSION_ID
        else
            log_error "Cannot determine Linux distribution"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
        VERSION=$(sw_vers -productVersion)
    else
        log_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    
    log_success "Detected OS: $OS $VERSION"
}

# Check if Docker is installed
check_docker() {
    log_info "Checking Docker installation..."
    
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        log_success "Docker is installed: $DOCKER_VERSION"
        
        # Check if Docker daemon is running
        if docker info &> /dev/null; then
            log_success "Docker daemon is running"
        else
            log_error "Docker daemon is not running"
            log_info "Please start Docker daemon and try again"
            exit 1
        fi
    else
        log_warning "Docker is not installed"
        install_docker
    fi
}

# Install Docker based on OS
install_docker() {
    log_info "Installing Docker..."
    
    if [[ "$OS" == "macOS" ]]; then
        log_info "For macOS, please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
        log_info "Or install via Homebrew: brew install --cask docker"
        exit 1
    elif [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        install_docker_ubuntu
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]] || [[ "$OS" == *"Fedora"* ]]; then
        install_docker_centos
    else
        log_error "Unsupported Linux distribution for automatic Docker installation"
        log_info "Please install Docker manually for $OS"
        exit 1
    fi
}

# Install Docker on Ubuntu/Debian
install_docker_ubuntu() {
    log_info "Installing Docker on Ubuntu/Debian..."
    
    # Update package index
    sudo apt-get update
    
    # Install prerequisites
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Set up stable repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    log_success "Docker installed successfully"
    log_warning "Please log out and log back in for group changes to take effect"
}

# Install Docker on CentOS/RHEL/Fedora
install_docker_centos() {
    log_info "Installing Docker on CentOS/RHEL/Fedora..."
    
    # Install prerequisites
    sudo yum install -y yum-utils
    
    # Add Docker repository
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    # Install Docker Engine
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    log_success "Docker installed successfully"
    log_warning "Please log out and log back in for group changes to take effect"
}

# Check Docker Compose
check_docker_compose() {
    log_info "Checking Docker Compose..."
    
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version --short)
        log_success "Docker Compose is available: $COMPOSE_VERSION"
    elif command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)
        log_success "Docker Compose is available: $COMPOSE_VERSION"
    else
        log_error "Docker Compose is not available"
        log_info "Docker Compose should be installed with Docker. Please reinstall Docker."
        exit 1
    fi
}

# Check system resources
check_resources() {
    log_info "Checking system resources..."
    
    # Check available memory
    if [[ "$OS" == "macOS" ]]; then
        TOTAL_MEM=$(sysctl -n hw.memsize)
        TOTAL_MEM_GB=$((TOTAL_MEM / 1024 / 1024 / 1024))
    else
        TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
        TOTAL_MEM_GB=$((TOTAL_MEM / 1024))
    fi
    
    if [ $TOTAL_MEM_GB -lt 4 ]; then
        log_warning "System has less than 4GB RAM. BillionMail may run slowly."
    else
        log_success "System has ${TOTAL_MEM_GB}GB RAM - sufficient for BillionMail"
    fi
    
    # Check available disk space
    if [[ "$OS" == "macOS" ]]; then
        AVAILABLE_SPACE=$(df -g . | awk 'NR==2 {print $4}')
    else
        AVAILABLE_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    fi
    
    if [ "$AVAILABLE_SPACE" -lt 10 ]; then
        log_warning "Less than 10GB disk space available. Consider freeing up space."
    else
        log_success "Available disk space: ${AVAILABLE_SPACE}GB"
    fi
}

# Check required ports
check_ports() {
    log_info "Checking required ports..."
    
    PORTS=(25 80 110 143 443 465 587 993 995 25432 26379)
    BUSY_PORTS=()
    
    for port in "${PORTS[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            BUSY_PORTS+=($port)
        fi
    done
    
    if [ ${#BUSY_PORTS[@]} -gt 0 ]; then
        log_warning "The following ports are already in use: ${BUSY_PORTS[*]}"
        log_info "You may need to stop services using these ports or modify the .env file"
    else
        log_success "All required ports are available"
    fi
}

# Check and create .env file
setup_env() {
    log_info "Setting up environment configuration..."
    
    if [ ! -f .env ]; then
        if [ -f env_init ]; then
            cp env_init .env
            log_success "Created .env file from env_init template"
        else
            log_error "No .env file or env_init template found"
            exit 1
        fi
    else
        log_success ".env file already exists"
    fi
    
    # Check if .env has required variables
    if ! grep -q "BILLIONMAIL_HOSTNAME" .env; then
        log_warning ".env file may be incomplete. Please check configuration."
    fi
}

# Check Docker images
check_images() {
    log_info "Checking Docker images..."
    
    # Check if images are available locally or can be pulled
    IMAGES=(
        "postgres:17.4-alpine"
        "redis:7.4.2-alpine"
        "roundcube/roundcubemail:1.6.10-fpm-alpine"
        "billionmail/core:4.2.1"
        "billionmail/postfix:1.6"
        "billionmail/dovecot:1.5"
        "billionmail/rspamd:1.2"
    )
    
    MISSING_IMAGES=()
    
    for image in "${IMAGES[@]}"; do
        if ! docker image inspect "$image" &> /dev/null; then
            MISSING_IMAGES+=("$image")
        fi
    done
    
    if [ ${#MISSING_IMAGES[@]} -gt 0 ]; then
        log_info "The following images will be downloaded on first run:"
        for image in "${MISSING_IMAGES[@]}"; do
            echo "  - $image"
        done
    else
        log_success "All required Docker images are available locally"
    fi
}

# Test Docker setup
test_docker() {
    log_info "Testing Docker setup..."
    
    # Test Docker daemon
    if docker run --rm hello-world &> /dev/null; then
        log_success "Docker daemon is working correctly"
    else
        log_error "Docker daemon test failed"
        exit 1
    fi
    
    # Test Docker Compose
    if docker compose version &> /dev/null; then
        log_success "Docker Compose is working correctly"
    elif docker-compose --version &> /dev/null; then
        log_success "Docker Compose is working correctly"
    else
        log_error "Docker Compose test failed"
        exit 1
    fi
}

# Main installation function
main() {
    echo "=========================================="
    echo "  BillionMail Docker Installation Script"
    echo "=========================================="
    echo
    
    check_root
    check_os
    check_docker
    check_docker_compose
    check_resources
    check_ports
    setup_env
    check_images
    test_docker
    
    echo
    echo "=========================================="
    log_success "Docker setup completed successfully!"
    echo "=========================================="
    echo
    echo "Next steps:"
    echo "1. Review and modify .env file if needed"
    echo "2. Run: make start (or docker-compose up -d)"
    echo "3. Access admin panel at: http://localhost/billion"
    echo "4. Default credentials: billion / billion"
    echo
    echo "Useful commands:"
    echo "  make help          - Show all available commands"
    echo "  make status        - Check service status"
    echo "  make logs          - View service logs"
    echo "  make stop          - Stop all services"
    echo
}

# Run main function
main "$@"
