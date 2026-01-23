param(
    [string]$target = "help"
)

switch ($target) {
    "dev"     { docker-compose up }
    "build"   { docker-compose build }
    "up"      { docker-compose up -d }
    "down"    { docker-compose down }
    "logs"    { docker-compose logs -f }
    "clean"   { docker-compose down -v; docker system prune -f }
    "migrate" { docker-compose exec postgres psql -U erp_admin -d erp_lab_saq -f /docker-entrypoint-initdb.d/001_init_schema.sql }
    default   { Write-Output "Available commands: dev, build, up, down, logs, clean, migrate" }
}
