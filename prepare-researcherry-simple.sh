#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2154

set -e

# include common functions
. ./utils.sh

# Устанавливаем переменные для Researcherry
export APP_NAME="Researcherry"
export APP_NAME_LC="researcherry"
export BINARY_NAME="researcherry"
export GH_REPO_PATH="VSCodium/vscodium"
export ORG_NAME="Researcherry"
export ASSETS_REPOSITORY="VSCodium/vscodium"
export VSCODE_QUALITY="stable"

echo "=== DEBUG: Переменные окружения ==="
echo "APP_NAME=\"${APP_NAME}\""
echo "APP_NAME_LC=\"${APP_NAME_LC}\""
echo "BINARY_NAME=\"${BINARY_NAME}\""
echo "ORG_NAME=\"${ORG_NAME}\""
echo "VSCODE_QUALITY=\"${VSCODE_QUALITY}\""

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  cp -rp src/insider/* vscode/
else
  cp -rp src/stable/* vscode/
fi

cp -f LICENSE vscode/LICENSE.txt

cd vscode || { echo "'vscode' dir not found"; exit 1; }

echo "=== DEBUG: Начинаем настройку product.json ==="

# Создаем функцию setpath
setpath() {
  local jsonTmp
  echo "=== DEBUG: setpath $1 $2 $3 ==="
  jsonTmp=$( jq --arg 'path' "${2}" --arg 'value' "${3}" 'setpath([$path]; $value)' "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
  echo "=== DEBUG: setpath завершен ==="
}

setpath_json() {
  local jsonTmp
  jsonTmp=$( jq --arg 'path' "${2}" --argjson 'value' "${3}" 'setpath([$path]; $value)' "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
}

# product.json
cp product.json{,.bak}

echo "=== DEBUG: Настройка имен для VSCODE_QUALITY=${VSCODE_QUALITY} ==="

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  echo "=== DEBUG: Настройка insider ==="
  setpath "product" "nameShort" "Researcherry - Insiders"
  setpath "product" "nameLong" "Researcherry - Insiders"
  setpath "product" "applicationName" "researcherry-insiders"
  setpath "product" "win32ShellNameShort" "Researcherry Insiders"
else
  echo "=== DEBUG: Настройка stable ==="
  setpath "product" "nameShort" "Researcherry"
  setpath "product" "nameLong" "Researcherry"
  setpath "product" "applicationName" "researcherry"
  setpath "product" "win32ShellNameShort" "Researcherry"
fi

echo "=== DEBUG: Финальный product.json ==="
cat product.json

cd .. 