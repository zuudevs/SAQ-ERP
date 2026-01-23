package domain

import (
    "time"
    "github.com/google/uuid"
)

type Member struct {
    ID              uuid.UUID  `json:"id" db:"id"`
    NIM             string     `json:"nim" db:"nim"`
    Name            string     `json:"name" db:"name"`
    EmailUni        string     `json:"email_uni" db:"email_uni"`
    GenerationYear  int        `json:"generation_year" db:"generation_year"`
    MajorCode       string     `json:"major_code" db:"major_code"`
    SerialNumber    int        `json:"serial_number" db:"serial_number"`
    Status          string     `json:"status" db:"status"`
    MemberRole      string     `json:"member_role" db:"member_role"`  // FIXED: Changed from current_role
    PasswordHash    string     `json:"-" db:"password_hash"`          // ADDED: For authentication
    JoinedAt        time.Time  `json:"joined_at" db:"joined_at"`
    UpdatedAt       time.Time  `json:"updated_at" db:"updated_at"`
}

type MemberRepository interface {
    Create(member *Member) error
    FindByID(id uuid.UUID) (*Member, error)
    FindByNIM(nim string) (*Member, error)
    Update(member *Member) error
    List(limit, offset int) ([]*Member, error)
}

type MemberUsecase interface {
    Register(member *Member) error
    GetProfile(id uuid.UUID) (*Member, error)
    UpdateProfile(member *Member) error
    ListMembers(page, pageSize int) ([]*Member, error)
}