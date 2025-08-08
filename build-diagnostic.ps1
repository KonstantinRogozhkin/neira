# Researcherry Diagnostic Build Script
# Usage: powershell -ExecutionPolicy ByPass -File .\build-diagnostic.ps1

param(
    [switch]$SkipClean = $false,
    [switch]$SkipDownload = $false,
    [switch]$SkipPatch = $false,
    [switch]$SkipBuild = $false,
    [switch]$Verbose = $false
)

$scriptStartTime = Get-Date

function Write-Log {
    param([string]$Message, [string]$Level = "INFO", [string]$Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $Color
    "$timestamp [$Level] $Message" | Out-File -FilePath "build-diagnostic.log" -Append -Encoding UTF8
}

function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Get-FolderSize {
    param([string]$Path)
    if (Test-Path $Path) {
        $size = (Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        return [math]::Round($size / 1MB, 2)
    }
    return 0
}

Write-Log "=== RESEARCHERRY DIAGNOSTIC BUILD START ===" "START" "Magenta"

# Step 1: System Requirements Check
Write-Log "Step 1: Checking system requirements" "STEP" "Cyan"

# Check Node.js
if (Test-Command "node") {
    $nodeVersion = node --version
    Write-Log "Node.js version: $nodeVersion" "INFO" "Green"
    
    $requiredVersion = Get-Content ".nvmrc" -ErrorAction SilentlyContinue
    if ($requiredVersion) {
        $requiredVersion = $requiredVersion.Trim()
        if ($nodeVersion -ne "v$requiredVersion") {
            Write-Log "WARNING: Required Node.js v$requiredVersion, found $nodeVersion" "WARNING" "Yellow"
        } else {
            Write-Log "Node.js version matches requirements" "SUCCESS" "Green"
        }
    }
} else {
    Write-Log "ERROR: Node.js not found" "ERROR" "Red"
    exit 1
}

# Check Python
if (Test-Command "python") {
    $pythonVersion = python --version
    Write-Log "Python version: $pythonVersion" "INFO" "Green"
} else {
    Write-Log "WARNING: Python not found (may be needed for native modules)" "WARNING" "Yellow"
}

# Check Git Bash
$bashPath = "C:\Program Files\Git\bin\bash.exe"
if (Test-Path $bashPath) {
    Write-Log "Git Bash found: $bashPath" "SUCCESS" "Green"
} else {
    Write-Log "ERROR: Git Bash not found at $bashPath" "ERROR" "Red"
    exit 1
}

# Check disk space
$drive = (Get-Location).Drive
$freeSpace = [math]::Round((Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$($drive.Name)'").FreeSpace / 1GB, 2)
Write-Log "Free disk space on $($drive.Name): $freeSpace GB" "INFO" "Cyan"
if ($freeSpace -lt 10) {
    Write-Log "WARNING: Low disk space (recommended minimum 10 GB)" "WARNING" "Yellow"
}

# Step 2: Set Environment Variables
Write-Log "Step 2: Setting Researcherry environment variables" "STEP" "Cyan"

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

Write-Log "Environment variables set:" "INFO" "Cyan"
Write-Log "  APP_NAME: $env:APP_NAME" "INFO" "Cyan"
Write-Log "  BINARY_NAME: $env:BINARY_NAME" "INFO" "Cyan"
Write-Log "  VSCODE_QUALITY: $env:VSCODE_QUALITY" "INFO" "Cyan"

# Step 3: Clean Previous Artifacts
if (-not $SkipClean) {
    Write-Log "Step 3: Cleaning previous build artifacts" "STEP" "Cyan"
    
    $itemsToClean = @("vscode", "src", "node_modules", "VSCode-*", "*.tar.gz", "*.zip")
    foreach ($item in $itemsToClean) {
        if (Test-Path $item) {
            $size = Get-FolderSize $item
            Write-Log "Removing $item (size: $size MB)" "INFO" "Yellow"
            Remove-Item -Path $item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Log "Cleanup completed" "SUCCESS" "Green"
} else {
    Write-Log "Step 3: Skipping cleanup (SkipClean flag)" "SKIP" "Yellow"
}

# Step 4: Download VSCode Source
if (-not $SkipDownload) {
    Write-Log "Step 4: Downloading VSCode source code" "STEP" "Cyan"
    
    Write-Log "Running get_repo.sh..." "INFO" "Cyan"
    $startTime = Get-Date
    
    try {
        $output = & $bashPath ./get_repo.sh 2>&1
        if ($Verbose) {
            $output | ForEach-Object { Write-Log "get_repo: $_" "INFO" "White" }
        }
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMinutes
        Write-Log "Download completed in $([math]::Round($duration, 2)) minutes" "SUCCESS" "Green"
        
        if (Test-Path "vscode") {
            $vscodeFolderSize = Get-FolderSize "vscode"
            $fileCount = (Get-ChildItem -Path "vscode" -Recurse -File -ErrorAction SilentlyContinue).Count
            Write-Log "vscode folder created: $vscodeFolderSize MB, $fileCount files" "SUCCESS" "Green"
        } else {
            Write-Log "ERROR: vscode folder not created" "ERROR" "Red"
            exit 1
        }
    } catch {
        Write-Log "ERROR downloading source code: $($_.Exception.Message)" "ERROR" "Red"
        exit 1
    }
} else {
    Write-Log "Step 4: Skipping download (SkipDownload flag)" "SKIP" "Yellow"
}

# Step 5: Apply Researcherry Patches
if (-not $SkipPatch) {
    Write-Log "Step 5: Applying Researcherry patches" "STEP" "Cyan"
    
    Write-Log "Running prepare-researcherry.sh..." "INFO" "Cyan"
    $startTime = Get-Date
    
    try {
        $output = & $bashPath ./prepare-researcherry.sh 2>&1
        if ($Verbose) {
            $output | ForEach-Object { Write-Log "prepare: $_" "INFO" "White" }
        }
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMinutes
        Write-Log "Preparation completed in $([math]::Round($duration, 2)) minutes" "SUCCESS" "Green"
        
        if (Test-Path "src") {
            $srcFolderSize = Get-FolderSize "src"
            Write-Log "src folder created: $srcFolderSize MB" "SUCCESS" "Green"
        } else {
            Write-Log "WARNING: src folder not created" "WARNING" "Yellow"
        }
        
        if (Test-Path "vscode/product.json") {
            $productContent = Get-Content "vscode/product.json" -Raw
            if ($productContent -like "*Researcherry*") {
                Write-Log "product.json configured for Researcherry" "SUCCESS" "Green"
            } else {
                Write-Log "WARNING: product.json may not be configured for Researcherry" "WARNING" "Yellow"
            }
        }
    } catch {
        Write-Log "ERROR during preparation: $($_.Exception.Message)" "ERROR" "Red"
        Write-Log "Continuing execution..." "WARNING" "Yellow"
    }
} else {
    Write-Log "Step 5: Skipping patches (SkipPatch flag)" "SKIP" "Yellow"
}

# Step 6: Install Dependencies
Write-Log "Step 6: Installing Node.js dependencies" "STEP" "Cyan"

if (Test-Path "vscode") {
    Push-Location "vscode"
    
    Write-Log "Installing dependencies in vscode folder..." "INFO" "Cyan"
    $startTime = Get-Date
    
    try {
        $output = npm install 2>&1
        if ($Verbose) {
            $output | ForEach-Object { Write-Log "npm: $_" "INFO" "White" }
        }
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMinutes
        Write-Log "Dependencies installed in $([math]::Round($duration, 2)) minutes" "SUCCESS" "Green"
        
        if (Test-Path "node_modules") {
            $nodeModulesSize = Get-FolderSize "node_modules"
            Write-Log "node_modules created: $nodeModulesSize MB" "SUCCESS" "Green"
        } else {
            Write-Log "ERROR: node_modules not created" "ERROR" "Red"
            Pop-Location
            exit 1
        }
    } catch {
        Write-Log "ERROR installing dependencies: $($_.Exception.Message)" "ERROR" "Red"
        Pop-Location
        exit 1
    }
    
    Pop-Location
} else {
    Write-Log "ERROR: vscode folder not found" "ERROR" "Red"
    exit 1
}

# Step 7: Build Application
if (-not $SkipBuild) {
    Write-Log "Step 7: Building Researcherry application" "STEP" "Cyan"
    
    Push-Location "vscode"
    
    Write-Log "Starting build process..." "INFO" "Cyan"
    $startTime = Get-Date
    
    try {
        Write-Log "Running compilation..." "INFO" "Cyan"
        $output = npm run compile 2>&1
        if ($Verbose) {
            $output | ForEach-Object { Write-Log "compile: $_" "INFO" "White" }
        }
        
        Write-Log "Compilation completed, starting packaging..." "INFO" "Cyan"
        
        $output = npm run gulp -- vscode-win32-x64 2>&1
        if ($Verbose) {
            $output | ForEach-Object { Write-Log "gulp: $_" "INFO" "White" }
        }
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMinutes
        Write-Log "Build completed in $([math]::Round($duration, 2)) minutes" "SUCCESS" "Green"
        
    } catch {
        Write-Log "ERROR during build: $($_.Exception.Message)" "ERROR" "Red"
        Pop-Location
        exit 1
    }
    
    Pop-Location
} else {
    Write-Log "Step 7: Skipping build (SkipBuild flag)" "SKIP" "Yellow"
}

# Step 8: Verify Results
Write-Log "Step 8: Verifying build results" "STEP" "Cyan"

$buildFolders = Get-ChildItem -Path "." -Directory -ErrorAction SilentlyContinue | Where-Object { 
    $_.Name -like "*VSCode*" -or $_.Name -like "*Researcherry*" 
}

if ($buildFolders) {
    foreach ($folder in $buildFolders) {
        $folderSize = Get-FolderSize $folder.FullName
        Write-Log "Found build folder: $($folder.Name) ($folderSize MB)" "SUCCESS" "Green"
        
        $exeFiles = Get-ChildItem -Path $folder.FullName -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue
        foreach ($exe in $exeFiles) {
            Write-Log "  Executable: $($exe.Name)" "SUCCESS" "Green"
        }
    }
} else {
    Write-Log "WARNING: No build folders found" "WARNING" "Yellow"
}

$archives = Get-ChildItem -Path "." -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in @(".zip", ".tar.gz") }
if ($archives) {
    foreach ($archive in $archives) {
        $archiveSize = [math]::Round($archive.Length / 1MB, 2)
        Write-Log "Found archive: $($archive.Name) ($archiveSize MB)" "SUCCESS" "Green"
    }
}

# Final Statistics
Write-Log "Step 9: Final diagnostics" "STEP" "Cyan"

$totalSize = Get-FolderSize "."
Write-Log "Total project size: $totalSize MB" "INFO" "Cyan"

$totalTime = (Get-Date) - $scriptStartTime
Write-Log "Total execution time: $($totalTime.ToString('hh\:mm\:ss'))" "INFO" "Cyan"

Write-Log "=== RESEARCHERRY DIAGNOSTIC BUILD COMPLETE ===" "END" "Magenta"
Write-Log "Log saved to: build-diagnostic.log" "INFO" "Cyan"

Write-Host "`n=== FINAL SUMMARY ===" -ForegroundColor Magenta
Write-Host "Execution time: $($totalTime.ToString('hh\:mm\:ss'))" -ForegroundColor Cyan
Write-Host "Project size: $totalSize MB" -ForegroundColor Cyan
Write-Host "Log file: build-diagnostic.log" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Magenta
