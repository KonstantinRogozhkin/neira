param()
$ErrorActionPreference = 'Stop'

$pngPath = Join-Path $PSScriptRoot '..\icons\Neira\panel_dark.png'
$stableSvg = Join-Path $PSScriptRoot '..\src\stable\src\vs\workbench\browser\media\code-icon.svg'
$insiderSvg = Join-Path $PSScriptRoot '..\src\insider\src\vs\workbench\browser\media\code-icon.svg'

if (-not (Test-Path $pngPath)) { throw "PNG not found: $pngPath" }

$base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($pngPath))

$update = {
  param($path,$b64)
  if (-not (Test-Path $path)) { throw "SVG not found: $path" }
  $content = Get-Content -Raw -Path $path
  $content = $content -replace 'REPLACE_BASE64', [Regex]::Escape($b64).Replace('\\+','+')
  Set-Content -Encoding UTF8 -Path $path -Value $content
}

& $update $stableSvg $base64
& $update $insiderSvg $base64

Write-Host 'Embedded panel_dark.png into code-icon.svg (stable/insider)' 