
.PHONY: help up down build logs restart shell ps clean clean-all clean-volumes health status
.PHONY: dev-up dev-down dev-build dev-logs dev-restart dev-shell dev-ps backend-shell gateway-shell mongo-shell
.PHONY: prod-up prod-down prod-build prod-logs prod-restart
.PHONY: backend-build backend-install backend-type-check backend-dev
.PHONY: db-reset db-backup

# Default mode and service
MODE ?= dev
SERVICE ?= backend
COMPOSE_FILE_DEV = docker/compose.development.yaml
COMPOSE_FILE_PROD = docker/compose.production.yaml
COMPOSE_FILE = $(if $(filter prod,$(MODE)),$(COMPOSE_FILE_PROD),$(COMPOSE_FILE_DEV))
PROJECT_NAME = $(if $(filter prod,$(MODE)),hackathon_prod,hackathon_dev)

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Help target
help:
	@echo "$(GREEN)Docker Hackathon Makefile$(NC)"
	@echo ""
	@echo "$(YELLOW)Docker Services:$(NC)"
	@echo "  up              - Start services (make up [service...] or make up MODE=prod ARGS='--build')"
	@echo "  down            - Stop services (make down [service...] or make down MODE=prod ARGS='--volumes')"
	@echo "  build           - Build containers (make build [service...] or make build MODE=prod)"
	@echo "  logs            - View logs (make logs SERVICE=backend MODE=prod)"
	@echo "  restart         - Restart services (make restart [service...] or make restart MODE=prod)"
	@echo "  shell           - Open shell in container (make shell SERVICE=gateway MODE=prod)"
	@echo "  ps              - Show running containers (make ps MODE=prod)"
	@echo ""
	@echo "$(YELLOW)Development Aliases:$(NC)"
	@echo "  dev-up          - Start development environment"
	@echo "  dev-down        - Stop development environment"
	@echo "  dev-build       - Build development containers"
	@echo "  dev-logs        - View development logs"
	@echo "  dev-restart     - Restart development services"
	@echo "  dev-shell       - Open shell in backend container (dev)"
	@echo "  dev-ps          - Show running development containers"
	@echo "  backend-shell   - Open shell in backend container"
	@echo "  gateway-shell   - Open shell in gateway container"
	@echo "  mongo-shell     - Open MongoDB shell"
	@echo ""
	@echo "$(YELLOW)Production Aliases:$(NC)"
	@echo "  prod-up         - Start production environment"
	@echo "  prod-down       - Stop production environment"
	@echo "  prod-build      - Build production containers"
	@echo "  prod-logs       - View production logs"
	@echo "  prod-restart    - Restart production services"
	@echo ""
	@echo "$(YELLOW)Backend:$(NC)"
	@echo "  backend-build      - Build backend TypeScript"
	@echo "  backend-install    - Install backend dependencies"
	@echo "  backend-type-check - Type check backend code"
	@echo "  backend-dev        - Run backend in development mode (local)"
	@echo ""
	@echo "$(YELLOW)Database:$(NC)"
	@echo "  db-reset        - Reset MongoDB database (WARNING: deletes all data)"
	@echo "  db-backup       - Backup MongoDB database"
	@echo ""
	@echo "$(YELLOW)Cleanup:$(NC)"
	@echo "  clean           - Remove containers and networks"
	@echo "  clean-all       - Remove containers, networks, volumes, and images"
	@echo "  clean-volumes   - Remove all volumes"
	@echo ""
	@echo "$(YELLOW)Utilities:$(NC)"
	@echo "  status          - Alias for ps"
	@echo "  health          - Check service health"

# Core Docker Compose commands with dynamic service support
up:
	@echo "$(GREEN)Starting services in $(MODE) mode...$(NC)"
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) up -d $(ARGS) $(filter-out $@,$(MAKECMDGOALS))

down:
	@echo "$(YELLOW)Stopping services in $(MODE) mode...$(NC)"
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) down $(ARGS) $(filter-out $@,$(MAKECMDGOALS))

build:
	@echo "$(GREEN)Building containers in $(MODE) mode...$(NC)"
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) build $(ARGS) $(filter-out $@,$(MAKECMDGOALS))

logs:
	@echo "$(GREEN)Showing logs for $(SERVICE) in $(MODE) mode...$(NC)"
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) logs -f $(SERVICE)

restart:
	@echo "$(YELLOW)Restarting services in $(MODE) mode...$(NC)"
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) restart $(filter-out $@,$(MAKECMDGOALS))

shell:
	@echo "$(GREEN)Opening shell in $(SERVICE) container ($(MODE) mode)...$(NC)"
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) exec $(SERVICE) sh

ps:
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) ps

status: ps

