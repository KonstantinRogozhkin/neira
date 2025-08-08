# Скрипт для проверки результата сборки Researcherry
# powershell -ExecutionPolicy ByPass -File .\check-result.ps1

Write-Host "=== Проверка результата сборки Researcherry ===" -ForegroundColor Green

# Проверяем наличие папки сборки
$buildFolder = "VSCode-win32-x64"
if (Test-Path $buildFolder) {
    Write-Host "✅ Папка сборки найдена: $buildFolder" -ForegroundColor Green
    
    # Проверяем исполняемый файл
    $exeFile = Get-ChildItem -Path $buildFolder -Name "*.exe" | Select-Object -First 1
    if ($exeFile) {
        Write-Host "📁 Исполняемый файл: $exeFile" -ForegroundColor Yellow
        
        if ($exeFile -eq "Researcherry.exe") {
            Write-Host "✅ УСПЕХ! Файл переименован в Researcherry.exe" -ForegroundColor Green
        } else {
            Write-Host "❌ Файл все еще называется: $exeFile" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Исполняемый файл не найден" -ForegroundColor Red
    }
    
    # Проверяем product.json
    $productJson = "$buildFolder\resources\app\product.json"
    if (Test-Path $productJson) {
        Write-Host "📄 Product.json найден" -ForegroundColor Yellow
        
        $content = Get-Content $productJson -Raw
        if ($content -match '"nameShort":\s*"Researcherry"') {
            Write-Host "✅ УСПЕХ! Product.json содержит имя 'Researcherry'" -ForegroundColor Green
        } else {
            Write-Host "❌ Product.json не содержит правильное имя" -ForegroundColor Red
            Write-Host "Найденное значение:" -ForegroundColor Yellow
            $content | Select-String '"nameShort"' | Write-Host
        }
    } else {
        Write-Host "❌ Product.json не найден" -ForegroundColor Red
    }
    
} else {
    Write-Host "❌ Папка сборки не найдена: $buildFolder" -ForegroundColor Red
    Write-Host "Возможные причины:" -ForegroundColor Yellow
    Write-Host "- Сборка еще не завершена" -ForegroundColor Yellow
    Write-Host "- Произошла ошибка во время сборки" -ForegroundColor Yellow
    Write-Host "- Папка находится в другом месте" -ForegroundColor Yellow
    
    # Проверяем другие возможные папки
    $otherFolders = Get-ChildItem -Path "." -Name "VSCode*" -ErrorAction SilentlyContinue
    if ($otherFolders) {
        Write-Host "Найдены другие папки сборки:" -ForegroundColor Yellow
        $otherFolders | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }
}

Write-Host "`n=== Проверка завершена ===" -ForegroundColor Green 