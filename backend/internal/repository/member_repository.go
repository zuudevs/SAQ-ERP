package repository

import (
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/zuudevs/erp-saq-lab/internal/domain"
)

type memberRepository struct {
	db *sqlx.DB
}

func NewMemberRepository(db *sqlx.DB) domain.MemberRepository {
	return &memberRepository{db: db}
}

func (r *memberRepository) Create(member *domain.Member) error {
	query := `
		INSERT INTO member (nim, name, email_uni, generation_year, major_code, 
			serial_number, status, member_role, password_hash)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		RETURNING id, joined_at, updated_at
	`
	return r.db.QueryRow(
		query,
		member.NIM,
		member.Name,
		member.EmailUni,
		member.GenerationYear,
		member.MajorCode,
		member.SerialNumber,
		member.Status,
		member.MemberRole,
		member.PasswordHash,
	).Scan(&member.ID, &member.JoinedAt, &member.UpdatedAt)
}

func (r *memberRepository) FindByID(id uuid.UUID) (*domain.Member, error) {
	var member domain.Member
	query := `
		SELECT id, nim, name, email_uni, generation_year, major_code,
			serial_number, status, member_role, password_hash, joined_at, updated_at
		FROM member
		WHERE id = $1
	`
	err := r.db.Get(&member, query, id)
	if err != nil {
		return nil, err
	}
	return &member, nil
}

func (r *memberRepository) FindByNIM(nim string) (*domain.Member, error) {
	var member domain.Member
	query := `
		SELECT id, nim, name, email_uni, generation_year, major_code,
			serial_number, status, member_role, password_hash, joined_at, updated_at
		FROM member
		WHERE nim = $1
	`
	err := r.db.Get(&member, query, nim)
	if err != nil {
		return nil, err
	}
	return &member, nil
}

func (r *memberRepository) Update(member *domain.Member) error {
	query := `
		UPDATE member
		SET name = $1, email_uni = $2, status = $3, member_role = $4,
			updated_at = CURRENT_TIMESTAMP
		WHERE id = $5
	`
	_, err := r.db.Exec(
		query,
		member.Name,
		member.EmailUni,
		member.Status,
		member.MemberRole,
		member.ID,
	)
	return err
}

func (r *memberRepository) List(limit, offset int) ([]*domain.Member, error) {
	var members []*domain.Member
	query := `
		SELECT id, nim, name, email_uni, generation_year, major_code,
			serial_number, status, member_role, joined_at, updated_at
		FROM member
		ORDER BY joined_at DESC
		LIMIT $1 OFFSET $2
	`
	err := r.db.Select(&members, query, limit, offset)
	return members, err
}