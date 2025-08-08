# Скрипт пошаговой сборки Researcherry с диагностикой
# Автор: Cascade AI Assistant
# Дата: 2025-08-05
# Использование: powershell -ExecutionPolicy ByPass -File .\build-researcherry-diagnostic.ps1

param(
    [switch]$SkipClean = $false,
    [switch]$SkipDownload = $false,
    [switch]$SkipPatch = $false,
    [switch]$SkipBuild = $false,
    [switch]$Verbose = $false
)

# Цвета для вывода
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"
$ColorInfo = "Cyan"
$ColorStep = "Magenta"

# Функция для логирования
function Write-DiagnosticLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $Color
    
    # Записываем в лог файл
    "$timestamp [$Level] $Message" | Out-File -FilePath "build-diagnostic.log" -Append -Encoding UTF8
}

# Функция для проверки команды
function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

# Функция для проверки размера папки
function Get-FolderSize {
    param([string]$Path)
    if (Test-Path $Path) {
        $size = (Get-ChildItem -Path $Path -Recurse -File | Measure-Object -Property Length -Sum).Sum
        return [math]::Round($size / 1MB, 2)
    }
    return 0
}

# Функция для проверки процессов
function Get-BuildProcesses {
    return Get-Process | Where-Object {
        $_.ProcessName -like "*node*" -or 
        $_.ProcessName -like "*npm*" -or 
        $_.ProcessName -like "*git*" -or 
        $_.ProcessName -like "*bash*"
    }
}

Write-DiagnosticLog "=== НАЧАЛО ДИАГНОСТИЧЕСКОЙ СБОРКИ RESEARCHERRY ===" "START" $ColorStep

# Этап 1: Проверка системных требований
Write-DiagnosticLog "Этап 1: Проверка системных требований" "STEP" $ColorStep

# Проверка Node.js
if (Test-Command "node") {
    $nodeVersion = node --version
    Write-DiagnosticLog "Node.js версия: $nodeVersion" "INFO" $ColorInfo
    
    # Проверка требуемой версии
    $requiredVersion = Get-Content ".nvmrc" -ErrorAction SilentlyContinue
    if ($requiredVersion) {
        $requiredVersion = $requiredVersion.Trim()
        if ($nodeVersion -ne "v$requiredVersion") {
            Write-DiagnosticLog "ВНИМАНИЕ: Требуется Node.js v$requiredVersion, установлена $nodeVersion" "WARNING" $ColorWarning
        } else {
            Write-DiagnosticLog "Версия Node.js соответствует требованиям" "SUCCESS" $ColorSuccess
        }
    }
} else {
    Write-DiagnosticLog "ОШИБКА: Node.js не найден" "ERROR" $ColorError
    exit 1
}

# Проверка Python
if (Test-Command "python") {
    $pythonVersion = python --version
    Write-DiagnosticLog "Python версия: $pythonVersion" "INFO" $ColorInfo
} else {
    Write-DiagnosticLog "ВНИМАНИЕ: Python не найден (может потребоваться для нативных модулей)" "WARNING" $ColorWarning
}

# Проверка Git Bash
$bashPath = "C:\Program Files\Git\bin\bash.exe"
if (Test-Path $bashPath) {
    Write-DiagnosticLog "Git Bash найден: $bashPath" "SUCCESS" $ColorSuccess
} else {
    Write-DiagnosticLog "ОШИБКА: Git Bash не найден по пути $bashPath" "ERROR" $ColorError
    exit 1
}

