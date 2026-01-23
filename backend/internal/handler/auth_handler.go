package handler

import (
	"net/http"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/labstack/echo/v4"
	"golang.org/x/crypto/bcrypt"
	"github.com/zuudevs/erp-saq-lab/internal/config"
	"github.com/zuudevs/erp-saq-lab/internal/domain"
	"github.com/zuudevs/erp-saq-lab/internal/middleware"
)

type AuthHandler struct {
	cfg        *config.Config
	memberRepo domain.MemberRepository
}

func NewAuthHandler(e *echo.Echo, cfg *config.Config, memberRepo domain.MemberRepository) {
	handler := &AuthHandler{
		cfg:        cfg,
		memberRepo: memberRepo,
	}

	auth := e.Group("/api/v1/auth")
	auth.POST("/login", handler.Login)
}

type LoginRequest struct {
	NIM      string `json:"nim"`
	Password string `json:"password"`
}

type LoginResponse struct {
	Token        string `json:"token"`
	RefreshToken string `json:"refresh_token"`
	UserID       string `json:"user_id"`
	Role         string `json:"role"`
	Name         string `json:"name"`
}

func (h *AuthHandler) Login(c echo.Context) error {
	var req LoginRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid request body",
		})
	}

	// Find user by NIM
	member, err := h.memberRepo.FindByNIM(req.NIM)
	if err != nil {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "Invalid credentials",
		})
	}

	// Verify password using bcrypt
	err = bcrypt.CompareHashAndPassword([]byte(member.PasswordHash), []byte(req.Password))
	if err != nil {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "Invalid credentials",
		})
	}

	// Generate JWT token
	claims := &middleware.JWTClaims{
		UserID: member.ID.String(),
		Role:   member.MemberRole,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(h.cfg.JWT.Secret))
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": "Failed to generate token",
		})
	}

	// Generate refresh token
	refreshClaims := &middleware.JWTClaims{
		UserID: claims.UserID,
		Role:   claims.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(7 * 24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	refreshToken := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims)
	refreshTokenString, err := refreshToken.SignedString([]byte(h.cfg.JWT.Secret))
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": "Failed to generate refresh token",
		})
	}

	return c.JSON(http.StatusOK, LoginResponse{
		Token:        tokenString,
		RefreshToken: refreshTokenString,
		UserID:       claims.UserID,
		Role:         claims.Role,
		Name:         member.Name,
	})
}