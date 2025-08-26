# BillionMail Email Platform Makefile
# Provides useful commands for development, deployment, and maintenance

.PHONY: help install dev build start stop restart logs status clean docker-build docker-push test lint format

# Default target
help: ## Show this help message
	@echo "BillionMail Email Platform - Available Commands:"
	@echo ""
	@echo "Development Commands:"
	@echo "  make install     - Install frontend dependencies"
	@echo "  make dev         - Start frontend development server"
	@echo "  make build       - Build frontend for production"
	@echo "  make lint        - Run ESLint on frontend code"
	@echo "  make format      - Format code with Prettier"
	@echo ""
	@echo "Docker Commands:"
	@echo "  make start       - Start all services with docker-compose"
	@echo "  make stop        - Stop all services"
	@echo "  make restart     - Restart all services"
	@echo "  make logs        - Show logs from all services"
	@echo "  make status      - Show status of all services"
	@echo "  make clean       - Stop services and remove containers/volumes"
	@echo "  make clean-networks - Clean up Docker networks (fix conflicts)"
	@echo ""
	@echo "Backend Commands:"
	@echo "  make go-build    - Build Go backend"
	@echo "  make go-test     - Run Go tests"
	@echo "  make go-lint     - Run Go linter"
	@echo ""
	@echo "Deployment Commands:"
	@echo "  make docker-build - Build all Docker images"
	@echo "  make docker-push  - Push images to registry"
	@echo "  make docker-clone-images - Clone billionmail images to your account"
	@echo "  make docker-push-cloned - Push cloned images to your Docker Hub"
	@echo "  make docker-update-compose - Update compose to use your images"
	@echo "  make docker-full-clone - Complete image cloning workflow"
	@echo "  make deploy      - Deploy to production"
	@echo ""
	@echo "Git Sync Commands:"
	@echo "  make sync-upstream      - Fetch latest from upstream BillionMail"
	@echo "  make rebase-upstream    - Rebase your commits on upstream"
	@echo "  make sync-and-rebase    - Sync and rebase in one command"
	@echo "  make show-upstream-status - Show sync status"
	@echo "  make full-sync          - Complete sync workflow"
	@echo ""
	@echo "Utility Commands:"
	@echo "  make backup      - Backup database and configs"
	@echo "  make restore     - Restore from backup"
	@echo "  make logs-clean  - Clean old log files"
	@echo "  make ssl-renew   - Renew SSL certificates"
	@echo "  make install-docker - Run Docker installation and setup script"
	@echo ""
	@echo "Docker Compose Version Management:"
	@echo "  make use-smeservicesvn - Switch to smeservicesvn images (default)"
	@echo "  make use-billionmail   - Switch to original billionmail images"
	@echo "  make show-compose-versions - Show available docker-compose versions"
	@echo ""
	@echo "Architecture & Troubleshooting:"
	@echo "  make check-arch  - Check system architecture and Docker platform"
	@echo "  make docker-check-images - Check current Docker images and architecture"
	@echo "  make fix-exec-format-error - Fix exec format error with correct architecture"
	@echo "  make docker-clone-images-fixed - Clone images with architecture detection"

# Frontend Development Commands
install: ## Install frontend dependencies
	@echo "Installing frontend dependencies..."
	cd core/frontend && pnpm install

dev: ## Start frontend development server
	@echo "Starting frontend development server..."
	cd core/frontend && pnpm dev

build: ## Build frontend for production
	@echo "Building frontend for production..."
	cd core/frontend && pnpm build

build-git: ## Build frontend for git deployment
	@echo "Building frontend for git deployment..."
	cd core/frontend && pnpm run build:git

lint: ## Run ESLint on frontend code
	@echo "Running ESLint..."
	cd core/frontend && pnpm lint

lint-fix: ## Fix ESLint issues automatically
	@echo "Fixing ESLint issues..."
	cd core/frontend && pnpm lint:fix

format: ## Format code with Prettier
	@echo "Formatting code with Prettier..."
	cd core/frontend && pnpm format