# Проверка свободного места на диске
$drive = (Get-Location).Drive
$freeSpace = [math]::Round((Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$($drive.Name)'").FreeSpace / 1GB, 2)
Write-DiagnosticLog "Свободное место на диске $($drive.Name): $freeSpace GB" "INFO" $ColorInfo
if ($freeSpace -lt 10) {
    Write-DiagnosticLog "ВНИМАНИЕ: Мало свободного места (рекомендуется минимум 10 GB)" "WARNING" $ColorWarning
}

# Этап 2: Установка переменных окружения
Write-DiagnosticLog "Этап 2: Установка переменных окружения Researcherry" "STEP" $ColorStep

$env:APP_NAME = "Researcherry"
$env:APP_NAME_LC = "researcherry"
$env:BINARY_NAME = "researcherry"
$env:GH_REPO_PATH = "VSCodium/vscodium"
$env:ORG_NAME = "Researcherry"
$env:ASSETS_REPOSITORY = "VSCodium/vscodium"
$env:CI_BUILD = "no"
$env:SHOULD_BUILD = "yes"
$env:SKIP_ASSETS = "yes"
$env:SKIP_BUILD = "no"
$env:SKIP_SOURCE = "no"
$env:VSCODE_LATEST = "no"
$env:VSCODE_QUALITY = "stable"
$env:VSCODE_SKIP_NODE_VERSION_CHECK = "yes"

Write-DiagnosticLog "Переменные окружения установлены:" "INFO" $ColorInfo
Write-DiagnosticLog "  APP_NAME: $env:APP_NAME" "INFO" $ColorInfo
Write-DiagnosticLog "  BINARY_NAME: $env:BINARY_NAME" "INFO" $ColorInfo
Write-DiagnosticLog "  VSCODE_QUALITY: $env:VSCODE_QUALITY" "INFO" $ColorInfo

# Этап 3: Очистка предыдущих артефактов
if (-not $SkipClean) {
    Write-DiagnosticLog "Этап 3: Очистка предыдущих артефактов" "STEP" $ColorStep
    
    $itemsToClean = @("vscode", "src", "node_modules", "VSCode-*", "*.tar.gz", "*.zip")
    foreach ($item in $itemsToClean) {
        if (Test-Path $item) {
            $size = Get-FolderSize $item
            Write-DiagnosticLog "Удаление $item (размер: $size MB)" "INFO" $ColorInfo
            Remove-Item -Path $item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Write-DiagnosticLog "Очистка завершена" "SUCCESS" $ColorSuccess
} else {
    Write-DiagnosticLog "Этап 3: Пропуск очистки (флаг -SkipClean)" "SKIP" $ColorWarning
}

# Этап 4: Загрузка исходного кода VSCode
if (-not $SkipDownload) {
    Write-DiagnosticLog "Этап 4: Загрузка исходного кода VSCode" "STEP" $ColorStep
    
    Write-DiagnosticLog "Запуск get_repo.sh..." "INFO" $ColorInfo
    $startTime = Get-Date
    
    try {
        & $bashPath ./get_repo.sh 2>&1 | ForEach-Object {
            Write-DiagnosticLog "get_repo: $_" "INFO" $ColorInfo
        }
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMinutes
        Write-DiagnosticLog "Загрузка завершена за $([math]::Round($duration, 2)) минут" "SUCCESS" $ColorSuccess
        
        # Проверка результата
        if (Test-Path "vscode") {
            $vscodeFolderSize = Get-FolderSize "vscode"
            $fileCount = (Get-ChildItem -Path "vscode" -Recurse -File).Count
            Write-DiagnosticLog "Папка vscode создана: $vscodeFolderSize MB, $fileCount файлов" "SUCCESS" $ColorSuccess
        } else {
            Write-DiagnosticLog "ОШИБКА: Папка vscode не создана" "ERROR" $ColorError
            exit 1
        }
    } catch {
        Write-DiagnosticLog "ОШИБКА при загрузке исходного кода: $($_.Exception.Message)" "ERROR" $ColorError
        exit 1
    }
} else {
    Write-DiagnosticLog "Этап 4: Пропуск загрузки (флаг -SkipDownload)" "SKIP" $ColorWarning
}

# Этап 5: Подготовка и применение патчей
if (-not $SkipPatch) {
    Write-DiagnosticLog "Этап 5: Подготовка и применение патчей Researcherry" "STEP" $ColorStep
    
    Write-DiagnosticLog "Запуск prepare-researcherry.sh..." "INFO" $ColorInfo
    $startTime = Get-Date
    
    try {
        & $bashPath ./prepare-researcherry.sh 2>&1 | ForEach-Object {
            Write-DiagnosticLog "prepare: $_" "INFO" $ColorInfo
        }
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMinutes
        Write-DiagnosticLog "Подготовка завершена за $([math]::Round($duration, 2)) минут" "SUCCESS" $ColorSuccess
        
        # Проверка результата
        if (Test-Path "src") {
            $srcFolderSize = Get-FolderSize "src"
            Write-DiagnosticLog "Папка src создана: $srcFolderSize MB" "SUCCESS" $ColorSuccess
        } else {
            Write-DiagnosticLog "ВНИМАНИЕ: Папка src не создана" "WARNING" $ColorWarning
        }
        
        # Проверка product.json
        if (Test-Path "vscode/product.json") {
            $productContent = Get-Content "vscode/product.json" -Raw
            if ($productContent -like "*Researcherry*") {
                Write-DiagnosticLog "product.json успешно настроен для Researcherry" "SUCCESS" $ColorSuccess
            } else {
                Write-DiagnosticLog "ВНИМАНИЕ: product.json может быть не настроен для Researcherry" "WARNING" $ColorWarning
            }
        }
    } catch {
        Write-DiagnosticLog "ОШИБКА при подготовке: $($_.Exception.Message)" "ERROR" $ColorError
        Write-DiagnosticLog "Продолжаем выполнение..." "WARNING" $ColorWarning
    }
} else {
    Write-DiagnosticLog "Этап 5: Пропуск подготовки (флаг -SkipPatch)" "SKIP" $ColorWarning
}

# Этап 6: Установка зависимостей
Write-DiagnosticLog "Этап 6: Установка зависимостей Node.js" "STEP" $ColorStep

if (Test-Path "vscode") {
    Push-Location "vscode"
    
    Write-DiagnosticLog "Установка зависимостей в папке vscode..." "INFO" $ColorInfo
    $startTime = Get-Date
    
    try {
        npm install 2>&1 | ForEach-Object {
            if ($Verbose) {
                Write-DiagnosticLog "npm: $_" "INFO" $ColorInfo
            }
        }
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMinutes
        Write-DiagnosticLog "Установка зависимостей завершена за $([math]::Round($duration, 2)) минут" "SUCCESS" $ColorSuccess
        
        # Проверка node_modules
        if (Test-Path "node_modules") {
            $nodeModulesSize = Get-FolderSize "node_modules"
            Write-DiagnosticLog "node_modules создан: $nodeModulesSize MB" "SUCCESS" $ColorSuccess
        } else {
            Write-DiagnosticLog "ОШИБКА: node_modules не создан" "ERROR" $ColorError
            Pop-Location
            exit 1
        }
    } catch {
        Write-DiagnosticLog "ОШИБКА при установке зависимостей: $($_.Exception.Message)" "ERROR" $ColorError
        Pop-Location
        exit 1
    }
    
    Pop-Location
} else {
    Write-DiagnosticLog "ОШИБКА: Папка vscode не найдена" "ERROR" $ColorError
    exit 1
}

# Этап 7: Сборка приложения
if (-not $SkipBuild) {
    Write-DiagnosticLog "Этап 7: Сборка приложения Researcherry" "STEP" $ColorStep
    
    Push-Location "vscode"
    
    Write-DiagnosticLog "Запуск сборки..." "INFO" $ColorInfo
    $startTime = Get-Date
    
    try {
        # Сборка для Windows
        npm run compile 2>&1 | ForEach-Object {
            if ($Verbose) {
                Write-DiagnosticLog "compile: $_" "INFO" $ColorInfo
            }
        }
        
        Write-DiagnosticLog "Компиляция завершена, запуск упаковки..." "INFO" $ColorInfo
        
        npm run gulp -- vscode-win32-x64 2>&1 | ForEach-Object {
            if ($Verbose) {
                Write-DiagnosticLog "gulp: $_" "INFO" $ColorInfo
            }
        }
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMinutes
        Write-DiagnosticLog "Сборка завершена за $([math]::Round($duration, 2)) минут" "SUCCESS" $ColorSuccess
        
    } catch {
        Write-DiagnosticLog "ОШИБКА при сборке: $($_.Exception.Message)" "ERROR" $ColorError
        Pop-Location
        exit 1
    }
    
    Pop-Location
} else {
    Write-DiagnosticLog "Этап 7: Пропуск сборки (флаг -SkipBuild)" "SKIP" $ColorWarning
}

# Этап 8: Проверка результатов
Write-DiagnosticLog "Этап 8: Проверка результатов сборки" "STEP" $ColorStep

# Поиск готовых билдов
$buildFolders = Get-ChildItem -Path "." -Directory | Where-Object { $_.Name -like "*VSCode*" -or $_.Name -like "*Researcherry*" }
if ($buildFolders) {
    foreach ($folder in $buildFolders) {
        $folderSize = Get-FolderSize $folder.FullName
        Write-DiagnosticLog "Найдена папка сборки: $($folder.Name) ($folderSize MB)" "SUCCESS" $ColorSuccess
        
        # Поиск исполняемых файлов
        $exeFiles = Get-ChildItem -Path $folder.FullName -Filter "*.exe" -Recurse
        foreach ($exe in $exeFiles) {
            Write-DiagnosticLog "  Исполняемый файл: $($exe.Name)" "SUCCESS" $ColorSuccess
        }
    }
} else {
    Write-DiagnosticLog "ВНИМАНИЕ: Папки сборки не найдены" "WARNING" $ColorWarning
}

# Поиск архивов
$archives = Get-ChildItem -Path "." -File | Where-Object { $_.Extension -in @(".zip", ".tar.gz") }
if ($archives) {
    foreach ($archive in $archives) {
        $archiveSize = [math]::Round($archive.Length / 1MB, 2)
        Write-DiagnosticLog "Найден архив: $($archive.Name) ($archiveSize MB)" "SUCCESS" $ColorSuccess
    }
}

# Финальная диагностика
Write-DiagnosticLog "Этап 9: Финальная диагностика" "STEP" $ColorStep

$totalSize = Get-FolderSize "."
Write-DiagnosticLog "Общий размер проекта: $totalSize MB" "INFO" $ColorInfo

$processes = Get-BuildProcesses
if ($processes) {
    Write-DiagnosticLog "Активные процессы сборки:" "INFO" $ColorInfo
    foreach ($proc in $processes) {
        Write-DiagnosticLog "  $($proc.ProcessName) (PID: $($proc.Id))" "INFO" $ColorInfo
    }
} else {
    Write-DiagnosticLog "Активных процессов сборки не найдено" "INFO" $ColorInfo
}

Write-DiagnosticLog "=== ДИАГНОСТИЧЕСКАЯ СБОРКА RESEARCHERRY ЗАВЕРШЕНА ===" "END" $ColorStep
Write-DiagnosticLog "Лог сохранен в файл: build-diagnostic.log" "INFO" $ColorInfo

# Показать итоговую статистику
Write-Host "`n=== ИТОГОВАЯ СТАТИСТИКА ===" -ForegroundColor $ColorStep
Write-Host "Время выполнения: $((Get-Date) - $scriptStartTime)" -ForegroundColor $ColorInfo
Write-Host "Размер проекта: $totalSize MB" -ForegroundColor $ColorInfo
Write-Host "Лог файл: build-diagnostic.log" -ForegroundColor $ColorInfo
Write-Host "=========================" -ForegroundColor $ColorStep
