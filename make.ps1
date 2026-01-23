param(
    [string]$target = "help"
)

switch ($target) {
    "dev" { 
		docker-compose up 
	}
    "build" { 
		docker-compose build 
	}
    "up" { 
		docker-compose up -d 
	}
    "down" { 
		docker-compose down 
	}
    "logs" { 
		docker-compose logs -f 
	}
	"restart" { 
		down up 
	}
    "clean"   { 
		docker-compose down -v; 
		docker system prune -f 
	}
    "migrate" { 
		Write-Output "Running database migrations...";
		docker-compose exec postgres psql -U erp_admin -d erp_lab_saq -f /docker-entrypoint-initdb.d/001_init_schema.sql;
		Write-Output "✓ Migrations completed"
	}
	"seed"    { 
		Write-Output "Seeding database...";
		docker-compose exec postgres psql -U erp_admin -d erp_lab_saq -f /docker-entrypoint-initdb.d/002_seed_data.sql;
		Write-Output "✓ Database seeded"
	}
	"test"    { 
		Write-Output "Running backend tests...";
		cd backend; 
		go test ./...; 
	}
	"backend-shell" {
		docker-compose exec backend sh
	}
	"db-shell" {
		docker-compose exec postgres psql -U erp_admin -d erp_lab_saq
	}
	"help" { 
		Write-Output "Available commands:";
		Write-Output "  make dev      - Start all services in foreground";
		Write-Output "  make build    - Build all Docker images";
		Write-Output "  make up       - Start all services in background";
		Write-Output "  make down     - Stop all services";
		Write-Output "  make logs     - Show logs from all services";
		Write-Output "  make clean    - Stop services and remove volumes";
		Write-Output "  make migrate  - Run database migrations";
		Write-Output "  make seed     - Seed database with sample data";
		Write-Output "  make test     - Run backend tests"
	}
    default { 
		Write-Output "Available commands: dev, build, up, down, logs, clean, migrate" 
	}
}
