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

# Установка зависимостей (минимально как в Researcherry)
export ELECTRON_SKIP_BINARY_DOWNLOAD=1
export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
export VSCODE_SKIP_NODE_VERSION_CHECK=1

mv .npmrc .npmrc.bak 2>/dev/null || true
cp ../npmrc .npmrc

for i in {1..3}; do
  if npm ci; then
    break
  fi
  echo "npm ci failed ($i), retrying..."
  sleep $(( 5 * i ))
  if [[ $i == 3 ]]; then
    echo "Npm install failed too many times" >&2
    exit 1
  fi
done

mv .npmrc.bak .npmrc 2>/dev/null || true

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

# Заменяем логотип на welcome-странице на Neira
# В CSS используется '../../../../browser/media/code-icon.svg' — заменим его на наш логотип
if [[ -f ../icons/Neira/logo_neira_white_full.svg ]]; then
  mkdir -p src/vs/workbench/browser/media
  cp -f src/vs/workbench/browser/media/code-icon.svg src/vs/workbench/browser/media/code-icon.svg.bak 2>/dev/null || true
  cp -f ../icons/Neira/logo_neira_white_full.svg src/vs/workbench/browser/media/code-icon.svg
fi

# Предустанавливаем расширение из VSIX как built-in
NEIRA_VSIX_ABS="$(cd .. && pwd)/dev/neira-coder-3.31.21.vsix"
if [[ -f "${NEIRA_VSIX_ABS}" ]]; then
  mkdir -p .build/builtInExtensions/neira-coder
  # Скопируем vsix внутрь папки расширения
  cp -f "${NEIRA_VSIX_ABS}" .build/builtInExtensions/neira-coder/neira-coder.vsix
  # Вычислим sha256
  NEIRA_VSIX_SHA=$(node -e "const fs=require('fs'),crypto=require('crypto'); const b=fs.readFileSync('.build/builtInExtensions/neira-coder/neira-coder.vsix'); console.log(crypto.createHash('sha256').update(b).digest('hex'));")
  # Пропишем в product.builtInExtensions запись с vsix и sha256
  jq --arg sha "$NEIRA_VSIX_SHA" '.builtInExtensions = (.builtInExtensions // []) | .builtInExtensions += [{"name":"neira-coder","vsix":".build/builtInExtensions/neira-coder/neira-coder.vsix","sha256":$sha}]' product.json > product.json.tmp && mv product.json.tmp product.json
fi

echo "=== DEBUG: Финальный product.json ==="
cat product.json

cd .. 