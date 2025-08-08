# Руководство по диагностической сборке Researcherry

## Созданные скрипты

### 1. `build-researcherry-diagnostic.ps1` - Основной скрипт пошаговой сборки
Полный скрипт сборки с детальной диагностикой каждого этапа.

**Использование:**
```powershell
# Полная сборка с диагностикой
powershell -ExecutionPolicy ByPass -File .\build-researcherry-diagnostic.ps1

# Сборка с подробным выводом
powershell -ExecutionPolicy ByPass -File .\build-researcherry-diagnostic.ps1 -Verbose

# Пропустить очистку (если нужно продолжить прерванную сборку)
powershell -ExecutionPolicy ByPass -File .\build-researcherry-diagnostic.ps1 -SkipClean

# Пропустить загрузку исходников (если уже загружены)
powershell -ExecutionPolicy ByPass -File .\build-researcherry-diagnostic.ps1 -SkipDownload

# Только применить патчи и собрать (без загрузки)
powershell -ExecutionPolicy ByPass -File .\build-researcherry-diagnostic.ps1 -SkipDownload -SkipClean
```

**Параметры:**
- `-SkipClean` - пропустить очистку предыдущих артефактов
- `-SkipDownload` - пропустить загрузку исходного кода VSCode
- `-SkipPatch` - пропустить применение патчей Researcherry
- `-SkipBuild` - пропустить финальную сборку
- `-Verbose` - подробный вывод всех операций

### 2. `check-build-status.ps1` - Быстрая проверка статуса
Скрипт для быстрой проверки текущего состояния сборки.

**Использование:**
```powershell
powershell -ExecutionPolicy ByPass -File .\check-build-status.ps1
```

## Этапы сборки

### Этап 1: Проверка системных требований
- ✅ Проверка Node.js (версия из .nvmrc)
- ✅ Проверка Python
- ✅ Проверка Git Bash
- ✅ Проверка свободного места на диске

### Этап 2: Установка переменных окружения
- `APP_NAME="Researcherry"`
- `BINARY_NAME="researcherry"`
- `VSCODE_QUALITY="stable"`

### Этап 3: Очистка артефактов
- Удаление папок: `vscode`, `src`, `node_modules`, `VSCode-*`
- Удаление архивов: `*.tar.gz`, `*.zip`

### Этап 4: Загрузка исходного кода
- Выполнение `get_repo.sh`
- Проверка размера и количества файлов

### Этап 5: Применение патчей
- Выполнение `prepare-researcherry.sh`
- Создание папки `src` с кастомизированным кодом
- Настройка `product.json` для Researcherry

### Этап 6: Установка зависимостей
- `npm install` в папке `vscode`
- Проверка создания `node_modules`

### Этап 7: Сборка приложения
- `npm run compile` - компиляция TypeScript
- `npm run gulp -- vscode-win32-x64` - упаковка для Windows

### Этап 8: Проверка результатов
- Поиск готовых сборок
- Поиск исполняемых файлов
- Поиск архивов

## Логирование

Все операции записываются в файл `build-diagnostic.log` с временными метками:
```
[2025-08-05 11:46:13] [INFO] Node.js версия: v22.17.1
[2025-08-05 11:46:14] [SUCCESS] Git Bash найден: C:\Program Files\Git\bin\bash.exe
[2025-08-05 11:46:15] [STEP] Этап 3: Очистка предыдущих артефактов
```

## Диагностика проблем

### Частые ошибки и решения:

1. **Node.js версия не соответствует**
   - Установите версию из `.nvmrc` или используйте флаг `VSCODE_SKIP_NODE_VERSION_CHECK`

2. **Git Bash не найден**
   - Установите Git for Windows
   - Проверьте путь: `C:\Program Files\Git\bin\bash.exe`

3. **Недостаточно места на диске**
   - Освободите минимум 10 GB
   - Сборка VSCode требует много места

4. **Ошибки сети при загрузке**
   - Проверьте интернет-соединение
   - Используйте `-SkipDownload` если исходники уже загружены

5. **Процесс завис**
   - Завершите зависшие процессы
   - Используйте `check-build-status.ps1` для диагностики

## Мониторинг процесса

Во время сборки можно отслеживать:
- Размер папок (`vscode`, `src`, `node_modules`)
- Активные процессы (node, npm, git, bash)
- Содержимое лог-файла `build-diagnostic.log`

## Результаты сборки

Успешная сборка создаст:
- 📁 `VSCode-win32-x64/` - готовое приложение
- 📄 `researcherry.exe` - исполняемый файл
- 📦 `*.zip` - архив для распространения

## Время выполнения

Ориентировочное время сборки:
- **Загрузка исходников**: 5-15 минут
- **Установка зависимостей**: 10-30 минут  
- **Компиляция и сборка**: 20-60 минут
- **Общее время**: 35-105 минут

*Время зависит от скорости интернета и мощности системы*
