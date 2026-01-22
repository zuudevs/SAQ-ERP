# Data Dictionary Updates & Implementation Notes

## 1. Audit Log Strategy (JSON Patch Implementation)
Gunakan library C++ seperti `nlohmann/json` untuk menghasilkan diff.
Format kolom `changes` di tabel `IMMUTABLE_LOG` wajib mengikuti standar **RFC 6902**.

### Contoh Kasus: Update Status Tugas
* **Skenario:** User mengubah status task dari `IN_PROGRESS` ke `COMPLETED` dan progress jadi 100%.
* **Database Action:** INSERT INTO immutable_log ...
* **JSONB `changes`:**
  ```json
  [
    { "op": "replace", "path": "/status", "value": "COMPLETED" },
    { "op": "replace", "path": "/progress_percentage", "value": 100 }
  ]
  ```

### Contoh Kasus: Komentar pada Tugas
* **Skenario:** User berkomentar "Kabel LAN sudah diganti".
* **Database Action:** INSERT INTO immutable_log ...
* **Kolom `action_type`:** `COMMENT`
* **Kolom `changes`:** `null` (Karena tidak ada data tabel yang berubah)
* **Kolom `metadata`:**
  ```json
  {
    "comment_text": "Kabel LAN sudah diganti",
    "attachment_url": null,
    "mentioned_users": ["uuid-user-lain"]
  }
  ```

## 2. Git Integration (Backend C++ with libgit2)
Backend tidak menyimpan file biner di database. Database hanya menyimpan metadata dan pointer commit.

### Konfigurasi Server
* **Repo Path:** `/var/erp_data/repo.git` (Bare Repository direkomendasikan).
* **Git User:** Set global config server sebagai `system@lab-saq.id` atau gunakan Signature user yang login saat commit.

### Flow Upload (Write)
1. Backend menerima Stream Multipart.
2. Tulis file ke working directory sementara.
3. Panggil `git_index_add_bypath` (libgit2).
4. Panggil `git_commit_create` (Author = User Login).
5. Ambil SHA-1 Hash dari hasil commit.
6. **SQL Insert:** Simpan SHA-1 ke tabel `DOCUMENT_VERSION` kolom `git_commit_hash`.

### Flow Download (Read)
1. User request file ID.
2. DB Lookup -> Ambil `git_commit_hash` & `git_tree_path`.
3. Panggil `git_commit_lookup` & `git_tree_entry_bypath`.
4. Stream blob content dari Git Object Database ke HTTP Response.

## 3. Exclusive Arc Constraint (SQL DDL)
Pastikan saat `CREATE TABLE document_context_adapter`, tambahkan constraint ini untuk mencegah satu dokumen nyasar ke banyak modul sekaligus:

```sql
CONSTRAINT chk_one_parent_only CHECK (
    (CASE WHEN event_id IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN daily_report_id IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN item_id IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN finance_transaction_id IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN task_assignment_id IS NOT NULL THEN 1 ELSE 0 END)
    = 1
);
```