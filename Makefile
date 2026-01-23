.PHONY: help dev build up down logs clean migrate seed test

help: ## Show this help
	@echo "Available commands:"
	@echo "  make dev      - Start all services in foreground"
	@echo "  make build    - Build all Docker images"
	@echo "  make up       - Start all services in background"
	@echo "  make down     - Stop all services"
	@echo "  make logs     - Show logs from all services"
	@echo "  make clean    - Stop services and remove volumes"
	@echo "  make migrate  - Run database migrations"
	@echo "  make seed     - Seed database with sample data"
	@echo "  make test     - Run backend tests"

dev: ## Start services in foreground
	docker-compose up

build: ## Build all images
	docker-compose build

up: ## Start services in background
	docker-compose up -d

down: ## Stop all services
	docker-compose down

logs: ## Follow logs
	docker-compose logs -f

clean: ## Clean everything
	docker-compose down -v
	docker system prune -f

migrate: ## Run migrations
	@echo "Running database migrations..."
	docker-compose exec postgres psql -U erp_admin -d erp_lab_saq -f /docker-entrypoint-initdb.d/001_init_schema.sql
	@echo "✓ Migrations completed"

seed: ## Seed database
	@echo "Seeding database..."
	@echo "✓ Database already seeded via migration"

test: ## Run tests
	cd backend && go test ./...

backend-shell: ## Open backend container shell
	docker-compose exec backend sh

db-shell: ## Open database shell
	docker-compose exec postgres psql -U erp_admin -d erp_lab_saq

restart: down up ## Restart all services