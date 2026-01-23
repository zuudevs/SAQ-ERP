.PHONY: help dev build up down logs clean migrate

help:
	@echo "Available commands:"
	@echo "  make dev      - Start development environment"
	@echo "  make build    - Build all containers"
	@echo "  make up       - Start all services"
	@echo "  make down     - Stop all services"
	@echo "  make logs     - Show logs"
	@echo "  make clean    - Remove all containers and volumes"
	@echo "  make migrate  - Run database migrations"

dev:
	docker-compose up

build:
	docker-compose build

up:
	docker-compose up -d

down:
	docker-compose down

logs:
	docker-compose logs -f

clean:
	docker-compose down -v
	docker system prune -f

migrate:
	docker-compose exec postgres psql -U erp_admin -d erp_lab_saq -f /docker-entrypoint-initdb.d/001_init_schema.sql