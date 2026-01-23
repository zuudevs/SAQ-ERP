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
		log.Println("Warning: .env file not found, using environment variables")
	}

	// Initialize configuration
	cfg := config.New()

	// Initialize database
	db, err := database.NewPostgres(cfg.Database)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	log.Println("✓ Database connected successfully")

	// Initialize MinIO
	minioClient, err := database.NewMinIO(cfg.MinIO)
	if err != nil {
		log.Fatalf("Failed to connect to MinIO: %v", err)
	}
	log.Printf("✓ MinIO connected successfully to %s", cfg.MinIO.Endpoint)
	_ = minioClient // Use later for file operations

	// Initialize repositories
	memberRepo := repository.NewMemberRepository(db)
	auditRepo := repository.NewAuditRepository(db)

	// Initialize usecases
	memberUC := usecase.NewMemberUsecase(memberRepo, auditRepo)

	// Initialize Echo
	e := echo.New()
	e.HideBanner = true

	// Middleware
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())
	e.Use(middleware.CORSWithConfig(middleware.CORSConfig{
		AllowOrigins: []string{
			"http://localhost:5173",
			"http://localhost:3000",
		},
		AllowMethods: []string{
			echo.GET,
			echo.POST,
			echo.PUT,
			echo.DELETE,
			echo.PATCH,
		},
		AllowHeaders: []string{
			echo.HeaderOrigin,
			echo.HeaderContentType,
			echo.HeaderAccept,
			echo.HeaderAuthorization,
		},
	}))

	// Initialize handlers
	handler.NewAuthHandler(e, cfg, memberRepo)
	handler.NewMemberHandler(e, memberUC)

	// Health check endpoint
	e.GET("/health", func(c echo.Context) error {
		return c.JSON(200, map[string]string{
			"status": "ok",
			"service": "ERP Lab SAQ",
		})
	})

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("🚀 Server starting on port %s", port)
	log.Printf("📡 API available at http://localhost:%s", port)
	log.Printf("🏥 Health check at http://localhost:%s/health", port)
	
	if err := e.Start(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}