# ==========================================================
# SKRIP PEMBERSIH VIRUS GRENAM (RE-NAMER / FILE INFECTOR)
# ==========================================================
# Skrip ini mencari file asli yang diubah namanya menjadi 'g*.exe'
# dan menyembunyikannya, kemudian menghapus file virus tiruan ('*.exe')
# dan mengembalikan nama & atribut file asli.
# ==========================================================

# Fungsi pembantu untuk menghitung ekstensi berkas sampah pendamping (misal .manifest -> .manifico)
function Get-JunkExtension {
    param ([string]$Extension)
    if ($Extension.Length -le 4) {
        return ".ico"
    } else {
        $extText = $Extension.Substring(1)
        if ($extText.Length -gt 3) {
            return "." + $extText.Substring(0, $extText.Length - 3) + "ico"
        } else {
            return ".ico"
        }
    }
}

# Fungsi pencarian rekursif yang aman dari Junction/Symlink (ReparsePoint)
function Get-SafeChildItem {
    param (
        [string]$Path,
        [int]$Depth = 0
    )
    # Batasi kedalaman rekursi maksimal 30 level untuk mencegah Call Depth Overflow
    if ($Depth -gt 30) {
        return @()
    }

    $results = @()
    
    # Tampilkan progress folder yang sedang aktif dipindai menggunakan Write-Progress agar tidak memenuhi log
    $script:folderCount++
    if ($script:folderCount % 50 -eq 0) {
        Write-Progress -Activity "Memindai Virus Grenam" -Status "Memindai: $Path"
    }
    
    # Cari file g* dengan ekstensi .exe, .ico, .manifest, .manifico, .blockmap, .blockico, atau .jar di folder ini
    $files = Get-ChildItem -Path $Path -Filter "g*" -Force -ErrorAction SilentlyContinue | Where-Object { 
        -not $_.PSIsContainer -and ($_.Extension -eq ".exe" -or $_.Extension -eq ".ico" -or $_.Extension -eq ".manifest" -or $_.Extension -eq ".manifico" -or $_.Extension -eq ".blockmap" -or $_.Extension -eq ".blockico" -or $_.Extension -eq ".jar")
    }
    if ($files) {
        foreach ($file in $files) { $results += $file }
    }
    
    # Cari subfolder yang BUKAN Junction / Symlink (ReparsePoint) dan bukan AppData
    $subDirs = Get-ChildItem -Path $Path -Directory -Force -ErrorAction SilentlyContinue | Where-Object { 
        $_.Attributes -notmatch 'ReparsePoint' -and $_.Name -ne 'AppData'
    }
    if ($subDirs) {
        foreach ($dir in $subDirs) {
            $subFiles = Get-SafeChildItem -Path $dir.FullName -Depth ($Depth + 1)
            if ($subFiles) {
                foreach ($sf in $subFiles) { $results += $sf }
            }
        }
    }
    return $results
}

# ----------------- KONFIGURASI PEMINDAIAN -----------------
# Mengatur batas ukuran maksimal file virus tiruan (dalam Megabyte).
# Jika file virus tiruan berukuran lebih besar dari ini, ia tidak akan dihapus demi keamanan.
$MaxVirusSizeMB = 5

# Folder/Direktori sistem yang HARUS DIKECUALIKAN dari pemindaian demi keamanan & kecepatan
$excludeFolders = @(
    "Windows",
    "System Volume Information",
    "`$Recycle.Bin",
    "`$WINDOWS.~BT",
    "`$SysReset",
    "Recovery",
    "ProgramData",
    "Users"  # Kita kecualikan folder Users utama untuk diproses subfoldernya secara aman
)

