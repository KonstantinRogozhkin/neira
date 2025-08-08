# Иконки для Researcherry

Этот документ описывает, как создать и использовать кастомные иконки для приложения "Researcherry".

## Структура иконок

```
icons/
├── researcherry/
│   ├── researcherry_cnl.svg          # Основная иконка (нормальная)
│   ├── researcherry_clt.svg          # Светлая иконка
│   └── researcherry_cnl_w80_b8.svg   # Иконка с рамкой для Windows
├── build-researcherry-icons.sh       # Скрипт сборки иконок
└── RESEARCHERRY_ICONS.md             # Эта инструкция
```

## Создание иконок

### 1. Основная иконка (`researcherry_cnl.svg`)
- **Размер**: 100x100 пикселей
- **Цвет**: Оранжевый градиент (#FF6B35 → #CC4A1B)
- **Содержание**: Буква "R" в стиле VSCodium + декоративные элементы

### 2. Светлая иконка (`researcherry_clt.svg`)
- **Размер**: 100x100 пикселей
- **Цвет**: Светло-оранжевый градиент (#FF8A65 → #FF6B35)
- **Использование**: Для светлых тем

### 3. Иконка с рамкой (`researcherry_cnl_w80_b8.svg`)
- **Размер**: 100x100 пикселей
- **Особенности**: Белый фон с рамкой, иконка уменьшена до 80%
- **Использование**: Для Windows установщиков

## Сборка иконок

### Предварительные требования

Для сборки иконок нужны следующие программы:
- **ImageMagick** - для конвертации изображений
- **rsvg-convert** - для работы с SVG
- **png2icns** - для создания macOS иконок
- **icotool** - для работы с Windows иконками

### Установка зависимостей

#### Windows (через Chocolatey):
```powershell
choco install imagemagick
choco install librsvg
```

#### Windows (через Scoop):
```bash
scoop install imagemagick
scoop install librsvg
```

#### macOS:
```bash
brew install imagemagick
brew install librsvg
brew install png2icns
```

#### Linux (Ubuntu/Debian):
```bash
sudo apt-get install imagemagick librsvg2-bin
```

### Запуск сборки иконок

```bash
cd icons
chmod +x build-researcherry-icons.sh
./build-researcherry-icons.sh
```

## Что создается

После сборки в папке `src/researcherry/resources/` будут созданы:

### Windows
- `win32/code.ico` - основная иконка приложения
- `win32/code_70x70.png` - иконка 70x70
- `win32/code_150x150.png` - иконка 150x150
- `win32/inno-*.bmp` - иконки для установщика Inno Setup

### Linux
- `linux/code.png` - основная иконка
- `linux/rpm/code.xpm` - иконка для RPM пакетов

### macOS
- `darwin/code.icns` - иконка приложения

### Сервер
- `server/favicon.ico` - иконка для веб-интерфейса
- `server/code-192.png` - иконка 192x192
- `server/code-512.png` - иконка 512x512

### Медиа
- `src/vs/workbench/browser/media/code-icon.svg` - SVG иконка для веб-интерфейса

## Интеграция с основным процессом сборки

Иконки автоматически интегрируются в процесс сборки через скрипт `build-researcherry.sh`. 

### Порядок выполнения:

1. **Сборка иконок** - создаются все необходимые форматы
2. **Копирование ресурсов** - иконки копируются в нужные папки
3. **Сборка приложения** - VSCodium собирается с кастомными иконками

## Кастомизация иконок

### Изменение цвета

Отредактируйте градиент в SVG файлах:

```xml
<linearGradient id="Gradient_1" ...>
  <stop offset="0" stop-color="#ВАШ_ЦВЕТ_1"/>
  <stop offset="1" stop-color="#ВАШ_ЦВЕТ_2"/>
</linearGradient>
```

### Изменение символа

Замените path с буквой "R" на свой символ:

```xml
<path d="..." fill="url(#Gradient_1)"/>
```

### Добавление элементов

Добавьте дополнительные элементы в SVG:

```xml
<circle cx="70" cy="30" r="8" fill="url(#Gradient_1)" opacity="0.7"/>
<rect x="10" y="10" width="20" height="20" fill="url(#Gradient_1)"/>
```

## Проверка результата

После сборки проверьте:

1. **Windows**: Откройте `VSCode-win32-x64/Researcherry.exe` - должна быть ваша иконка
2. **Linux**: Проверьте иконку в меню приложений
3. **macOS**: Проверьте иконку в Dock

## Устранение неполадок

### Ошибка "command not found"
Убедитесь, что все зависимости установлены:
```bash
which convert
which rsvg-convert
which png2icns
```

### Ошибка "Permission denied"
```bash
chmod +x build-researcherry-icons.sh
```

### Иконки не отображаются
1. Очистите кэш иконок системы
2. Перезапустите проводник (Windows)
3. Обновите кэш иконок (Linux: `gtk-update-icon-cache`)

## Примеры иконок

### Простая буква
```xml
<text x="50" y="60" font-family="Arial" font-size="40" text-anchor="middle" fill="url(#Gradient_1)">R</text>
```

### Геометрическая фигура
```xml
<rect x="20" y="20" width="60" height="60" rx="10" fill="url(#Gradient_1)"/>
```

### Комбинированный дизайн
```xml
<circle cx="50" cy="50" r="40" fill="url(#Gradient_1)"/>
<text x="50" y="60" font-family="Arial" font-size="30" text-anchor="middle" fill="white">R</text>
``` 