**Proyek:** ERP Lab SAQ
**Status:** Keputusan Final (Migrasi dari C++)
**Terakhir Diperbarui:** 22 Januari 2026

## 1. Backend Inti: Go (Golang)
Keputusan untuk beralih dari C++ ke Go diambil guna menyeimbangkan kebutuhan performa tinggi dengan efisiensi waktu pengembangan (*development velocity*).

* **Bahasa Pemrograman:** Go (Versi Stabil Terbaru).
* **Kerangka Kerja (Framework):** **Echo** atau **Gin**.
    * *Alasan:* Keduanya memiliki performa tinggi, minimalis, dan efisien. Penggunaan kerangka kerja yang terlalu berat (*bloated*) dihindari untuk menjaga latensi rendah.
* **Pola Arsitektur:** **Clean Architecture**.
    * `Handler`: Lapisan HTTP/Transport.
    * `Usecase`: Logika Bisnis & Mesin Status Alur Kerja (*Workflow State Machine*).
    * `Repository`: Akses Basis Data.
    * `Domain`: Entitas & Antarmuka (*Interfaces*).

## 2. Frontend: React + TypeScript
Penggunaan Vanilla JavaScript dihindari untuk menjaga integritas kode jangka panjang.

* **Pustaka (Library):** React 18+.
* **Bahasa:** TypeScript (Mode Ketat/Strict). Antarmuka TypeScript harus mencerminkan struktur (*Struct*) pada Go untuk konsistensi tipe data.
* **Manajemen State:** TanStack Query (React Query) untuk pengelolaan data sisi server (*server state*).
* **Kerangka Kerja UI:** Tailwind CSS + Shadcn/UI (dipilih untuk mempercepat pembuatan purwarupa dasbor).

## 3. Basis Data & Lapisan Penyimpanan
* **Basis Data Utama:** **PostgreSQL** (Data Relasional, JSONB untuk Log Audit).
* **Penyimpanan Objek:** **MinIO** (Kompatibel dengan S3).
    * Berfungsi menyimpan seluruh berkas biner (PDF, Gambar, Arsip ZIP).
    * **Versi Berkas:** Menggunakan fitur bawaan **Bucket Versioning** pada MinIO.
    * **Akses:** Bucket bersifat privat; akses dilakukan melalui *Presigned URL* yang dibuat oleh Backend Go.

## 4. Strategi Versioning
* **Kode Sumber:** Git (GitHub/GitLab).
* **Dokumen/Aset:** MinIO Versioning (referensi dicatat melalui `version_id` pada basis data).
* **Catatan:** Penggunaan pustaka Git (`libgit2`) pada layanan backend ditiadakan sepenuhnya.

## 5. Keamanan & Infrastruktur
* **Kontainerisasi:** Docker & Docker Compose.
* **Autentikasi:** JWT dengan masa berlaku singkat (*short expiration*) disertai rotasi *Refresh Token*.
* **Enkripsi:**
    * *At-Rest* (Saat disimpan): Enkripsi kolom sensitif pada Postgres (pgcrypto) & SSE-S3 pada MinIO.
    * *In-Transit* (Saat transmisi): TLS/SSL (dikelola oleh Nginx Reverse Proxy).