# Berkas bersih yang diawali huruf 'g'/'G' yang harus dikecualikan dari pembersihan otomatis
$globalCleanGFiles = @(
    "git.exe", "grep.exe", "gh.exe", "gpg.exe", "gdb.exe", "gcc.exe", "g++.exe", "go.exe", "gofmt.exe",
    "google-chrome.exe", "google-drive.exe", "gcompat.exe", "gspawn-win64-helper.exe", "gspawn-win64-helper-console.exe",
    "gui.exe", "gui-32.exe", "gui-64.exe", "gui-arm64.exe", "game_helper_32.exe", "game_helper_64.exe",
    "Gv.exe", "GvLedServices.exe", "GopInfoX.exe", "GoogleUpdate.exe", "GRAPH.EXE", "grv_icons.exe",
    "git-receive-pack.exe", "git-upload-pack.exe", "git-askpass.exe", "git-askyesno.exe",
    "git-credential-helper-selector.exe", "git-credential-manager.exe", "git-credential-wincred.exe",
    "git-http-fetch.exe", "git-http-push.exe", "git-remote-http.exe", "git-remote-https.exe",
    "git-sh-i18n--envsubst.exe", "git-wrapper.exe", "gencat.exe", "getfacl.exe", "getopt.exe",
    "gmondump.exe", "getprocaddr32.exe", "getprocaddr64.exe", "guidgen.exe", "graphedt.exe",
    "gamesaveutil.exe", "genmanifest.exe", "gc.exe", "Ghost-Chat.exe", "GoogleDriveFS.exe",
    "GeForce Experience Permission.exe", "GetHelp.exe", "GameBar.exe", "GameBarElevatedFT.exe", "GameBarFTServer.exe",
    "GPUSniffer.exe", "gifopt.exe", "gifsicle.exe", "gifdiff.exe", "giftool.exe", "GpuSpeedTest.exe", "GenerateGPUDatabase.exe",
    "gupdate.exe", "gupdatem.exe", "GameOverlayUI.exe", "geckodriver.exe", "gswin64c.exe", "gswin64.exe", "gimp.exe",
    "g2m.exe", "g2mcomm.exe", "g2mtrans.exe", "g2mupdate.exe", "gen_snapshot.exe", "git-credential-store.exe",
    "git-fast-import.exe", "git-show-index.exe", "GitHub.Authentication.exe", "gawk.exe", "gblocked-file-util.exe",
    "gflutter_tester.exe", "GoW.exe", "Graph.exe", "Graph.exe.manifest", "guile.exe", "gs.exe"
)

# ----------------- PENGATURAN MODE AKTIF -----------------
# SECARA DEFAULT: $DryRun = $true (Skrip hanya mensimulasikan pemindaian, tidak menghapus apa pun)
# UBAH MENJADI: $DryRun = $false untuk mulai melakukan pembersihan asli.
$DryRun = $false

# Path Log Pembersihan di Folder Skrip Ini
$scriptFolder = $PSScriptRoot
if (-not $scriptFolder) { $scriptFolder = $pwd }
$logFile = Join-Path -Path $scriptFolder -ChildPath "Log_Pemulihan_Grenam.txt"
# ----------------------------------------------------------

# 1. Cek Hak Akses Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[-] PERINGATAN: Skrip tidak berjalan sebagai Administrator!" -ForegroundColor Yellow
    Write-Host "Beberapa folder sistem (seperti Program Files) atau proses virus di latar belakang" -ForegroundColor Yellow
    Write-Host "mungkin tidak bisa diakses/dimodifikasi tanpa hak akses Administrator." -ForegroundColor Yellow
    Write-Host "Disarankan menutup jendela ini, klik kanan PowerShell, dan pilih 'Run as Administrator'." -ForegroundColor Yellow
    Write-Host "`nTekan Enter jika ingin melanjutkan dalam mode non-Admin..." -ForegroundColor Cyan
    [void]$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Mulai menulis log
Stop-Transcript -ErrorAction SilentlyContinue
Start-Transcript -Path $logFile -Force

# Deteksi semua drive penyimpanan tipe 'Fixed' (Harddisk/SSD internal)
$drives = [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq 'Fixed' } | Select-Object -ExpandProperty Name

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "          MULAI PEMINDAIAN VIRUS GRENAM" -ForegroundColor Cyan
Write-Host "  Drive terdeteksi: $($drives -join ', ')" -ForegroundColor Yellow
if ($DryRun) {
    Write-Host "  MODE: DRY RUN (SIMULASI - Tidak ada file yang diubah)" -ForegroundColor Yellow
} else {
    Write-Host "  MODE: AKTIF (MENGHAPUS VIRUS & MEMULIHKAN FILE ASLI)" -ForegroundColor Red
}
Write-Host "=======================================================" -ForegroundColor Cyan

