# Grenam Virus Cleaner & Restorer 🛡️

Sebuah skrip PowerShell yang dirancang secara khusus untuk mendeteksi, membersihkan, dan memulihkan infeksi **Virus Grenam (Win32/Grenam)** secara tuntas pada sistem operasi Windows. Skrip ini memindai seluruh drive penyimpanan, menghapus payload samaran virus, dan mengembalikan file asli yang disembunyikan oleh virus ke kondisi semula.

---

## 🚀 Fitur Utama

| Fitur | Penjelasan | Keunggulan Teknis |
| :--- | :--- | :--- |
| **Heuristic Multi-Drive Scan** | Memindai seluruh drive yang terdeteksi (`C:\` hingga `H:\`) secara aman dan terstruktur. | Membatasi kedalaman rekursi hingga **maksimal 30 level** untuk mencegah *stack overflow* pada folder virtual (seperti Google Drive). |
| **Multi-Extension Support** | Mendukung pembersihan file target yang diinfeksi virus: `.exe`, `.manifest`, `.blockmap`, dan `.jar` (Java Archive). | Menangani kasus infeksi pada tools developer dan IDE (seperti Android Studio/VS Code) secara tuntas. |
| **JIT Process Killer** | Menghentikan paksa proses mencurigakan di memori RAM yang mengunci file virus. | Mencegah terjadinya kegagalan pembersihan akibat file yang sedang digunakan/dikunci oleh sistem operasi (*file lock*). |
| **Smart Whitelisting** | Mengecualikan file bersih sistem dan developer yang diawali huruf 'g' (misal `git.exe`, `gawk.exe`, `gen_snapshot.exe`, `GoW.exe`). | **Manifest-Aware Whitelisting**: Menganalisis file `.manifest`/`.blockmap` dan mencocokkannya dengan executable di whitelist untuk mencegah *false positive*. |
| **Simulasi (Dry Run)** | Mode aman untuk melakukan simulasi pemindaian tanpa mengubah atau menghapus data apa pun. | Mengaktifkan `$DryRun = $true` untuk menganalisis infeksi terlebih dahulu sebelum aksi pembersihan nyata dilakukan. |
| **Pembersihan Berkas Sampah** | Otomatis melacak dan menghapus file pendamping kosong (**0 KB**) dengan ekstensi `.ico`, `.manifico`, dan `.blockico`. | Membersihkan sisa junk file ikon tanpa merusak ikon internal yang tertanam dalam file executable asli. |
| **Pencatatan Log Transkrip** | Seluruh proses aktivitas pemindaian disimpan secara transparan. | Output otomatis dicatat ke dalam file log terpusat: `Log_Pemulihan_Grenam.txt`. |

---

## 🛠️ Cara Penggunaan

Ikuti langkah-langkah di bawah ini untuk menjalankan pembersihan pada komputer Anda:

### 1. Buka PowerShell Sebagai Administrator
Untuk mengakses folder sistem (seperti `Program Files`) dan menghentikan proses virus, Anda harus menjalankan skrip ini dengan hak akses Administrator:
* Klik **Start**, cari **PowerShell**.
* Klik kanan pada **Windows PowerShell**, lalu pilih **Run as Administrator**.

### 2. Unduh dan Masuk ke Direktori Skrip
Arahkan direktori PowerShell Anda ke folder tempat skrip `clean_grenam.ps1` disimpan:
```powershell
cd "D:\1. MY CODE\Groundfinder"
```
*(Ganti jalur di atas sesuai dengan lokasi penyimpanan skrip Anda)*

### 3. Jalankan Skrip Pembersihan
Eksekusi skrip dengan mengabaikan pembatasan kebijakan eksekusi lokal (*Execution Policy Bypass*):
```powershell
powershell -ExecutionPolicy Bypass -File .\clean_grenam.ps1
```

---

## ⚠️ Informasi Penting untuk Pengguna

> [!IMPORTANT]
> **Mode Simulasi (Dry Run):**
> Secara default, Anda dapat memantau atau menguji perilaku skrip terlebih dahulu dengan mengubah nilai variabel `$DryRun = $true` di dalam skrip. Ubah variabel menjadi `$DryRun = $false` untuk mulai melakukan pembersihan asli.

> [!WARNING]
> **Proses Windows Defender:**
> Jika Windows Defender mendeteksi file `.jar` atau `.exe` Anda sebagai `Virus:Win32/Grenam`, itu karena virus telah mengganti file tersebut dengan payload virus sebesar ~521 KB. Skrip ini akan menghapus file palsu tersebut dan mengembalikan file asli yang disembunyikan (`g[nama].jar`/`g[nama].exe`) kembali ke nama aslinya secara aman.

---

## 📄 Log Pemulihan
Hasil pemindaian dan pemulihan dapat dilihat secara real-time pada jendela PowerShell atau dibaca setelah pemindaian selesai pada berkas:
📄 [Log_Pemulihan_Grenam.txt](file:///D:/1.%20MY%20CODE/Groundfinder/Log_Pemulihan_Grenam.txt)
