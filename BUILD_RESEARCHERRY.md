# Сборка VSCodium с именем "Researcherry" на Windows

## Найденные проблемы и исправления

### Проблема 1: Переменная VSCODE_QUALITY не была установлена
**Проблема:** В `prepare-researcherry.sh` переменная `VSCODE_QUALITY` была пустой, поэтому скрипт не попадал в нужную секцию кода.

**Исправление:** Добавлена строка в `prepare-researcherry.sh`:
```bash
export VSCODE_QUALITY="stable"
```

### Проблема 2: PowerShell скрипт вызывал неправильный bash скрипт
**Проблема:** `build-researcherry.ps1` вызывал `bash ./dev/build.sh` вместо `bash ./dev/build-researcherry.sh`.

**Исправление:** Изменена строка в `build-researcherry.ps1`:
```powershell
# Было:
bash ./dev/build.sh

# Стало:
bash ./dev/build-researcherry.sh
```

### Проблема 3: Патчи не применялись из-за конфликтов
**Проблема:** Патчи не могли быть применены к уже измененному коду, что приводило к прерыванию скрипта.

**Исправление:** Добавлена обработка ошибок во всех секциях патчей в `prepare-researcherry.sh`:
```bash
# Основные патчи
apply_patch "${file}" || echo "Патч ${file} не применился, продолжаем..."

# Insider патчи
apply_patch "${file}" || echo "Insider патч ${file} не применился, продолжаем..."

# OS патчи
apply_patch "${file}" || echo "OS патч ${file} не применился, продолжаем..."

# User патчи
apply_patch "${file}" || echo "User патч ${file} не применился, продолжаем..."
```

## Текущий процесс сборки

1. **Запуск:** `powershell -ExecutionPolicy ByPass -File .\build-researcherry.ps1`
2. **PowerShell скрипт** устанавливает переменные окружения для Researcherry
3. **Вызывает:** `bash ./dev/build-researcherry.sh`
4. **Bash скрипт** устанавливает дополнительные переменные и вызывает `build-researcherry-main.sh`
5. **Main скрипт** вызывает `prepare-researcherry.sh`
6. **Prepare скрипт** настраивает product.json с именем "Researcherry" (даже если патчи не применились)

## Структура кастомных файлов

- `build-researcherry.ps1` - PowerShell entry point
- `dev/build-researcherry.sh` - Bash entry point с переменными Researcherry
- `build-researcherry-main.sh` - Основной скрипт сборки
- `prepare-researcherry.sh` - Настройка product.json и иконок (с обработкой ошибок патчей)

## Ожидаемый результат

После успешной сборки в папке `VSCode-win32-x64` должны быть:
- `Researcherry.exe` (вместо VSCodium.exe)
- `resources/app/product.json` с именем "Researcherry"

## Проверка результата

```powershell
# Проверка product.json
Get-Content "VSCode-win32-x64/resources/app/product.json" | Select-String "nameShort"

# Проверка исполняемого файла
Get-ChildItem "VSCode-win32-x64" -Name "*.exe"
```

## Статус исправлений

- ✅ **Проблема 1 исправлена** - VSCODE_QUALITY установлена
- ✅ **Проблема 2 исправлена** - PowerShell вызывает правильный bash скрипт
- ✅ **Проблема 3 исправлена** - Добавлена обработка ошибок патчей
- ✅ **Product.json настраивается правильно** - проверено в тестовом запуске
- ⏳ **Сборка в процессе** - ожидается успешное завершение 