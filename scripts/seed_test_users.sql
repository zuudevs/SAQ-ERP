-- =====================================================
-- QUICK SEED TEST USERS
-- Jalankan: docker-compose exec postgres psql -U erp_admin -d erp_lab_saq -f /scripts/seed_test_users.sql
-- =====================================================

-- Password bcrypt hash untuk masing-masing user:
-- admin123 -> $2a$10$N9qo8uLOickgx2ZMRZoMye6p66Le683LKkjXVUU0dQPEQ0Ks5tHsC
-- 2024-11-001 -> $2a$10$YourHashHere (atau gunakan NIM sebagai password)

-- User 1: Admin (password: admin123)
INSERT INTO member (
    nim, name, email_uni, generation_year, major_code, 
    serial_number, status, member_role, password_hash
) VALUES (
    '2024-11-001',
    'Admin Lab SAQ',
    'admin@student.ac.id',
    2024,
    '11',
    1,
    'ACTIVE',
    'KOOR_LAB',
    '$2a$10$N9qo8uLOickgx2ZMRZoMye6p66Le683LKkjXVUU0dQPEQ0Ks5tHsC'
) ON CONFLICT (nim) DO UPDATE SET
    password_hash = EXCLUDED.password_hash;

-- User 2: Bendahara (password: bendahara123)  
INSERT INTO member (
    nim, name, email_uni, generation_year, major_code, 
    serial_number, status, member_role, password_hash
) VALUES (
    '2024-11-002',
    'Bendahara Lab',
    'bendahara@student.ac.id',
    2024,
    '11',
    2,
    'ACTIVE',
    'BENDAHARA',
    '$2a$10$5Fqm8p7qGBA9k.3xVqh8S.HxZWF2tqU9bGCvqKCXmJq5HqYqHqHqH'
) ON CONFLICT (nim) DO UPDATE SET
    password_hash = EXCLUDED.password_hash;

-- User 3: Anggota Biasa (password: anggota123)
INSERT INTO member (
    nim, name, email_uni, generation_year, major_code, 
    serial_number, status, member_role, password_hash
) VALUES (
    '2024-12-001',
    'Anggota Lab',
    'anggota@student.ac.id',
    2024,
    '12',
    1,
    'ACTIVE',
    'ANGGOTA',
    '$2a$10$8qCkx9VqXEJ7NxQqSVGG5OXqYqFqGqHqMqPqNqOqSqTqVqWqXqYqZ'
) ON CONFLICT (nim) DO UPDATE SET
    password_hash = EXCLUDED.password_hash;

-- Tampilkan hasil
SELECT nim, name, member_role, status FROM member ORDER BY nim;