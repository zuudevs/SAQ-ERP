package handler

import (
	"net/http"
	"strconv"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"github.com/zuudevs/erp-saq-lab/internal/domain"
)

type MemberHandler struct {
	memberUC domain.MemberUsecase
}

func NewMemberHandler(e *echo.Echo, memberUC domain.MemberUsecase) {
	handler := &MemberHandler{
		memberUC: memberUC,
	}

	// Routes
	api := e.Group("/api/v1")
	members := api.Group("/members")

	members.POST("", handler.Register)
	members.GET("/:id", handler.GetProfile)
	members.PUT("/:id", handler.UpdateProfile)
	members.GET("", handler.ListMembers)
}

type RegisterRequest struct {
	NIM            string `json:"nim"`
	Name           string `json:"name"`
	EmailUni       string `json:"email_uni"`
	GenerationYear int    `json:"generation_year"`
	MajorCode      string `json:"major_code"`
	SerialNumber   int    `json:"serial_number"`
}

func (h *MemberHandler) Register(c echo.Context) error {
	var req RegisterRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid request body",
		})
	}

	member := &domain.Member{
		NIM:            req.NIM,
		Name:           req.Name,
		EmailUni:       req.EmailUni,
		GenerationYear: req.GenerationYear,
		MajorCode:      req.MajorCode,
		SerialNumber:   req.SerialNumber,
	}

	if err := h.memberUC.Register(member); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusCreated, member)
}

func (h *MemberHandler) GetProfile(c echo.Context) error {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid ID format",
		})
	}

	member, err := h.memberUC.GetProfile(id)
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{
			"error": "Member not found",
		})
	}

	return c.JSON(http.StatusOK, member)
}

func (h *MemberHandler) UpdateProfile(c echo.Context) error {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid ID format",
		})
	}

	var member domain.Member
	if err := c.Bind(&member); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid request body",
		})
	}
	member.ID = id

	if err := h.memberUC.UpdateProfile(&member); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, member)
}

func (h *MemberHandler) ListMembers(c echo.Context) error {
	page, _ := strconv.Atoi(c.QueryParam("page"))
	if page < 1 {
		page = 1
	}

	pageSize, _ := strconv.Atoi(c.QueryParam("page_size"))
	if pageSize < 1 || pageSize > 100 {
		pageSize = 10
	}

	members, err := h.memberUC.ListMembers(page, pageSize)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"data": members,
		"meta": map[string]int{
			"page":      page,
			"page_size": pageSize,
		},
	})
}