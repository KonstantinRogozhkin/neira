param()
$ErrorActionPreference = 'SilentlyContinue'

# Stop running processes
Get-Process -Name Neira,VSCodium,Code -ErrorAction SilentlyContinue | Stop-Process -Force

$paths = @(
  Join-Path $env:APPDATA 'Neira',
  Join-Path $env:LOCALAPPDATA 'Neira',
  Join-Path $env:APPDATA 'VSCodium',
  Join-Path $env:LOCALAPPDATA 'VSCodium',
  Join-Path $env:APPDATA 'Code',
  Join-Path $env:LOCALAPPDATA 'Code',
  (Join-Path $env:APPDATA 'Code - OSS'),
  (Join-Path $env:LOCALAPPDATA 'Code - OSS'),
  (Join-Path $env:USERPROFILE '.vscode'),
  (Join-Path $env:USERPROFILE '.vscode-oss')
)

foreach ($p in $paths) {
  if ([string]::IsNullOrWhiteSpace($p)) { continue }
  if (Test-Path -LiteralPath $p) {
    try {
      Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction Stop
      Write-Host "Removed: $p"
    } catch {
      Write-Host "Failed:  $p -> $($_.Exception.Message)"
    }
  } else {
    Write-Host "NotFound: $p"
  }
} 