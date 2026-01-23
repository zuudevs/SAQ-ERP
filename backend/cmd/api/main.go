package main

import (
	"log"
	"os"

	"github.com/joho/godotenv"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"github.com/zuudevs/erp-saq-lab/internal/config"
	"github.com/zuudevs/erp-saq-lab/internal/database"
	"github.com/zuudevs/erp-saq-lab/internal/handler"
	"github.com/zuudevs/erp-saq-lab/internal/repository"
	"github.com/zuudevs/erp-saq-lab/internal/usecase"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("Warning: .env file not found")
	}

	// Initialize configuration
	cfg := config.New()

	// Initialize database
	db, err := database.NewPostgres(cfg.Database)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Initialize MinIO
	_, err = database.NewMinIO(cfg.MinIO)
	if err != nil {
		log.Fatalf("Failed to connect to MinIO: %v", err)
	}

	// Initialize repositories
	memberRepo := repository.NewMemberRepository(db)
	auditRepo := repository.NewAuditRepository(db)

	// Initialize usecases
	memberUC := usecase.NewMemberUsecase(memberRepo, auditRepo)

	// Initialize Echo
	e := echo.New()

	// Middleware
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())
	e.Use(middleware.CORS())

	// Initialize handlers
	handler.NewMemberHandler(e, memberUC)

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	if err := e.Start(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}