# 1.5. Bersihkan virus utama (Payload) dan Startup Entry
Write-Host "`n[+] Memeriksa payload virus utama (Ground.exe)..." -ForegroundColor Cyan

# Dapatkan path dinamis menggunakan .NET Environment API
$appDataRoaming = [Environment]::GetFolderPath('ApplicationData')
$groundPath = Join-Path -Path $appDataRoaming -ChildPath "Ground.exe"

$startupFolder = [Environment]::GetFolderPath('Startup')
$groundLnk = Join-Path -Path $startupFolder -ChildPath "Ground.lnk"

# Hentikan proses jika Ground sedang berjalan
$virusProcess = Get-Process -Name "Ground" -ErrorAction SilentlyContinue
if ($null -ne $virusProcess) {
    Write-Host "[!] Terdeteksi proses virus utama sedang aktif: Ground (PID: $($virusProcess.Id))" -ForegroundColor Red
    if (-not $DryRun) {
        Write-Host "    [-] Menghentikan proses Ground..." -ForegroundColor Yellow
        Stop-Process -Name "Ground" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    } else {
        Write-Host "    [DryRun] Akan menghentikan proses Ground" -ForegroundColor Gray
    }
}

# Hapus file payload Ground.exe
if (Test-Path $groundPath) {
    Write-Host "[!] Terdeteksi file virus utama: $groundPath" -ForegroundColor Red
    if (-not $DryRun) {
        Remove-Item -Path $groundPath -Force -ErrorAction SilentlyContinue
        Write-Host "    [-] File virus utama berhasil dihapus." -ForegroundColor Yellow
    } else {
        Write-Host "    [DryRun] Akan menghapus file virus utama: $groundPath" -ForegroundColor Gray
    }
}

# Hapus file startup link Ground.lnk
if (Test-Path $groundLnk) {
    Write-Host "[!] Terdeteksi startup link virus: $groundLnk" -ForegroundColor Red
    if (-not $DryRun) {
        Remove-Item -Path $groundLnk -Force -ErrorAction SilentlyContinue
        Write-Host "    [-] Startup link virus berhasil dihapus." -ForegroundColor Yellow
    } else {
        Write-Host "    [DryRun] Akan menghapus startup link virus: $groundLnk" -ForegroundColor Gray
    }
}

# 2. Cari dan matikan proses virus yang sedang berjalan di RAM
Write-Host "`n[+] Memeriksa memori RAM untuk proses yang mencurigakan..." -ForegroundColor Cyan
$processes = Get-Process | Where-Object { $_.Path -and (Test-Path $_.Path) }
$terminatedCount = 0

foreach ($proc in $processes) {
    try {
        $procPath = $proc.Path
        $procDir = [System.IO.Path]::GetDirectoryName($procPath)
        $procName = [System.IO.Path]::GetFileName($procPath)
        
        # Cek apakah ada file pendamping dengan awalan 'g' di folder yang sama
        $gName = "g" + $procName
        $gPath = Join-Path -Path $procDir -ChildPath $gName
        
        if (Test-Path -Path $gPath) {
            # Ditemukan indikasi virus: ada process.exe berjalan, dan gprocess.exe ada di folder tersebut
            $procFile = Get-Item -Path $procPath -Force -ErrorAction SilentlyContinue
            $gFile = Get-Item -Path $gPath -Force -ErrorAction SilentlyContinue
            
            if ($null -ne $procFile -and $null -ne $gFile) {
                # Jika ukuran file proses sama persis dengan file 'g*.exe' pendampingnya,
                # kemungkinan besar ini adalah file asli yang terduplikasi (bukan virus)
                if ($procFile.Length -eq $gFile.Length) {
                    continue
                }
                
                if ($procFile.Length -lt ($MaxVirusSizeMB * 1024 * 1024)) {
                    Write-Host "[!] Terdeteksi proses virus aktif: $($proc.ProcessName) ($procPath)" -ForegroundColor Red
                    if (-not $DryRun) {
                        Write-Host "    [-] Menghentikan proses: $($proc.ProcessName)..." -ForegroundColor Yellow
                        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                        $terminatedCount++
                    } else {
                        Write-Host "    [DryRun] Akan menghentikan proses: $($proc.ProcessName)" -ForegroundColor Gray
                    }
                }
            }
        }
    } catch {
        # Abaikan error akses proses sistem internal
    }
}

if ($terminatedCount -gt 0) {
    # Beri jeda waktu agar Windows melepaskan lock file setelah proses dimatikan
    Start-Sleep -Seconds 2
}

# 3. Kumpulkan folder yang akan dipindai di setiap drive
$scanPaths = @()
foreach ($drive in $drives) {
    # Tambahkan root drive untuk dipindai di tingkat paling atas saja
    $scanPaths += $drive
    
    # Dapatkan semua folder utama di drive ini (abaikan Junctions/Symlinks dengan ReparsePoint)
    $topFolders = Get-ChildItem -Path $drive -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $_.Attributes -notmatch 'ReparsePoint' }
    foreach ($folder in $topFolders) {
        if ($excludeFolders -notcontains $folder.Name) {
            $scanPaths += $folder.FullName
        } else {
            Write-Host "[~] Melewati folder sistem: $($folder.FullName)" -ForegroundColor DarkGray
        }
    }
    
    # Proses khusus untuk folder Users secara aman tanpa memicu loop junction
    $usersPath = Join-Path -Path $drive -ChildPath "Users"
    if (Test-Path $usersPath) {
        $scanPaths += $usersPath
        # Dapatkan subfolder di dalam Users, abaikan Junctions (ReparsePoint) seperti 'Default User'
        $userSubfolders = Get-ChildItem -Path $usersPath -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $_.Attributes -notmatch 'ReparsePoint' }
        foreach ($sub in $userSubfolders) {
            $scanPaths += $sub.FullName
        }
    }

    # Proses khusus untuk folder ProgramData secara aman tanpa memicu loop junction
    $programDataPath = Join-Path -Path $drive -ChildPath "ProgramData"
    if (Test-Path $programDataPath) {
        $scanPaths += $programDataPath
        # Dapatkan subfolder di dalam ProgramData, abaikan Junctions (ReparsePoint) seperti 'Application Data'
        $progDataSubfolders = Get-ChildItem -Path $programDataPath -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $_.Attributes -notmatch 'ReparsePoint' }
        foreach ($sub in $progDataSubfolders) {
            $scanPaths += $sub.FullName
        }
    }
}

# 4. Pindai folder target di disk
$virusCount = 0
$restoredCount = 0
$script:folderCount = 0