# Docker Compose command detection
DOCKER_COMPOSE_CMD := $(shell if docker compose version >/dev/null 2>&1; then echo "docker compose"; elif docker-compose --version >/dev/null 2>&1; then echo "docker-compose"; else echo ""; fi)

# Docker Service Commands
start: ## Start all services with docker-compose
	@if [ -z "$(DOCKER_COMPOSE_CMD)" ]; then \
		echo "Error: Neither 'docker compose' nor 'docker-compose' is available."; \
		echo "Please install Docker Compose or run: make install-docker"; \
		exit 1; \
	fi
	@echo "Starting all services using $(DOCKER_COMPOSE_CMD)..."
	$(DOCKER_COMPOSE_CMD) up -d
	@echo "Services started. Access admin panel at: http://localhost/billion"
	@echo "Frontend dev server: https://localhost:3000/"

stop: ## Stop all services
	@if [ -z "$(DOCKER_COMPOSE_CMD)" ]; then \
		echo "Error: Neither 'docker compose' nor 'docker-compose' is available."; \
		exit 1; \
	fi
	@echo "Stopping all services..."
	$(DOCKER_COMPOSE_CMD) down

restart: ## Restart all services
	@if [ -z "$(DOCKER_COMPOSE_CMD)" ]; then \
		echo "Error: Neither 'docker compose' nor 'docker-compose' is available."; \
		exit 1; \
	fi
	@echo "Restarting all services..."
	$(DOCKER_COMPOSE_CMD) restart

status: ## Show status of all services
	@if [ -z "$(DOCKER_COMPOSE_CMD)" ]; then \
		echo "Error: Neither 'docker compose' nor 'docker-compose' is available."; \
		exit 1; \
	fi
	@echo "Service Status:"
	$(DOCKER_COMPOSE_CMD) ps

logs: ## Show logs from all services
	@if [ -z "$(DOCKER_COMPOSE_CMD)" ]; then \
		echo "Error: Neither 'docker compose' nor 'docker-compose' is available."; \
		exit 1; \
	fi
	@echo "Showing logs from all services..."
	$(DOCKER_COMPOSE_CMD) logs -f

logs-core: ## Show core service logs
	@if [ -z "$(DOCKER_COMPOSE_CMD)" ]; then \
		echo "Error: Neither 'docker compose' nor 'docker-compose' is available."; \
		exit 1; \
	fi
	@echo "Showing core service logs..."
	$(DOCKER_COMPOSE_CMD) logs -f core-billionmail

logs-mail: ## Show mail service logs
	@if [ -z "$(DOCKER_COMPOSE_CMD)" ]; then \
		echo "Error: Neither 'docker compose' nor 'docker-compose' is available."; \
		exit 1; \
	fi
	@echo "Showing mail service logs..."
	$(DOCKER_COMPOSE_CMD) logs -f postfix-billionmail dovecot-billionmail rspamd-billionmail

logs-webmail: ## Show webmail service logs
	@if [ -z "$(DOCKER_COMPOSE_CMD)" ]; then \
		echo "Error: Neither 'docker compose' nor 'docker-compose' is available."; \
		exit 1; \
	fi
	@echo "Showing webmail service logs..."
	$(DOCKER_COMPOSE_CMD) logs -f webmail-billionmail

logs-db: ## Show database logs
	@if [ -z "$(DOCKER_COMPOSE_CMD)" ]; then \
		echo "Error: Neither 'docker compose' nor 'docker-compose' is available."; \
		exit 1; \
	fi
	@echo "Showing database logs..."
	$(DOCKER_COMPOSE_CMD) logs -f pgsql-billionmail redis-billionmail

clean: ## Stop services and remove containers/volumes
	@if [ -z "$(DOCKER_COMPOSE_CMD)" ]; then \
		echo "Error: Neither 'docker compose' nor 'docker-compose' is available."; \
		exit 1; \
	fi
	@echo "Stopping services and cleaning up..."
	$(DOCKER_COMPOSE_CMD) down -v --remove-orphans
	@echo "Cleanup complete"

