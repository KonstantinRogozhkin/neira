# Build Status Check for Researcherry
# Usage: powershell -ExecutionPolicy ByPass -File .\status-check.ps1

function Get-FolderSize {
    param([string]$Path)
    if (Test-Path $Path) {
        $size = (Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        return [math]::Round($size / 1MB, 2)
    }
    return 0
}

Write-Host "=== RESEARCHERRY BUILD STATUS CHECK ===" -ForegroundColor Cyan

# Check main folders
$folders = @(
    @{Name="vscode"; Description="VSCode Source"},
    @{Name="src"; Description="Custom Code"},
    @{Name="vscode/node_modules"; Description="Dependencies"}
)

Write-Host "`n--- FOLDERS ---" -ForegroundColor Yellow
foreach ($folder in $folders) {
    if (Test-Path $folder.Name) {
        $size = Get-FolderSize $folder.Name
        $fileCount = (Get-ChildItem -Path $folder.Name -Recurse -File -ErrorAction SilentlyContinue).Count
        Write-Host "[OK] $($folder.Description): $size MB, $fileCount files" -ForegroundColor Green
    } else {
        Write-Host "[MISSING] $($folder.Description): not found" -ForegroundColor Red
    }
}

# Check for build outputs
Write-Host "`n--- BUILD OUTPUTS ---" -ForegroundColor Yellow
$buildFolders = Get-ChildItem -Path "." -Directory -ErrorAction SilentlyContinue | Where-Object { 
    $_.Name -like "*VSCode*" -or $_.Name -like "*Researcherry*" -or $_.Name -like "*win32*"
}

if ($buildFolders) {
    foreach ($folder in $buildFolders) {
        $size = Get-FolderSize $folder.FullName
        Write-Host "[OK] Build folder: $($folder.Name) ($size MB)" -ForegroundColor Green
        
        $exeFiles = Get-ChildItem -Path $folder.FullName -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue
        foreach ($exe in $exeFiles) {
            Write-Host "   EXE: $($exe.Name)" -ForegroundColor Cyan
        }
    }
} else {
    Write-Host "[MISSING] No build folders found" -ForegroundColor Red
}

# Check archives
Write-Host "`n--- ARCHIVES ---" -ForegroundColor Yellow
$archives = Get-ChildItem -Path "." -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in @(".zip", ".tar.gz") }
if ($archives) {
    foreach ($archive in $archives) {
        $size = [math]::Round($archive.Length / 1MB, 2)
        Write-Host "[OK] Archive: $($archive.Name) ($size MB)" -ForegroundColor Green
    }
} else {
    Write-Host "[MISSING] No archives found" -ForegroundColor Red
}

# Check active processes
Write-Host "`n--- ACTIVE PROCESSES ---" -ForegroundColor Yellow
$processes = Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -like "*node*" -or 
    $_.ProcessName -like "*npm*" -or 
    $_.ProcessName -like "*git*" -or 
    $_.ProcessName -like "*bash*"
}

if ($processes) {
    foreach ($proc in $processes) {
        Write-Host "[RUNNING] $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Yellow
    }
} else {
    Write-Host "[OK] No active build processes" -ForegroundColor Green
}

# General stats
Write-Host "`n--- STATISTICS ---" -ForegroundColor Yellow
$totalSize = Get-FolderSize "."
Write-Host "Total project size: $totalSize MB" -ForegroundColor Cyan

$freeSpace = [math]::Round((Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace / 1GB, 2)
Write-Host "Free disk space: $freeSpace GB" -ForegroundColor Cyan

Write-Host "`n=== STATUS CHECK COMPLETE ===" -ForegroundColor Cyan
