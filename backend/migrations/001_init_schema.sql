-- =====================================================
-- CETAK BIRU DATABASE ERP LAB SAQ
-- Sesuai Dokumentasi: docs/02-database-design/
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- 1. REFERENSI (Master Data)
-- =====================================================

CREATE TABLE IF NOT EXISTS major (
    code VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    faculty VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS batch_generation (
    year INT PRIMARY KEY,
    nickname VARCHAR(50),
    entry_date DATE,
    graduation_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 2. CORE IDENTITY (Public Info)
-- =====================================================

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
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_status CHECK (status IN ('RECRUITMENT', 'ACTIVE', 'INACTIVE', 'ALUMNI', 'EXPELLED'))
);

-- =====================================================
-- 3. SENSITIVE DATA (PII - Wajib Encrypted)
-- =====================================================

CREATE TABLE IF NOT EXISTS member_sensitive_data (
    member_id UUID PRIMARY KEY REFERENCES member(id) ON DELETE CASCADE,
    nik_ktp VARCHAR(255),  -- Encrypted
    phone_number VARCHAR(255),  -- Encrypted
    personal_email VARCHAR(255),  -- Encrypted
    address TEXT,  -- Encrypted
    bank_account VARCHAR(255),  -- Encrypted
    date_of_birth DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 4. CAREER PATH (History Jabatan)
-- =====================================================

CREATE TABLE IF NOT EXISTS member_position_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id UUID NOT NULL REFERENCES member(id) ON DELETE CASCADE,
    role_name VARCHAR(50) NOT NULL,
    division VARCHAR(50),
    start_date DATE NOT NULL,
    end_date DATE,
    achievement TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 5. SKILLSET (Buat Penugasan Proyek)
-- =====================================================

CREATE TABLE IF NOT EXISTS member_skill (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id UUID NOT NULL REFERENCES member(id) ON DELETE CASCADE,
    skill_name VARCHAR(100) NOT NULL,
    proficiency VARCHAR(20) NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_proficiency CHECK (proficiency IN ('BEGINNER', 'INTERMEDIATE', 'EXPERT'))
);

-- =====================================================
-- 6. AUDIT LOG (IMMUTABLE - BLOCKCHAIN-LIKE)
-- =====================================================

CREATE TABLE IF NOT EXISTS immutable_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prev_hash VARCHAR(64),
    curr_hash VARCHAR(64) NOT NULL UNIQUE,
    actor_id UUID NOT NULL,
    role_snapshot VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT,
    action_type VARCHAR(20) NOT NULL,
    target_table VARCHAR(50) NOT NULL,
    target_id VARCHAR(100) NOT NULL,
    changes JSONB NOT NULL,
    metadata JSONB,
    CONSTRAINT chk_action_type CHECK (action_type IN ('CREATE', 'UPDATE', 'DELETE', 'APPROVE', 'REJECT'))
);

-- =====================================================
-- 7. DOCUMENT & ARCHIVE SYSTEM
-- =====================================================

CREATE TABLE IF NOT EXISTS master_archive (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    archive_code VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    category_tag VARCHAR(50),
    is_archived BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS document_version (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    master_archive_id UUID NOT NULL REFERENCES master_archive(id) ON DELETE CASCADE,
    version_number INT NOT NULL,
    bucket_name VARCHAR(100) NOT NULL,
    object_path VARCHAR(500) NOT NULL,
    s3_version_id VARCHAR(100),
    s3_etag VARCHAR(100),
    file_name_original VARCHAR(255) NOT NULL,
    file_mime_type VARCHAR(100),
    file_size_bytes BIGINT,
    change_note TEXT,
    uploader_id UUID REFERENCES member(id),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_version UNIQUE (master_archive_id, version_number)
);

-- =====================================================
-- 8. DOCUMENT CONTEXT ADAPTER (Exclusive Arc)
-- =====================================================

CREATE TABLE IF NOT EXISTS document_context_adapter (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    master_archive_id UUID NOT NULL REFERENCES master_archive(id) ON DELETE CASCADE,
    event_id UUID,
    daily_report_id UUID,
    item_id UUID,
    finance_transaction_id UUID,
    task_assignment_id UUID,
    relation_role VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_one_parent_only CHECK (
        (CASE WHEN event_id IS NOT NULL THEN 1 ELSE 0 END) +
        (CASE WHEN daily_report_id IS NOT NULL THEN 1 ELSE 0 END) +
        (CASE WHEN item_id IS NOT NULL THEN 1 ELSE 0 END) +
        (CASE WHEN finance_transaction_id IS NOT NULL THEN 1 ELSE 0 END) +
        (CASE WHEN task_assignment_id IS NOT NULL THEN 1 ELSE 0 END) = 1
    )
);

-- =====================================================
-- 9. INVENTORY MODULE
-- =====================================================

CREATE TABLE IF NOT EXISTS location (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS owner_entity (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_owner_type CHECK (type IN ('INTERNAL', 'EXTERNAL'))
);

CREATE TABLE IF NOT EXISTS item (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    brand VARCHAR(100),
    serial_number VARCHAR(100),
    specifications TEXT,
    location_id INT REFERENCES location(id),
    owner_entity_id INT REFERENCES owner_entity(id),
    status VARCHAR(50) NOT NULL DEFAULT 'AVAILABLE',
    purchase_order_id UUID,
    source_type VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_item_status CHECK (status IN ('AVAILABLE', 'BORROWED', 'MAINTENANCE', 'LOST', 'TAKEOVER'))
);

CREATE TABLE IF NOT EXISTS actor (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    identity_number VARCHAR(255),  -- Encrypted
    contact_info VARCHAR(255),  -- Encrypted
    type VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_actor_type CHECK (type IN ('STUDENT', 'LECTURER', 'PUBLIC'))
);

CREATE TABLE IF NOT EXISTS loan_transaction (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id UUID NOT NULL REFERENCES item(id),
    borrower_id UUID NOT NULL REFERENCES actor(id),
    start_time TIMESTAMP NOT NULL,
    due_date TIMESTAMP NOT NULL,
    actual_return_time TIMESTAMP,
    approval_status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    condition_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_loan_status CHECK (approval_status IN ('DRAFT', 'APPROVED', 'REJECTED', 'RETURNED'))
);

-- =====================================================
-- 10. PROCUREMENT MODULE
-- =====================================================

CREATE TABLE IF NOT EXISTS procurement_request (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    requester_id UUID REFERENCES member(id),
    event_id UUID,
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    required_date TIMESTAMP,
    status VARCHAR(30) NOT NULL DEFAULT 'DRAFT',
    rejection_reason TEXT,
    total_estimated_cost DECIMAL(15,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_procurement_status CHECK (status IN ('DRAFT', 'SUBMITTED', 'REVIEWED_LAB', 'REVIEWED_FINANCE', 'APPROVED', 'REJECTED', 'PARTIALLY_FULFILLED', 'COMPLETED'))
);

CREATE TABLE IF NOT EXISTS procurement_item (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL REFERENCES procurement_request(id) ON DELETE CASCADE,
    item_name VARCHAR(200) NOT NULL,
    item_url TEXT,
    quantity_requested INT NOT NULL,
    estimated_price_per_unit DECIMAL(15,2),
    priority VARCHAR(20) DEFAULT 'MEDIUM',
    status_per_item VARCHAR(20) DEFAULT 'PENDING',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_priority CHECK (priority IN ('HIGH', 'MEDIUM', 'LOW')),
    CONSTRAINT chk_item_status CHECK (status_per_item IN ('PENDING', 'APPROVED', 'REJECTED'))
);

CREATE TABLE IF NOT EXISTS purchase_order (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID REFERENCES procurement_request(id),
    executor_id UUID REFERENCES member(id),
    purchase_date TIMESTAMP,
    total_actual_cost DECIMAL(15,2),
    proof_file_url TEXT,
    proof_file_hash VARCHAR(64),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Link Purchase Order to Item
ALTER TABLE item ADD CONSTRAINT fk_purchase_order 
    FOREIGN KEY (purchase_order_id) REFERENCES purchase_order(id);

-- =====================================================
-- 11. OPERATIONS MODULE (Daily Teaching Log)
-- =====================================================

CREATE TABLE IF NOT EXISTS academic_period (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS subject (
    code VARCHAR(20) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    sks INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS class_session (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_code VARCHAR(20) NOT NULL REFERENCES subject(code),
    class_name VARCHAR(50) NOT NULL,
    default_room VARCHAR(100),
    default_day VARCHAR(20),
    default_start_time TIME,
    default_end_time TIME,
    main_lecturer_id UUID REFERENCES member(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS daily_report (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_date DATE NOT NULL UNIQUE,
    academic_period_id INT REFERENCES academic_period(id),
    officer_on_duty_id UUID REFERENCES member(id),
    general_notes TEXT,
    status VARCHAR(20) DEFAULT 'DRAFT',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_report_status CHECK (status IN ('DRAFT', 'SUBMITTED', 'ACKNOWLEDGED'))
);

CREATE TABLE IF NOT EXISTS teaching_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_session_id UUID NOT NULL REFERENCES class_session(id),
    daily_report_id UUID NOT NULL REFERENCES daily_report(id) ON DELETE CASCADE,
    assistant_id UUID REFERENCES member(id),
    meeting_number INT,
    material_delivered TEXT,
    class_condition VARCHAR(20),
    notes TEXT,
    session_status VARCHAR(20) NOT NULL,
    actual_start_time TIMESTAMP,
    actual_end_time TIMESTAMP,
    room_used VARCHAR(100),
    is_ppd BOOLEAN DEFAULT FALSE,
    ppd_start_time TIME,
    ppd_end_time TIME,
    ppd_notes TEXT,
    is_honorarium_claimed BOOLEAN DEFAULT FALSE,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_session_status CHECK (session_status IN ('ON_SCHEDULE', 'RESCHEDULED', 'ASYNC_TASK', 'CANCELLED'))
);

CREATE TABLE IF NOT EXISTS report_attachment (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    daily_report_id UUID NOT NULL REFERENCES daily_report(id) ON DELETE CASCADE,
    file_url TEXT NOT NULL,
    file_type VARCHAR(50),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 12. DUTY & TASK MODULE
-- =====================================================

CREATE TABLE IF NOT EXISTS shift_master (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS duty_roster (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    duty_date DATE NOT NULL,
    shift_id INT REFERENCES shift_master(id),
    member_id UUID REFERENCES member(id),
    status VARCHAR(20) DEFAULT 'SCHEDULED',
    check_in_time TIMESTAMP,
    check_out_time TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_duty_status CHECK (status IN ('SCHEDULED', 'PRESENT', 'ABSENT'))
);

CREATE TABLE IF NOT EXISTS task_category (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    color_code VARCHAR(7),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS task_assignment (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    category_id INT REFERENCES task_category(id),
    creator_id UUID REFERENCES member(id),
    start_date TIMESTAMP,
    due_date TIMESTAMP,
    priority VARCHAR(20) DEFAULT 'MEDIUM',
    status VARCHAR(20) DEFAULT 'TODO',
    progress_percentage INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    CONSTRAINT chk_task_priority CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    CONSTRAINT chk_task_status CHECK (status IN ('TODO', 'IN_PROGRESS', 'BLOCKED', 'REVIEW', 'COMPLETED')),
    CONSTRAINT chk_progress CHECK (progress_percentage BETWEEN 0 AND 100)
);

CREATE TABLE IF NOT EXISTS task_assignee (
    task_id UUID REFERENCES task_assignment(id) ON DELETE CASCADE,
    member_id UUID REFERENCES member(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'MEMBER',
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (task_id, member_id),
    CONSTRAINT chk_assignee_role CHECK (role IN ('LEADER', 'MEMBER'))
);

CREATE TABLE IF NOT EXISTS recurring_task_template (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    cron_schedule VARCHAR(100) NOT NULL,
    category_id INT REFERENCES task_category(id),
    priority VARCHAR(20) DEFAULT 'MEDIUM',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 13. FINANCE MODULE
-- =====================================================

CREATE TABLE IF NOT EXISTS finance_account (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL,
    current_balance DECIMAL(15,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_account_type CHECK (type IN ('ASSET', 'LIABILITY', 'EQUITY', 'INCOME', 'EXPENSE'))
);

CREATE TABLE IF NOT EXISTS finance_transaction (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_date DATE NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    amount DECIMAL(15,2) NOT NULL,
    from_account_id INT REFERENCES finance_account(id),
    to_account_id INT REFERENCES finance_account(id),
    status VARCHAR(20) DEFAULT 'DRAFT',
    creator_id UUID REFERENCES member(id),
    approver_id UUID REFERENCES member(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_finance_status CHECK (status IN ('DRAFT', 'SUBMITTED', 'APPROVED', 'REJECTED'))
);

-- =====================================================
-- 14. EVENT MODULE
-- =====================================================

CREATE TABLE IF NOT EXISTS event (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    location_name VARCHAR(200),
    status VARCHAR(20) DEFAULT 'DRAFT',
    pic_id UUID REFERENCES member(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_event_status CHECK (status IN ('DRAFT', 'PENDING', 'APPROVED', 'ONGOING', 'COMPLETED'))
);

CREATE TABLE IF NOT EXISTS event_tag (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    color_code VARCHAR(7),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS event_tag_map (
    event_id UUID REFERENCES event(id) ON DELETE CASCADE,
    tag_id INT REFERENCES event_tag(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (event_id, tag_id)
);

-- Add Foreign Keys for document_context_adapter
ALTER TABLE document_context_adapter 
    ADD CONSTRAINT fk_event FOREIGN KEY (event_id) REFERENCES event(id),
    ADD CONSTRAINT fk_daily_report FOREIGN KEY (daily_report_id) REFERENCES daily_report(id),
    ADD CONSTRAINT fk_item FOREIGN KEY (item_id) REFERENCES item(id),
    ADD CONSTRAINT fk_finance_transaction FOREIGN KEY (finance_transaction_id) REFERENCES finance_transaction(id),
    ADD CONSTRAINT fk_task_assignment FOREIGN KEY (task_assignment_id) REFERENCES task_assignment(id);

-- =====================================================
-- INDEXES (Performance Optimization)
-- =====================================================

-- Member Indexes
CREATE INDEX idx_member_nim ON member(nim);
CREATE INDEX idx_member_status ON member(status);
CREATE INDEX idx_member_generation ON member(generation_year);
CREATE INDEX idx_member_email ON member(email_uni);

-- Audit Log Indexes
CREATE INDEX idx_audit_target ON immutable_log(target_table, target_id);
CREATE INDEX idx_audit_timestamp ON immutable_log(timestamp DESC);
CREATE INDEX idx_audit_actor ON immutable_log(actor_id);
CREATE INDEX idx_audit_hash ON immutable_log(curr_hash);

-- Document Indexes
CREATE INDEX idx_doc_archive ON document_version(master_archive_id);
CREATE INDEX idx_doc_uploader ON document_version(uploader_id);

-- Inventory Indexes
CREATE INDEX idx_item_status ON item(status);
CREATE INDEX idx_item_location ON item(location_id);
CREATE INDEX idx_loan_status ON loan_transaction(approval_status);

-- Task Indexes
CREATE INDEX idx_task_status ON task_assignment(status);
CREATE INDEX idx_task_due ON task_assignment(due_date);
CREATE INDEX idx_task_creator ON task_assignment(creator_id);

-- Finance Indexes
CREATE INDEX idx_finance_date ON finance_transaction(transaction_date);
CREATE INDEX idx_finance_status ON finance_transaction(status);

-- Event Indexes
CREATE INDEX idx_event_status ON event(status);
CREATE INDEX idx_event_date ON event(start_time);

-- =====================================================
-- INITIAL DATA (Seed Data)
-- =====================================================

-- Insert default majors
INSERT INTO major (code, name, faculty) VALUES
    ('11', 'Teknik Informatika', 'Fakultas Teknik'),
    ('12', 'Sistem Informasi', 'Fakultas Teknik')
ON CONFLICT (code) DO NOTHING;

-- Insert default batch
INSERT INTO batch_generation (year, nickname, entry_date) VALUES
    (2024, 'Genesis', '2024-09-01'),
    (2025, 'Vanguard', '2025-09-01'),
    (2026, 'Pioneer', '2026-09-01')
ON CONFLICT (year) DO NOTHING;

-- Insert default locations
INSERT INTO location (name, code) VALUES
    ('Lab 1', 'LAB-1'),
    ('Lab 2', 'LAB-2'),
    ('Lemari A', 'CABINET-A'),
    ('Gudang', 'STORAGE')
ON CONFLICT (code) DO NOTHING;

-- Insert default owner entities
INSERT INTO owner_entity (name, type) VALUES
    ('Lab SAQ', 'INTERNAL'),
    ('Fakultas Teknik', 'INTERNAL'),
    ('External Donor', 'EXTERNAL')
ON CONFLICT DO NOTHING;

-- Insert default task categories
INSERT INTO task_category (name, color_code) VALUES
    ('Maintenance', '#FF5733'),
    ('Project', '#3498DB'),
    ('Kebersihan', '#2ECC71'),
    ('Administrasi', '#F39C12')
ON CONFLICT DO NOTHING;

-- Insert default finance accounts
INSERT INTO finance_account (name, type, current_balance) VALUES
    ('Kas Besar', 'ASSET', 0),
    ('Rekening BNI', 'ASSET', 0),
    ('Kas Kecil', 'ASSET', 0),
    ('Pendapatan Proyek', 'INCOME', 0),
    ('Biaya Operasional', 'EXPENSE', 0)
ON CONFLICT DO NOTHING;

-- Insert default shifts
INSERT INTO shift_master (name, start_time, end_time) VALUES
    ('Shift Pagi', '08:00:00', '12:00:00'),
    ('Shift Siang', '13:00:00', '17:00:00')
ON CONFLICT DO NOTHING;

-- Insert default event tags
INSERT INTO event_tag (name, color_code) VALUES
    ('Workshop', '#3498DB'),
    ('Seminar', '#E74C3C'),
    ('Rapat', '#F39C12'),
    ('Pelatihan', '#2ECC71')
ON CONFLICT DO NOTHING;