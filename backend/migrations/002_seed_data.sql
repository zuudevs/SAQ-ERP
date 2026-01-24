-- =====================================================
-- SEED DATA untuk Testing
-- Password default semua user adalah NIM mereka
-- =====================================================

-- Insert sample member (password = 2024-11-001)
-- Hash dari bcrypt untuk "2024-11-001"
INSERT INTO member (nim, name, email_uni, generation_year, major_code, serial_number, status, member_role, password_hash)
VALUES 
    ('202631000', 'Admin User', 'admin@student.ac.id', 2024, '11', 1, 'ACTIVE', 'KOOR_LAB', '$2a$10$d9cMBFtJZUwU01MBkkZNF.0o5r71cf3BpSYtKeQc431i7tl5D2vrC'),
    ('202631001', 'Test User', 'test@student.ac.id', 2024, '11', 2, 'ACTIVE', 'ANGGOTA', '$2a$10$YourBcryptHashHere'),
    ('202631002', 'Bendahara User', 'bendahara@student.ac.id', 2024, '12', 1, 'ACTIVE', 'BENDAHARA', '$2a$10$YourBcryptHashHere')
ON CONFLICT (nim) DO NOTHING;

-- Note: Hash di atas adalah placeholder
-- Untuk production, generate proper bcrypt hash
-- Atau buat endpoint untuk set password pertama kali