clean-all: ## Complete cleanup including images
	@if [ -z "$(DOCKER_COMPOSE_CMD)" ]; then \
		echo "Error: Neither 'docker compose' nor 'docker-compose' is available."; \
		exit 1; \
	fi
	@echo "Complete cleanup including images..."
	$(DOCKER_COMPOSE_CMD) down -v --remove-orphans --rmi all
	@echo "Complete cleanup finished"

clean-networks: ## Clean up Docker networks (fix network conflicts)
	@echo "Cleaning up Docker networks..."
	@echo "Removing billionmail networks..."
	@docker network ls --filter name=billionmail --format "{{.Name}}" | xargs -r docker network rm 2>/dev/null || true
	@echo "Network cleanup complete"

# Backend Commands
go-build: ## Build Go backend
	@echo "Building Go backend..."
	cd core && go build -o billionmail ./cmd/main.go

go-test: ## Run Go tests
	@echo "Running Go tests..."
	cd core && go test ./...

go-lint: ## Run Go linter
	@echo "Running Go linter..."
	cd core && golangci-lint run

go-mod: ## Tidy and verify Go modules
	@echo "Tidying Go modules..."
	cd core && go mod tidy && go mod verify

# Docker Image Commands
docker-build: ## Build all Docker images
	@echo "Building Docker images..."
	docker build -t billionmail/core:latest -f Dockerfiles/core/Dockerfile .
	docker build -t billionmail/postfix:latest -f Dockerfiles/postfix/Dockerfile .
	docker build -t billionmail/dovecot:latest -f Dockerfiles/dovecot/Dockerfile .
	docker build -t billionmail/rspamd:latest -f Dockerfiles/rspamd/Dockerfile .
	@echo "All images built successfully"

docker-push: ## Push Docker images to registry
	@echo "Pushing Docker images..."
	docker push billionmail/core:latest
	docker push billionmail/postfix:latest
	docker push billionmail/dovecot:latest
	docker push billionmail/rspamd:latest

# Docker Image Cloning and Management
docker-clone-images: ## Clone billionmail images to your account (set DOCKER_USERNAME)
	@if [ -z "$(DOCKER_USERNAME)" ]; then echo "Usage: make docker-clone-images DOCKER_USERNAME=yourusername"; exit 1; fi
	@echo "Cloning billionmail images to $(DOCKER_USERNAME) account..."
	docker tag billionmail/core:4.3.2 $(DOCKER_USERNAME)/billionmail-core:4.3.2
	docker tag billionmail/core:4.3.2 $(DOCKER_USERNAME)/billionmail-core:latest
	docker tag billionmail/rspamd:1.2 $(DOCKER_USERNAME)/billionmail-rspamd:1.2
	docker tag billionmail/rspamd:1.2 $(DOCKER_USERNAME)/billionmail-rspamd:latest
	docker tag billionmail/dovecot:1.5 $(DOCKER_USERNAME)/billionmail-dovecot:1.5
	docker tag billionmail/dovecot:1.5 $(DOCKER_USERNAME)/billionmail-dovecot:latest
	docker tag billionmail/postfix:1.6 $(DOCKER_USERNAME)/billionmail-postfix:1.6
	docker tag billionmail/postfix:1.6 $(DOCKER_USERNAME)/billionmail-postfix:latest
	@echo "Images tagged successfully. Use 'make docker-push-cloned DOCKER_USERNAME=$(DOCKER_USERNAME)' to push them."

docker-push-cloned: ## Push cloned images to your Docker Hub account
	@if [ -z "$(DOCKER_USERNAME)" ]; then echo "Usage: make docker-push-cloned DOCKER_USERNAME=yourusername"; exit 1; fi
	@echo "Pushing cloned images to $(DOCKER_USERNAME) account..."
	docker push $(DOCKER_USERNAME)/billionmail-core:4.3.2
	docker push $(DOCKER_USERNAME)/billionmail-core:latest
	docker push $(DOCKER_USERNAME)/billionmail-rspamd:1.2
	docker push $(DOCKER_USERNAME)/billionmail-rspamd:latest
	docker push $(DOCKER_USERNAME)/billionmail-dovecot:1.5
	docker push $(DOCKER_USERNAME)/billionmail-dovecot:latest
	docker push $(DOCKER_USERNAME)/billionmail-postfix:1.6
	docker push $(DOCKER_USERNAME)/billionmail-postfix:latest
	@echo "All images pushed to $(DOCKER_USERNAME) account successfully!"

