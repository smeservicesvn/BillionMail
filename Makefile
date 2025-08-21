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
	@echo ""
	@echo "Backend Commands:"
	@echo "  make go-build    - Build Go backend"
	@echo "  make go-test     - Run Go tests"
	@echo "  make go-lint     - Run Go linter"
	@echo ""
	@echo "Deployment Commands:"
	@echo "  make docker-build - Build all Docker images"
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

# Docker Service Commands
start: ## Start all services with docker-compose
	@echo "Starting all services..."
	docker-compose up -d
	@echo "Services started. Access admin panel at: http://localhost/billion"
	@echo "Frontend dev server: https://localhost:3000/"

stop: ## Stop all services
	@echo "Stopping all services..."
	docker-compose down

restart: ## Restart all services
	@echo "Restarting all services..."
	docker-compose restart

status: ## Show status of all services
	@echo "Service Status:"
	docker-compose ps

logs: ## Show logs from all services
	@echo "Showing logs from all services..."
	docker-compose logs -f

logs-core: ## Show core service logs
	@echo "Showing core service logs..."
	docker-compose logs -f core-billionmail

logs-mail: ## Show mail service logs
	@echo "Showing mail service logs..."
	docker-compose logs -f postfix-billionmail dovecot-billionmail rspamd-billionmail

logs-webmail: ## Show webmail service logs
	@echo "Showing webmail service logs..."
	docker-compose logs -f webmail-billionmail

logs-db: ## Show database logs
	@echo "Showing database logs..."
	docker-compose logs -f pgsql-billionmail redis-billionmail

clean: ## Stop services and remove containers/volumes
	@echo "Stopping services and cleaning up..."
	docker-compose down -v --remove-orphans
	@echo "Cleanup complete"

clean-all: ## Complete cleanup including images
	@echo "Complete cleanup including images..."
	docker-compose down -v --remove-orphans --rmi all
	@echo "Complete cleanup finished"

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

# Deployment Commands
deploy: ## Deploy to production
	@echo "Deploying to production..."
	git pull origin main
	docker-compose down
	docker-compose up -d --build
	@echo "Deployment complete"

# Utility Commands
backup: ## Backup database and configs
	@echo "Creating backup..."
	@mkdir -p backups/$(shell date +%Y%m%d_%H%M%S)
	@docker-compose exec pgsql-billionmail pg_dump -U billionmail billionmail > backups/$(shell date +%Y%m%d_%H%M%S)/database.sql
	@cp -r conf backups/$(shell date +%Y%m%d_%H%M%S)/
	@cp .env backups/$(shell date +%Y%m%d_%H%M%S)/
	@echo "Backup created in backups/$(shell date +%Y%m%d_%H%M%S)/"

restore: ## Restore from backup (usage: make restore BACKUP_DIR=backups/20240821_123456)
	@if [ -z "$(BACKUP_DIR)" ]; then echo "Usage: make restore BACKUP_DIR=backups/YYYYMMDD_HHMMSS"; exit 1; fi
	@echo "Restoring from backup: $(BACKUP_DIR)"
	@docker-compose exec pgsql-billionmail psql -U billionmail billionmail < $(BACKUP_DIR)/database.sql
	@cp -r $(BACKUP_DIR)/conf/* conf/
	@cp $(BACKUP_DIR)/.env .env
	@docker-compose restart
	@echo "Restore complete"

logs-clean: ## Clean old log files
	@echo "Cleaning old log files..."
	find logs/ -name "*.log" -mtime +7 -delete
	find logs/ -name "*.gz" -mtime +30 -delete
	@echo "Log cleanup complete"

ssl-renew: ## Renew SSL certificates
	@echo "Renewing SSL certificates..."
	docker-compose exec core-billionmail lego --email admin@localhost --domains localhost --http renew
	@docker-compose restart core-billionmail
	@echo "SSL renewal complete"

# Health Check Commands
health: ## Check health of all services
	@echo "Checking service health..."
	@echo "Core Service:"
	@curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost/billion || echo "Core service not responding"
	@echo "PostgreSQL:"
	@docker-compose exec pgsql-billionmail pg_isready -U billionmail || echo "PostgreSQL not ready"
	@echo "Redis:"
	@docker-compose exec redis-billionmail redis-cli ping || echo "Redis not responding"
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
