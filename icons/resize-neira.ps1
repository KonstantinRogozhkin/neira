param()
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

function Resize-Png {
  param(
    [Parameter(Mandatory=$true)][string]$SourcePath,
    [Parameter(Mandatory=$true)][string]$DestinationPath,
    [Parameter(Mandatory=$true)][int]$Width,
    [Parameter(Mandatory=$true)][int]$Height
  )
  if (-not (Test-Path $SourcePath)) {
    throw "Source not found: $SourcePath"
  }
  $sourceImage = [System.Drawing.Image]::FromFile($SourcePath)
  try {
    $bitmap = New-Object System.Drawing.Bitmap $Width, $Height
    try {
      $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
      try {
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.DrawImage($sourceImage, 0, 0, $Width, $Height)
        $destDir = [System.IO.Path]::GetDirectoryName($DestinationPath)
        if ($destDir -and -not (Test-Path $destDir)) {
          New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        $bitmap.Save($DestinationPath, [System.Drawing.Imaging.ImageFormat]::Png)
      } finally {
        $graphics.Dispose()
      }
    } finally {
      $bitmap.Dispose()
    }
  } finally {
    $sourceImage.Dispose()
  }
}

$src = Join-Path $PSScriptRoot 'Neira\neira-512.png'

# Linux app icon (already 512, but ensure overwrite)
Resize-Png -SourcePath $src -DestinationPath (Resolve-Path "$PSScriptRoot\..\src\insider\resources\linux\code.png").Path -Width 512 -Height 512
Resize-Png -SourcePath $src -DestinationPath (Resolve-Path "$PSScriptRoot\..\src\stable\resources\linux\code.png").Path -Width 512 -Height 512

# Server icons
Resize-Png -SourcePath $src -DestinationPath (Resolve-Path "$PSScriptRoot\..\src\insider\resources\server\code-512.png").Path -Width 512 -Height 512
Resize-Png -SourcePath $src -DestinationPath (Resolve-Path "$PSScriptRoot\..\src\insider\resources\server\code-192.png").Path -Width 192 -Height 192
Resize-Png -SourcePath $src -DestinationPath (Resolve-Path "$PSScriptRoot\..\src\stable\resources\server\code-512.png").Path -Width 512 -Height 512
Resize-Png -SourcePath $src -DestinationPath (Resolve-Path "$PSScriptRoot\..\src\stable\resources\server\code-192.png").Path -Width 192 -Height 192

# Windows tiles
Resize-Png -SourcePath $src -DestinationPath (Resolve-Path "$PSScriptRoot\..\src\insider\resources\win32\code_150x150.png").Path -Width 150 -Height 150
Resize-Png -SourcePath $src -DestinationPath (Resolve-Path "$PSScriptRoot\..\src\insider\resources\win32\code_70x70.png").Path -Width 70 -Height 70
Resize-Png -SourcePath $src -DestinationPath (Resolve-Path "$PSScriptRoot\..\src\stable\resources\win32\code_150x150.png").Path -Width 150 -Height 150
Resize-Png -SourcePath $src -DestinationPath (Resolve-Path "$PSScriptRoot\..\src\stable\resources\win32\code_70x70.png").Path -Width 70 -Height 70

Write-Host 'Resizing completed.' 