# Development convenience aliases
dev-up:
	@$(MAKE) up MODE=dev ARGS="--build"

dev-down:
	@$(MAKE) down MODE=dev

dev-build:
	@$(MAKE) build MODE=dev

dev-logs:
	@$(MAKE) logs MODE=dev

dev-restart:
	@$(MAKE) restart MODE=dev

dev-shell:
	@$(MAKE) shell MODE=dev SERVICE=backend

dev-ps:
	@$(MAKE) ps MODE=dev

backend-shell:
	@$(MAKE) shell SERVICE=backend

gateway-shell:
	@$(MAKE) shell SERVICE=gateway

mongo-shell:
	@echo "$(GREEN)Opening MongoDB shell...$(NC)"
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) exec mongodb mongosh -u $$MONGO_INITDB_ROOT_USERNAME -p $$MONGO_INITDB_ROOT_PASSWORD

# Production convenience aliases
prod-up:
	@$(MAKE) up MODE=prod ARGS="--build"

prod-down:
	@$(MAKE) down MODE=prod

prod-build:
	@$(MAKE) build MODE=prod

prod-logs:
	@$(MAKE) logs MODE=prod

prod-restart:
	@$(MAKE) restart MODE=prod

# Backend local development
backend-build:
	@echo "$(GREEN)Building backend TypeScript...$(NC)"
	@cd backend && npm run build

backend-install:
	@echo "$(GREEN)Installing backend dependencies...$(NC)"
	@cd backend && npm install

backend-type-check:
	@echo "$(GREEN)Type checking backend code...$(NC)"
	@cd backend && npm run type-check || echo "$(YELLOW)Note: type-check script not found$(NC)"

backend-dev:
	@echo "$(GREEN)Running backend in development mode (local)...$(NC)"
	@cd backend && npm run dev

# Database operations
db-reset:
	@echo "$(RED)WARNING: This will delete all data!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "$(YELLOW)Resetting database...$(NC)"; \
		docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) exec mongodb mongosh -u $$MONGO_INITDB_ROOT_USERNAME -p $$MONGO_INITDB_ROOT_PASSWORD --eval "db.getSiblingDB('$$MONGO_DATABASE').dropDatabase()"; \
		echo "$(GREEN)Database reset complete$(NC)"; \
	fi

db-backup:
	@echo "$(GREEN)Backing up MongoDB database...$(NC)"
	@mkdir -p backups
	@BACKUP_FILE="backups/mongodb-backup-$$(date +%Y%m%d-%H%M%S).archive"; \
	docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) exec -T mongodb mongodump \
		--uri="$$MONGO_URI/$$MONGO_DATABASE" \
		--gzip --archive > $$BACKUP_FILE && \
	echo "$(GREEN)Backup created: $$BACKUP_FILE$(NC)"

# Cleanup commands
clean:
	@echo "$(YELLOW)Removing containers and networks...$(NC)"
	@docker compose -f $(COMPOSE_FILE_DEV) -p hackathon_dev down 2>/dev/null || true
	@docker compose -f $(COMPOSE_FILE_PROD) -p hackathon_prod down 2>/dev/null || true
	@echo "$(GREEN)Cleanup complete$(NC)"

clean-all:
	@echo "$(RED)Removing containers, networks, volumes, and images...$(NC)"
	@docker compose -f $(COMPOSE_FILE_DEV) -p hackathon_dev down -v --rmi all 2>/dev/null || true
	@docker compose -f $(COMPOSE_FILE_PROD) -p hackathon_prod down -v --rmi all 2>/dev/null || true
	@echo "$(GREEN)Full cleanup complete$(NC)"

clean-volumes:
	@echo "$(RED)Removing all volumes...$(NC)"
	@docker compose -f $(COMPOSE_FILE_DEV) -p hackathon_dev down -v 2>/dev/null || true
	@docker compose -f $(COMPOSE_FILE_PROD) -p hackathon_prod down -v 2>/dev/null || true
	@echo "$(GREEN)Volumes removed$(NC)"

# Health check
health:
	@echo "$(GREEN)Checking service health...$(NC)"
	@echo ""
	@echo "$(YELLOW)Gateway Health:$(NC)"
	@curl -sf http://localhost:5921/health | python3 -m json.tool 2>/dev/null || echo "$(RED)Gateway not responding$(NC)"
	@echo ""
	@echo "$(YELLOW)Backend Health (via Gateway):$(NC)"
	@curl -sf http://localhost:5921/api/health | python3 -m json.tool 2>/dev/null || echo "$(RED)Backend not responding$(NC)"
	@echo ""
	@echo "$(YELLOW)Docker Container Status:$(NC)"
	@docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) ps

# Catch-all for dynamic service targets
%:
	@:




