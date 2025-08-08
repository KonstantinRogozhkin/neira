# Скрипт быстрой проверки статуса сборки Researcherry
# Использование: powershell -ExecutionPolicy ByPass -File .\check-build-status.ps1

$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"
$ColorInfo = "Cyan"

function Write-StatusLog {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Get-FolderSize {
    param([string]$Path)
    if (Test-Path $Path) {
        $size = (Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        return [math]::Round($size / 1MB, 2)
    }
    return 0
}

Write-StatusLog "=== ПРОВЕРКА СТАТУСА СБОРКИ RESEARCHERRY ===" $ColorInfo

# Проверка основных папок
$folders = @(
    @{Name="vscode"; Description="Исходный код VSCode"},
    @{Name="src"; Description="Кастомизированный код"},
    @{Name="vscode/node_modules"; Description="Зависимости Node.js"},
    @{Name="build"; Description="Скрипты сборки"}
)

foreach ($folder in $folders) {
    if (Test-Path $folder.Name) {
        $size = Get-FolderSize $folder.Name
        $fileCount = (Get-ChildItem -Path $folder.Name -Recurse -File -ErrorAction SilentlyContinue).Count
        Write-StatusLog "[OK] $($folder.Description): $size MB, $fileCount файлов" $ColorSuccess
    } else {
        Write-StatusLog "[ERROR] $($folder.Description): не найдена" $ColorError
    }
}

# Проверка готовых билдов
Write-StatusLog "`n--- ГОТОВЫЕ СБОРКИ ---" $ColorInfo
$buildFolders = Get-ChildItem -Path "." -Directory -ErrorAction SilentlyContinue | Where-Object { 
    $_.Name -like "*VSCode*" -or $_.Name -like "*Researcherry*" -or $_.Name -like "*win32*"
}

if ($buildFolders) {
    foreach ($folder in $buildFolders) {
        $size = Get-FolderSize $folder.FullName
        Write-StatusLog "[OK] Сборка: $($folder.Name) ($size MB)" $ColorSuccess
        
        # Поиск исполняемых файлов
        $exeFiles = Get-ChildItem -Path $folder.FullName -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue
        foreach ($exe in $exeFiles) {
            Write-StatusLog "   FILE: $($exe.Name)" $ColorInfo
        }
    }
} else {
    Write-StatusLog "[ERROR] Готовые сборки не найдены" $ColorError
}

# Проверка архивов
Write-StatusLog "`n--- АРХИВЫ ---" $ColorInfo
$archives = Get-ChildItem -Path "." -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in @(".zip", ".tar.gz") }
if ($archives) {
    foreach ($archive in $archives) {
        $size = [math]::Round($archive.Length / 1MB, 2)
        Write-StatusLog "[OK] Архив: $($archive.Name) ($size MB)" $ColorSuccess
    }
} else {
    Write-StatusLog "[ERROR] Архивы не найдены" $ColorError
}

# Проверка активных процессов
Write-StatusLog "`n--- АКТИВНЫЕ ПРОЦЕССЫ ---" $ColorInfo
$processes = Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -like "*node*" -or 
    $_.ProcessName -like "*npm*" -or 
    $_.ProcessName -like "*git*" -or 
    $_.ProcessName -like "*bash*"
}

if ($processes) {
    foreach ($proc in $processes) {
        Write-StatusLog "[RUNNING] $($proc.ProcessName) (PID: $($proc.Id))" $ColorWarning
    }
} else {
    Write-StatusLog "[OK] Активных процессов сборки нет" $ColorSuccess
}

# Проверка логов
Write-StatusLog "`n--- ЛОГИ ---" $ColorInfo
if (Test-Path "build-diagnostic.log") {
    $logSize = [math]::Round((Get-Item "build-diagnostic.log").Length / 1KB, 2)
    Write-StatusLog "[OK] Лог диагностики: $logSize KB" $ColorSuccess
} else {
    Write-StatusLog "[ERROR] Лог диагностики не найден" $ColorError
}

# Общая статистика
Write-StatusLog "`n--- ОБЩАЯ СТАТИСТИКА ---" $ColorInfo
$totalSize = Get-FolderSize "."
Write-StatusLog "[INFO] Общий размер проекта: $totalSize MB" $ColorInfo

$freeSpace = [math]::Round((Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace / 1GB, 2)
Write-StatusLog "[INFO] Свободное место на диске C: $freeSpace GB" $ColorInfo

Write-StatusLog "`n=== ПРОВЕРКА ЗАВЕРШЕНА ===" $ColorInfo