docker-update-compose: ## Update docker-compose.yml to use your cloned images
	@if [ -z "$(DOCKER_USERNAME)" ]; then echo "Usage: make docker-update-compose DOCKER_USERNAME=yourusername"; exit 1; fi
	@echo "Updating docker-compose.yml to use $(DOCKER_USERNAME) images..."
	@sed -i.bak 's|billionmail/|$(DOCKER_USERNAME)/billionmail-|g' docker-compose.yml
	@echo "docker-compose.yml updated. Backup saved as docker-compose.yml.bak"
	@echo "You can now use 'make start' with your own images!"

docker-restore-compose: ## Restore original docker-compose.yml
	@echo "Restoring original docker-compose.yml..."
	@if [ -f docker-compose.yml.bak ]; then \
		cp docker-compose.yml.bak docker-compose.yml; \
		echo "Original docker-compose.yml restored"; \
	else \
		echo "No backup found. Original file not modified."; \
	fi

docker-full-clone: ## Complete workflow: clone, push, and update compose
	@if [ -z "$(DOCKER_USERNAME)" ]; then echo "Usage: make docker-full-clone DOCKER_USERNAME=yourusername"; exit 1; fi
	@echo "Starting complete Docker image cloning workflow..."
	@make docker-clone-images DOCKER_USERNAME=$(DOCKER_USERNAME)
	@make docker-push-cloned DOCKER_USERNAME=$(DOCKER_USERNAME)
	@make docker-update-compose DOCKER_USERNAME=$(DOCKER_USERNAME)
	@echo "Complete workflow finished! Your fork now uses your own Docker images."

# Deployment Commands
deploy: ## Deploy to production
	@if [ -z "$(DOCKER_COMPOSE_CMD)" ]; then \
		echo "Error: Neither 'docker compose' nor 'docker-compose' is available."; \
		exit 1; \
	fi
	@echo "Deploying to production..."
	git pull origin main
	$(DOCKER_COMPOSE_CMD) down
	$(DOCKER_COMPOSE_CMD) up -d --build
	@echo "Deployment complete"

# Utility Commands
backup: ## Backup database and configs
	@if [ -z "$(DOCKER_COMPOSE_CMD)" ]; then \
		echo "Error: Neither 'docker compose' nor 'docker-compose' is available."; \
		exit 1; \
	fi
	@echo "Creating backup..."
	@mkdir -p backups/$(shell date +%Y%m%d_%H%M%S)
	@$(DOCKER_COMPOSE_CMD) exec pgsql-billionmail pg_dump -U billionmail billionmail > backups/$(shell date +%Y%m%d_%H%M%S)/database.sql
	@cp -r conf backups/$(shell date +%Y%m%d_%H%M%S)/
	@cp .env backups/$(shell date +%Y%m%d_%H%M%S)/
	@echo "Backup created in backups/$(shell date +%Y%m%d_%H%M%S)/"

