-- CORE TABLES
CREATE TABLE IF NOT EXISTS major (
    code VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    faculty VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS batch_generation (
    year INT PRIMARY KEY,
    nickname VARCHAR(50),
    entry_date DATE,
    graduation_date DATE
);

CREATE TABLE IF NOT EXISTS member (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nim VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    email_uni VARCHAR(100) UNIQUE NOT NULL,
    generation_year INT NOT NULL REFERENCES batch_generation(year),
    major_code VARCHAR(10) NOT NULL REFERENCES major(code),
    serial_number INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'RECRUITMENT',
    current_role VARCHAR(50) DEFAULT 'ANGGOTA',
    password_hash VARCHAR(255) NOT NULL,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- AUDIT LOG TABLE
CREATE TABLE IF NOT EXISTS immutable_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prev_hash VARCHAR(64),
    curr_hash VARCHAR(64) NOT NULL,
    actor_id UUID NOT NULL,
    role_snapshot VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT,
    action_type VARCHAR(20) NOT NULL,
    target_table VARCHAR(50) NOT NULL,
    target_id VARCHAR(100) NOT NULL,
    changes JSONB NOT NULL,
    metadata JSONB
);

-- Indexes untuk performa
CREATE INDEX idx_member_nim ON member(nim);
CREATE INDEX idx_member_status ON member(status);
CREATE INDEX idx_audit_target ON immutable_log(target_table, target_id);
CREATE INDEX idx_audit_timestamp ON immutable_log(timestamp DESC);