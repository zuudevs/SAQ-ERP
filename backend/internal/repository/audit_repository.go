package repository

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type AuditLog struct {
	ID          uuid.UUID       `db:"id"`
	PrevHash    *string         `db:"prev_hash"`
	CurrHash    string          `db:"curr_hash"`
	ActorID     uuid.UUID       `db:"actor_id"`
	RoleSnapshot string         `db:"role_snapshot"`
	ActionType  string          `db:"action_type"`
	TargetTable string          `db:"target_table"`
	TargetID    string          `db:"target_id"`
	Changes     json.RawMessage `db:"changes"`
	IPAddress   *string         `db:"ip_address"`
	UserAgent   *string         `db:"user_agent"`
}

type AuditRepository interface {
	Log(log *AuditLog) error
	GetLastHash() (*string, error)
}

type auditRepository struct {
	db *sqlx.DB
}

func NewAuditRepository(db *sqlx.DB) AuditRepository {
	return &auditRepository{db: db}
}

func (r *auditRepository) Log(log *AuditLog) error {
	// Get previous hash
	prevHash, err := r.GetLastHash()
	if err != nil {
		return err
	}
	log.PrevHash = prevHash

	// Calculate current hash
	hashData := fmt.Sprintf("%v%s%s%s%s",
		prevHash,
		log.ActorID.String(),
		log.ActionType,
		log.TargetTable,
		log.Changes,
	)
	hash := sha256.Sum256([]byte(hashData))
	log.CurrHash = hex.EncodeToString(hash[:])

	// Insert log
	query := `
		INSERT INTO immutable_log 
		(prev_hash, curr_hash, actor_id, role_snapshot, action_type, 
		 target_table, target_id, changes, ip_address, user_agent)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		RETURNING id
	`
	return r.db.QueryRow(
		query,
		log.PrevHash,
		log.CurrHash,
		log.ActorID,
		log.RoleSnapshot,
		log.ActionType,
		log.TargetTable,
		log.TargetID,
		log.Changes,
		log.IPAddress,
		log.UserAgent,
	).Scan(&log.ID)
}

func (r *auditRepository) GetLastHash() (*string, error) {
	var hash *string
	query := `SELECT curr_hash FROM immutable_log ORDER BY timestamp DESC LIMIT 1`
	err := r.db.Get(&hash, query)
	if err != nil {
		// If no records exist, return nil
		return nil, nil
	}
	return hash, nil
}