restore: ## Restore from backup (usage: make restore BACKUP_DIR=backups/20240821_123456)
	@if [ -z "$(DOCKER_COMPOSE_CMD)" ]; then \
		echo "Error: Neither 'docker compose' nor 'docker-compose' is available."; \
		exit 1; \
	fi
	@if [ -z "$(BACKUP_DIR)" ]; then echo "Usage: make restore BACKUP_DIR=backups/YYYYMMDD_HHMMSS"; exit 1; fi
	@echo "Restoring from backup: $(BACKUP_DIR)"
	@$(DOCKER_COMPOSE_CMD) exec pgsql-billionmail psql -U billionmail billionmail < $(BACKUP_DIR)/database.sql
	@cp -r $(BACKUP_DIR)/conf/* conf/
	@cp $(BACKUP_DIR)/.env .env
	@$(DOCKER_COMPOSE_CMD) restart
	@echo "Restore complete"

logs-clean: ## Clean old log files
	@echo "Cleaning old log files..."
	find logs/ -name "*.log" -mtime +7 -delete
	find logs/ -name "*.gz" -mtime +30 -delete
	@echo "Log cleanup complete"

ssl-renew: ## Renew SSL certificates
	@if [ -z "$(DOCKER_COMPOSE_CMD)" ]; then \
		echo "Error: Neither 'docker compose' nor 'docker-compose' is available."; \
		exit 1; \
	fi
	@echo "Renewing SSL certificates..."
	$(DOCKER_COMPOSE_CMD) exec core-billionmail lego --email admin@localhost --domains localhost --http renew
	@$(DOCKER_COMPOSE_CMD) restart core-billionmail
	@echo "SSL renewal complete"

# Health Check Commands
health: ## Check health of all services
	@if [ -z "$(DOCKER_COMPOSE_CMD)" ]; then \
		echo "Error: Neither 'docker compose' nor 'docker-compose' is available."; \
		exit 1; \
	fi
	@echo "Checking service health..."
	@echo "Core Service:"
	@curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost/billion || echo "Core service not responding"
	@echo "PostgreSQL:"
	@$(DOCKER_COMPOSE_CMD) exec pgsql-billionmail pg_isready -U billionmail || echo "PostgreSQL not ready"
	@echo "Redis:"
	@$(DOCKER_COMPOSE_CMD) exec redis-billionmail redis-cli ping || echo "Redis not responding"
	@echo "Mail Services:"
	@echo "  SMTP (25): $(shell nc -z localhost 25 && echo "OK" || echo "FAIL")"
	@echo "  IMAP (143): $(shell nc -z localhost 143 && echo "OK" || echo "FAIL")"
	@echo "  POP3 (110): $(shell nc -z localhost 110 && echo "OK" || echo "FAIL")"

# Development Environment Setup
setup-dev: ## Setup development environment
	@echo "Setting up development environment..."
	@make install
	@make start
	@echo "Development environment ready!"
	@echo "Frontend dev server: https://localhost:3000/"
	@echo "Admin panel: http://localhost/billion"
	@echo "Username: billion, Password: billion"

install-docker: ## Run Docker installation and setup script
	@echo "Running Docker installation and setup script..."
	@./install_docker.sh

# Quick Commands
up: start ## Alias for start
down: stop ## Alias for stop
ps: status ## Alias for status
build-prod: build ## Alias for build
dev-server: dev ## Alias for dev

# Show environment info
env-info: ## Show environment configuration
	@echo "Environment Configuration:"
	@echo "Hostname: $(shell grep BILLIONMAIL_HOSTNAME .env | cut -d'=' -f2)"
	@echo "Database: $(shell grep DBNAME .env | cut -d'=' -f2)"
	@echo "HTTP Port: $(shell grep HTTP_PORT .env | cut -d'=' -f2)"
	@echo "HTTPS Port: $(shell grep HTTPS_PORT .env | cut -d'=' -f2)"
	@echo "SMTP Ports: $(shell grep SMTP_PORT .env | cut -d'=' -f2), $(shell grep SMTPS_PORT .env | cut -d'=' -f2), $(shell grep SUBMISSION_PORT .env | cut -d'=' -f2)"
	@echo "IMAP Ports: $(shell grep IMAP_PORT .env | cut -d'=' -f2), $(shell grep IMAPS_PORT .env | cut -d'=' -f2)"

# Git Sync Commands
sync-upstream: ## Fetch latest changes from upstream BillionMail repository
	@echo "Fetching latest changes from upstream BillionMail repository..."
	git fetch upstream
	@echo "Upstream changes fetched. Use 'make rebase-upstream' to apply them."

rebase-upstream: ## Rebase your commits on top of upstream changes
	@echo "Rebasing your commits on top of upstream changes..."
	@echo "This will replay your local commits on top of the latest upstream code."
	git rebase upstream/dev
	@echo "Rebase complete! Your commits are now on top of upstream changes."

sync-and-rebase: ## Sync with upstream and rebase in one command
	@echo "Syncing with upstream and rebasing..."
	@make sync-upstream
	@make rebase-upstream

show-upstream-status: ## Show status compared to upstream repository
	@echo "Upstream Repository Status:"
	@echo "Upstream remote: $(shell git remote get-url upstream)"
	@echo "Your branch: $(shell git branch --show-current)"
	@echo "Commits ahead of upstream: $(shell git rev-list --count upstream/dev..HEAD)"
	@echo "Commits behind upstream: $(shell git rev-list --count HEAD..upstream/dev)"
	@echo ""
	@echo "Recent upstream commits:"
	@git log --oneline upstream/dev -5

push-to-origin: ## Push your rebased commits to your fork
	@echo "Pushing rebased commits to your fork..."
	git push origin dev --force-with-lease
	@echo "Pushed to origin successfully!"

full-sync: ## Complete sync workflow: fetch, rebase, and push
	@echo "Starting complete sync workflow..."
	@make sync-upstream
	@make rebase-upstream
	@make push-to-origin
	@echo "Full sync workflow completed!"

# Docker Compose Version Management
use-smeservicesvn: ## Switch to smeservicesvn images (default)
	@echo "Switching to smeservicesvn images..."
	@cp docker-compose.yml docker-compose-current.yml
	@echo "Now using smeservicesvn images (docker-compose.yml)"

use-billionmail: ## Switch to original billionmail images
	@echo "Switching to billionmail images..."
	@cp docker-compose-billionmail.yml docker-compose.yml
	@echo "Now using billionmail images (docker-compose.yml)"

show-compose-versions: ## Show available docker-compose versions
	@echo "Available Docker Compose versions:"
	@echo "=================================="
	@echo "1. smeservicesvn images (default):"
	@echo "   - smeservicesvn/billionmail-core:4.3.2"
	@echo "   - smeservicesvn/billionmail-rspamd:1.2"
	@echo "   - smeservicesvn/billionmail-dovecot:1.5"
	@echo "   - smeservicesvn/billionmail-postfix:1.6"
	@echo ""
	@echo "2. billionmail images (original):"
	@echo "   - billionmail/core:4.3.2"
	@echo "   - billionmail/rspamd:1.2"
	@echo "   - billionmail/dovecot:1.5"
	@echo "   - billionmail/postfix:1.6"
	@echo ""
	@echo "Current active version:"
	@if grep -q "image: smeservicesvn/" docker-compose.yml; then \
		echo "  ✓ smeservicesvn images (docker-compose.yml)"; \
	elif grep -q "image: billionmail/" docker-compose.yml; then \
		echo "  ✓ billionmail images (docker-compose.yml)"; \
	else \
		echo "  ? Unknown images (docker-compose.yml)"; \
	fi

# Architecture and Troubleshooting Commands
check-arch: ## Check system architecture and Docker platform
	@echo "System Architecture Information:"
	@echo "=========================="
	@echo "OS: $$(uname -s)"
	@echo "Machine: $$(uname -m)"
	@echo "Platform: $$(uname -p 2>/dev/null || echo 'unknown')"
	@echo ""
	@echo "Docker Platform Information:"
	@echo "=========================="
	@docker version --format 'Client Version: {{.Client.Version}}'
	@docker version --format 'Server Version: {{.Server.Version}}'
	@docker info --format 'Architecture: {{.Architecture}}'
	@docker info --format 'OS/Type: {{.OperatingSystem}}/{{.OSType}}'
	@echo ""
	@echo "Available Docker Platforms:"
	@docker buildx ls

docker-check-images: ## Check current Docker images and their architecture
	@echo "Current Docker Images and Architecture:"
	@echo "===================================="
	@for img in $$($(DOCKER_COMPOSE_CMD) config | grep 'image:' | awk '{print $$2}' | sort -u); do \
		echo "Image: $$img"; \
		docker image inspect $$img --format 'Architecture: {{.Architecture}} | OS: {{.Os}}' 2>/dev/null || echo "  Status: Not found locally"; \
		echo ""; \
	done

docker-pull-platform: ## Pull images for specific platform (use PLATFORM=linux/amd64 or linux/arm64)
	@if [ -z "$(PLATFORM)" ]; then echo "Usage: make docker-pull-platform PLATFORM=linux/amd64"; exit 1; fi
	@echo "Pulling images for platform: $(PLATFORM)"
	@echo "Pulling billionmail/core:4.3.2..."
	docker pull --platform $(PLATFORM) billionmail/core:4.3.2
	@echo "Pulling billionmail/rspamd:1.2..."
	docker pull --platform $(PLATFORM) billionmail/rspamd:1.2
	@echo "Pulling billionmail/dovecot:1.5..."
	docker pull --platform $(PLATFORM) billionmail/dovecot:1.5
	@echo "Pulling billionmail/postfix:1.6..."
	docker pull --platform $(PLATFORM) billionmail/postfix:1.6
	@echo "All platform-specific images pulled successfully!"

docker-clone-images-fixed: ## Clone images with proper architecture detection (set DOCKER_USERNAME)
	@if [ -z "$(DOCKER_USERNAME)" ]; then echo "Usage: make docker-clone-images-fixed DOCKER_USERNAME=yourusername"; exit 1; fi
	@echo "Detecting system architecture..."
	@ARCH=$$(uname -m); \
	if [ "$$ARCH" = "x86_64" ]; then \
		PLATFORM="linux/amd64"; \
	elif [ "$$ARCH" = "aarch64" ] || [ "$$ARCH" = "arm64" ]; then \
		PLATFORM="linux/arm64"; \
	else \
		echo "Unsupported architecture: $$ARCH"; \
		exit 1; \
	fi; \
	echo "System architecture: $$ARCH"; \
	echo "Docker platform: $$PLATFORM"; \
	echo ""; \
	echo "Pulling images for your architecture..."; \
	docker pull --platform $$PLATFORM billionmail/core:4.3.2; \
	docker pull --platform $$PLATFORM billionmail/rspamd:1.2; \
	docker pull --platform $$PLATFORM billionmail/dovecot:1.5; \
	docker pull --platform $$PLATFORM billionmail/postfix:1.6; \
	echo ""; \
	echo "Tagging images for $(DOCKER_USERNAME) account..."; \
	docker tag billionmail/core:4.3.2 $(DOCKER_USERNAME)/billionmail-core:4.3.2; \
	docker tag billionmail/core:4.3.2 $(DOCKER_USERNAME)/billionmail-core:latest; \
	docker tag billionmail/rspamd:1.2 $(DOCKER_USERNAME)/billionmail-rspamd:1.2; \
	docker tag billionmail/rspamd:1.2 $(DOCKER_USERNAME)/billionmail-rspamd:latest; \
	docker tag billionmail/dovecot:1.5 $(DOCKER_USERNAME)/billionmail-dovecot:1.5; \
	docker tag billionmail/dovecot:1.5 $(DOCKER_USERNAME)/billionmail-dovecot:latest; \
	docker tag billionmail/postfix:1.6 $(DOCKER_USERNAME)/billionmail-postfix:1.6; \
	docker tag billionmail/postfix:1.6 $(DOCKER_USERNAME)/billionmail-postfix:latest; \
	echo "Images tagged successfully for $(DOCKER_USERNAME)!"

fix-exec-format-error: ## Fix exec format error by pulling correct architecture images
	@echo "Fixing exec format error by detecting and pulling correct architecture images..."
	@ARCH=$$(uname -m); \
	if [ "$$ARCH" = "x86_64" ]; then \
		PLATFORM="linux/amd64"; \
	elif [ "$$ARCH" = "aarch64" ] || [ "$$ARCH" = "arm64" ]; then \
		PLATFORM="linux/arm64"; \
	else \
		echo "Unsupported architecture: $$ARCH"; \
		exit 1; \
	fi; \
	echo "Detected architecture: $$ARCH (platform: $$PLATFORM)"; \
	echo "Stopping services..."; \
	make stop; \
	echo "Pulling correct architecture images..."; \
	make docker-pull-platform PLATFORM=$$PLATFORM; \
	echo "Starting services with correct images..."; \
	make start; \
	echo "Fix completed! Services should now start without exec format errors."
