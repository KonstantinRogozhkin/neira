#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2154

set -e

# include common functions
. ./utils.sh

# Переменные бренда Neira (минимально достаточно для быстрого переименования)
export APP_NAME="Neira"
export APP_NAME_LC="neira"
export BINARY_NAME="neira"
export GH_REPO_PATH="VSCodium/vscodium"
export ORG_NAME="Neira"
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

# Простая функция setpath через jq
setpath() {
  local jsonTmp
  jsonTmp=$( jq --arg 'path' "${2}" --arg 'value' "${3}" 'setpath([$path]; $value)' "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
}

# product.json
cp product.json{,.bak}

echo "=== DEBUG: Настройка имен для VSCODE_QUALITY=${VSCODE_QUALITY} ==="
if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  setpath "product" "nameShort" "Neira - Insiders"
  setpath "product" "nameLong" "Neira - Insiders"
  setpath "product" "applicationName" "neira-insiders"
  setpath "product" "linuxIconName" "neira-insiders"
  setpath "product" "win32ShellNameShort" "Neira Insiders"
else
  setpath "product" "nameShort" "Neira"
  setpath "product" "nameLong" "Neira"
  setpath "product" "applicationName" "neira"
  setpath "product" "linuxIconName" "neira"
  setpath "product" "win32ShellNameShort" "Neira"
fi

echo "=== DEBUG: Финальный product.json ==="
cat product.json

cd .. 