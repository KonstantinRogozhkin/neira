#!/usr/bin/env bash
# Скрипт для тестирования переменных окружения Researcherry

echo "=== Тестирование переменных окружения ==="

# Устанавливаем переменные окружения для Researcherry
export APP_NAME="Researcherry"
export APP_NAME_LC="researcherry"
export BINARY_NAME="researcherry"
export GH_REPO_PATH="VSCodium/vscodium"
export ORG_NAME="Researcherry"
export ASSETS_REPOSITORY="VSCodium/vscodium"

echo "APP_NAME=\"${APP_NAME}\""
echo "APP_NAME_LC=\"${APP_NAME_LC}\""
echo "BINARY_NAME=\"${BINARY_NAME}\""
echo "ORG_NAME=\"${ORG_NAME}\""

echo ""
echo "=== Тестирование замены в патчах ==="

# Создаем тестовый файл
echo "VSCodium" > test_file.txt
echo "codium" >> test_file.txt
echo "vscodium" >> test_file.txt

echo "Исходный файл:"
cat test_file.txt

echo ""
echo "После замены:"
sed 's|VSCodium|!!APP_NAME!!|g' test_file.txt | sed 's|codium|!!BINARY_NAME!!|g' | sed 's|vscodium|!!APP_NAME_LC!!|g'

echo ""
echo "=== Проверка патчей ==="
ls -la patches/user/

echo ""
echo "=== Готово ===" 