foreach ($path in $scanPaths) {
    if (Test-Path $path) {
        # Cari apakah path ini root drive atau folder induk yang mengandung junction
        $isRootOrJunctionParent = ($path -match '^[a-zA-Z]:\\$') -or ($path -match '\\Users$') -or ($path -match '\\ProgramData$')
        if ($isRootOrJunctionParent) {
            Write-Host "`n[+] Memindai Folder Tingkat Atas (Non-Rekursif): $path" -ForegroundColor Yellow
            $files = Get-ChildItem -Path $path -Filter "g*" -Force -ErrorAction SilentlyContinue | Where-Object {
                -not $_.PSIsContainer -and ($_.Extension -eq ".exe" -or $_.Extension -eq ".ico" -or $_.Extension -eq ".manifest" -or $_.Extension -eq ".manifico")
            }
        } else {
            Write-Host "`n[+] Memindai folder secara rekursif (Aman): $path" -ForegroundColor Yellow
            $files = Get-SafeChildItem -Path $path
        }
        
        $icosToDelete = @()
        
        foreach ($currentFile in $files) {
            $dirPath = $currentFile.Directory.FullName
            $fileName = $currentFile.Name
            
            if ($currentFile.Extension -eq ".ico" -or $currentFile.Extension -eq ".manifico" -or $currentFile.Extension -eq ".blockico") {
                # Cek berkas .ico, .manifico, atau .blockico palsu/rusak (0 KB)
                if ($currentFile.Length -eq 0) {
                    $icosToDelete += $currentFile.FullName
                }
            }
            elseif ($currentFile.Extension -eq ".exe" -or $currentFile.Extension -eq ".manifest" -or $currentFile.Extension -eq ".blockmap" -or $currentFile.Extension -eq ".jar") {
                # Cek apakah file ini ada di daftar pengecualian berkas bersih
                $isCleanTool = $false
                $nameToCheck = $fileName
                if ($fileName.EndsWith(".manifest", [System.StringComparison]::OrdinalIgnoreCase)) {
                    $nameToCheck = $fileName.Substring(0, $fileName.Length - 9)
                }
                elseif ($fileName.EndsWith(".blockmap", [System.StringComparison]::OrdinalIgnoreCase)) {
                    $nameToCheck = $fileName.Substring(0, $fileName.Length - 9)
                }
                foreach ($cn in $globalCleanGFiles) {
                    if ($fileName -ieq $cn -or $nameToCheck -ieq $cn) {
                        $isCleanTool = $true
                        break
                    }
                }
                if ($isCleanTool) {
                    continue
                }

                # Ekstrak nama asli (buang huruf 'g' pertama)
                $originalName = $fileName.Substring(1)
                
                # Cegah kesalahan jika nama file terlalu pendek atau menghasilkan nama kosong
                if ($originalName -eq ".exe" -or $originalName.Length -lt 4) {
                    continue
                }
                
                $fakeVirusPath = Join-Path -Path $dirPath -ChildPath $originalName
                
                # Cek apakah file tiruan virus (tanpa 'g') ada di sana
                if (Test-Path -Path $fakeVirusPath) {
                    $fakeFile = Get-Item -Path $fakeVirusPath -Force -ErrorAction SilentlyContinue
                    
                    # Jika ukuran file tiruan sama persis dengan file asli tersembunyi,
                    # kemungkinan besar ini adalah file duplikat asli (bukan virus)
                    if ($null -ne $fakeFile -and $fakeFile.Length -eq $currentFile.Length) {
                        Write-Host "`n[~] Duplikat aman ditemukan di: $dirPath" -ForegroundColor Green
                        Write-Host "    -> File Asli: $originalName ($([Math]::Round($fakeFile.Length / 1KB, 2)) KB)" -ForegroundColor Green
                        Write-Host "    -> File Duplikat Tersembunyi: $fileName ($([Math]::Round($currentFile.Length / 1KB, 2)) KB)" -ForegroundColor DarkGray
                        if (-not $DryRun) {
                            Remove-Item -Path $currentFile.FullName -Force -ErrorAction SilentlyContinue
                            Write-Host "    [-] File duplikat tersembunyi berhasil dibersihkan." -ForegroundColor Yellow
                        } else {
                            Write-Host "    [DryRun] Simulasi: File duplikat tersembunyi akan dibersihkan." -ForegroundColor Gray
                        }
                        
                        # Cari berkas ikon pendamping 0 KB untuk dibersihkan
                        $icoNamesToCheck = @("$originalName.ico", "$fileName.ico", "$([System.IO.Path]::GetFileNameWithoutExtension($originalName)).ico", "$([System.IO.Path]::GetFileNameWithoutExtension($fileName)).ico")
                        foreach ($icoName in $icoNamesToCheck) {
                            $icoPath = Join-Path -Path $dirPath -ChildPath $icoName
                            if (Test-Path $icoPath) {
                                $icoFile = Get-Item -Path $icoPath -Force -ErrorAction SilentlyContinue
                                if ($null -ne $icoFile -and $icoFile.Length -eq 0) {
                                    $icosToDelete += $icoFile.FullName
                                }
                            }
                        }
                        
                        continue
                    }
                    
                    # Validasi ukuran virus berdasarkan batas maksimal di konfigurasi
                    if ($null -ne $fakeFile -and $fakeFile.Length -lt ($MaxVirusSizeMB * 1024 * 1024)) {
                        $virusCount++
                        Write-Host "`n[!] Terinfeksi ditemukan di: $dirPath" -ForegroundColor Red
                        Write-Host "    -> File Virus Tiruan: $originalName ($([Math]::Round($fakeFile.Length / 1KB, 2)) KB)" -ForegroundColor Red
                        Write-Host "    -> File Asli Disembunyikan: $fileName ($([Math]::Round($currentFile.Length / 1KB, 2)) KB)" -ForegroundColor Cyan
                        
                        if (-not $DryRun) {
                            # JIT (Just-In-Time) Process Termination:
                            # Cek jika ada proses berjalan yang memuat file virus tiruan ini agar file tidak dikunci OS
                            $runningProcesses = Get-Process | Where-Object { $_.Path -eq $fakeVirusPath } -ErrorAction SilentlyContinue
                            if ($runningProcesses) {
                                foreach ($p in $runningProcesses) {
                                    Write-Host "    [-] Menghentikan paksa proses pengunci: $($p.Name) (PID: $($p.Id))" -ForegroundColor Yellow
                                    Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
                                }
                                Start-Sleep -Milliseconds 800 # Beri waktu sejenak agar Windows melepas lock file
                            }

                            # A. Hapus virus tiruan
                            Remove-Item -Path $fakeVirusPath -Force -ErrorAction SilentlyContinue
                            Write-Host "    [-] Virus tiruan berhasil dihapus." -ForegroundColor Yellow
                            
                            # B. Kembalikan nama file asli
                            Rename-Item -Path $currentFile.FullName -NewName $originalName -Force -ErrorAction SilentlyContinue
                            
                            # C. Hapus atribut Hidden/System agar file asli terlihat kembali
                            $restoredPath = Join-Path -Path $dirPath -ChildPath $originalName
                            $restoredItem = Get-Item -Path $restoredPath -Force -ErrorAction SilentlyContinue
                            if ($null -ne $restoredItem) {
                                $restoredItem.Attributes = "Normal"
                                Write-Host "    [+] Berhasil me-rename file: $fileName -> $originalName (dan menghapus atribut tersembunyi)" -ForegroundColor Green
                                $restoredCount++
                            } else {
                                Write-Host "    [x] Gagal mengubah atribut file asli ke normal." -ForegroundColor DarkYellow
                            }
                        } else {
                            Write-Host "    [DryRun] Simulasi: Virus akan dihapus dan file asli akan dipulihkan." -ForegroundColor Gray
                        }
                        
                        # Cari berkas ikon pendamping 0 KB untuk dibersihkan (misal .ico atau .manifico)
                        $junkExt = Get-JunkExtension -Extension $currentFile.Extension
                        $baseOriginal = [System.IO.Path]::GetFileNameWithoutExtension($originalName)
                        $baseFile = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
                        $icoNamesToCheck = @(
                            "$originalName$junkExt", 
                            "$fileName$junkExt", 
                            "$baseOriginal$junkExt", 
                            "$baseFile$junkExt",
                            "$originalName.ico",
                            "$fileName.ico",
                            "$baseOriginal.ico",
                            "$baseFile.ico"
                        )
                        foreach ($icoName in $icoNamesToCheck) {
                            $icoPath = Join-Path -Path $dirPath -ChildPath $icoName
                            if (Test-Path $icoPath) {
                                $icoFile = Get-Item -Path $icoPath -Force -ErrorAction SilentlyContinue
                                if ($null -ne $icoFile -and $icoFile.Length -eq 0) {
                                    $icosToDelete += $icoFile.FullName
                                }
                            }
                        }
                    }
                } else {
                    # KASUS DI MANA FILE TIRUAN VIRUS TIDAK ADA (SUDAH DIHAPUS ANTIVIRUS)
                    # Tetapi file asli yang diubah namanya menjadi 'g*.exe' masih ada.
                    # Kita pulihkan berkas asli ini!
                    
                    # Khusus file .jar, kita harus pastikan file tersebut tersembunyi (Hidden/System)
                    # agar tidak merusak/mengubah nama file .jar bersih (seperti groovy.jar)
                    $isOriginalHidden = $currentFile.Attributes.HasFlag([System.IO.FileAttributes]::Hidden) -or $currentFile.Attributes.HasFlag([System.IO.FileAttributes]::System)
                    if ($currentFile.Extension -eq ".jar" -and -not $isOriginalHidden) {
                        continue
                    }
                    
                    Write-Host "`n[!] File asli tersembunyi/diubah namanya ditemukan tanpa file virus aktif di: $dirPath" -ForegroundColor Yellow
                    Write-Host "    -> Berkas Saat Ini: $fileName ($([Math]::Round($currentFile.Length / 1KB, 2)) KB)" -ForegroundColor Cyan
                    
                    if (-not $DryRun) {
                        # Kembalikan nama file asli
                        Rename-Item -Path $currentFile.FullName -NewName $originalName -Force -ErrorAction SilentlyContinue
                        
                        # Hapus atribut Hidden/System agar file asli terlihat kembali
                        $restoredPath = Join-Path -Path $dirPath -ChildPath $originalName
                        $restoredItem = Get-Item -Path $restoredPath -Force -ErrorAction SilentlyContinue
                        if ($null -ne $restoredItem) {
                            $restoredItem.Attributes = "Normal"
                            Write-Host "    [+] Berhasil me-rename file: $fileName -> $originalName (dan menghapus atribut tersembunyi)" -ForegroundColor Green
                            $restoredCount++
                        } else {
                            Write-Host "    [x] Gagal mengubah atribut file asli ke normal." -ForegroundColor DarkYellow
                        }
                    } else {
                        Write-Host "    [DryRun] Simulasi: File asli akan dipulihkan (karena file tiruan virus tidak ada)." -ForegroundColor Gray
                    }
                    
                    # Cari berkas ikon pendamping 0 KB untuk dibersihkan (misal .ico atau .manifico)
                    $junkExt = Get-JunkExtension -Extension $currentFile.Extension
                    $baseOriginal = [System.IO.Path]::GetFileNameWithoutExtension($originalName)
                    $baseFile = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
                    $icoNamesToCheck = @(
                        "$originalName$junkExt", 
                        "$fileName$junkExt", 
                        "$baseOriginal$junkExt", 
                        "$baseFile$junkExt",
                        "$originalName.ico",
                        "$fileName.ico",
                        "$baseOriginal.ico",
                        "$baseFile.ico"
                    )
                    $icosFound = @()
                    foreach ($icoName in $icoNamesToCheck) {
                        $icoPath = Join-Path -Path $dirPath -ChildPath $icoName
                        if (Test-Path $icoPath) {
                            $icoFile = Get-Item -Path $icoPath -Force -ErrorAction SilentlyContinue
                            if ($null -ne $icoFile -and $icoFile.Length -eq 0) {
                                $icosFound += $icoFile.FullName
                            }
                        }
                    }
                    
                    if ($icosFound) {
                        $icosToDelete += $icosFound
                    }
                }
            }
        }
        
        # Bersihkan berkas .ico yang terkumpul
        if ($icosToDelete) {
            $icosToDelete = $icosToDelete | Select-Object -Unique
            foreach ($icoPath in $icosToDelete) {
                if (Test-Path $icoPath) {
                    $icoName = [System.IO.Path]::GetFileName($icoPath)
                    if (-not $DryRun) {
                        Remove-Item -Path $icoPath -Force -ErrorAction SilentlyContinue
                        Write-Host "    [-] Menghapus ikon sampah virus (0 KB): $icoName" -ForegroundColor Yellow
                    } else {
                        Write-Host "    [DryRun] Simulasi: Akan menghapus ikon sampah virus (0 KB): $icoName" -ForegroundColor Gray
                    }
                }
            }
        }
    }
}

# Selesai memindai, hapus progress bar dari layar
Write-Progress -Activity "Memindai Virus Grenam" -Completed

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "                 PEMINDAIAN SELESAI!" -ForegroundColor Green
Write-Host "Total file terinfeksi terdeteksi: $virusCount" -ForegroundColor Yellow
if (-not $DryRun) {
    Write-Host "Total file asli berhasil dipulihkan: $restoredCount" -ForegroundColor Green
}
Write-Host "Log lengkap pembersihan telah disimpan di:" -ForegroundColor Gray
Write-Host "$logFile" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Cyan

Stop-Transcript
