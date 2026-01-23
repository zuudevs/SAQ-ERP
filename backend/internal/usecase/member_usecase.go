package usecase

import (
	"encoding/json"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"github.com/zuudevs/erp-saq-lab/internal/domain"
	"github.com/zuudevs/erp-saq-lab/internal/repository"
)

type memberUsecase struct {
	memberRepo domain.MemberRepository
	auditRepo  repository.AuditRepository
}

func NewMemberUsecase(
	memberRepo domain.MemberRepository,
	auditRepo repository.AuditRepository,
) domain.MemberUsecase {
	return &memberUsecase{
		memberRepo: memberRepo,
		auditRepo:  auditRepo,
	}
}

func (u *memberUsecase) Register(member *domain.Member) error {
	// Set default values
	if member.Status == "" {
		member.Status = "RECRUITMENT"
	}
	if member.MemberRole == "" {
		member.MemberRole = "ANGGOTA"
	}

	// Hash password (default password = NIM)
	if member.PasswordHash == "" {
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(member.NIM), bcrypt.DefaultCost)
		if err != nil {
			return err
		}
		member.PasswordHash = string(hashedPassword)
	}

	// Create member
	if err := u.memberRepo.Create(member); err != nil {
		return err
	}

	// Log audit
	changes, _ := json.Marshal(member)
	auditLog := &repository.AuditLog{
		ActorID:      member.ID,
		RoleSnapshot: "SYSTEM",
		ActionType:   "CREATE",
		TargetTable:  "member",
		TargetID:     member.ID.String(),
		Changes:      changes,
	}
	
	// Don't fail registration if audit logging fails
	_ = u.auditRepo.Log(auditLog)

	return nil
}

func (u *memberUsecase) GetProfile(id uuid.UUID) (*domain.Member, error) {
	return u.memberRepo.FindByID(id)
}

func (u *memberUsecase) UpdateProfile(member *domain.Member) error {
	// Get old data for audit
	oldMember, err := u.memberRepo.FindByID(member.ID)
	if err != nil {
		return err
	}

	// Update member
	if err := u.memberRepo.Update(member); err != nil {
		return err
	}

	// Create audit log with changes
	type Change struct {
		Op    string      `json:"op"`
		Path  string      `json:"path"`
		Value interface{} `json:"value"`
	}

	var changes []Change
	if oldMember.Name != member.Name {
		changes = append(changes, Change{
			Op:    "replace",
			Path:  "/name",
			Value: member.Name,
		})
	}
	if oldMember.EmailUni != member.EmailUni {
		changes = append(changes, Change{
			Op:    "replace",
			Path:  "/email_uni",
			Value: member.EmailUni,
		})
	}

	if len(changes) > 0 {
		changesJSON, _ := json.Marshal(changes)
		auditLog := &repository.AuditLog{
			ActorID:      member.ID,
			RoleSnapshot: member.MemberRole,
			ActionType:   "UPDATE",
			TargetTable:  "member",
			TargetID:     member.ID.String(),
			Changes:      changesJSON,
		}
		_ = u.auditRepo.Log(auditLog)
	}

	return nil
}

func (u *memberUsecase) ListMembers(page, pageSize int) ([]*domain.Member, error) {
	offset := (page - 1) * pageSize
	return u.memberRepo.List(pageSize, offset)
}