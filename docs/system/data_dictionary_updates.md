# Pembaruan Kamus Data & Catatan Implementasi (Edisi Go)

## 1. Strategi Log Audit (JSON Patch)
Implementasi menggunakan pustaka Go seperti `github.com/evanphx/json-patch` atau pustaka standar untuk proses pembedaan (*diffing*).

### Contoh Implementasi (Struct Go)
```go
type AuditLog struct {
    ID           uuid.UUID       `db:"id"`
    PrevHash     string          `db:"prev_hash"`
    CurrHash     string          `db:"curr_hash"` // SHA256
    ActionType   string          `db:"action_type"`
    Changes      json.RawMessage `db:"changes"`   // Format RFC 6902
    Metadata     json.RawMessage `db:"metadata"`
    Timestamp    time.Time       `db:"timestamp"`
}
```

### Skenario: Pembaruan Status
* **Data Lama:** `{"status": "DRAFT"}`
* **Data Baru:** `{"status": "SUBMITTED"}`
* **JSON Patch (RFC 6902) yang dihasilkan:**
    ```json
    [ { "op": "replace", "path": "/status", "value": "SUBMITTED" } ]
    ```

## 2. Penyimpanan Dokumen (Implementasi MinIO)
Backend tidak lagi menggunakan Git (`libgit2`). Sistem menggunakan API S3 sepenuhnya.

### Konfigurasi Bucket
* **Nama Bucket:** `erp-archives`
* **Versioning:** `Enabled` (Wajib diaktifkan pada konsol MinIO).
* **Object Lock:** Opsional, untuk kepatuhan *WORM (Write Once Read Many)*.

### Alur Unggah (Handler Go)
1.  Urai (*Parse*) `multipart/form-data`.
2.  Buat jalur objek: `uploads/{tahun}/{bulan}/{uuid}-{namafile}`.
3.  Alirkan berkas ke MinIO menggunakan SDK `minio-go` (`PutObject`).
4.  Dapatkan `VersionID` dari respons SDK.
5.  Simpan metadata ke tabel `DOCUMENT_VERSION`.

### Alur Unduh
1.  Pengguna meminta ID berkas.
2.  Backend memeriksa izin akses.
3.  Backend membuat **Presigned URL** (valid selama 15 menit).
4.  Arahkan pengguna ke URL tersebut atau *proxy stream* melalui backend.

## 3. Batasan Exclusive Arc (SQL DDL)
Batasan (*Constraint*) ini dipertahankan pada PostgreSQL untuk menjamin integritas data:

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