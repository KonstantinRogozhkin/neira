# Скрипт для сборки VSCodium с именем "Researcherry"
# powershell -ExecutionPolicy ByPass -File .\build-researcherry.ps1

# Устанавливаем переменные окружения для Researcherry
$env:APP_NAME = "Researcherry"
$env:APP_NAME_LC = "researcherry"
$env:BINARY_NAME = "researcherry"
$env:GH_REPO_PATH = "VSCodium/vscodium"
$env:ORG_NAME = "Researcherry"
$env:ASSETS_REPOSITORY = "VSCodium/vscodium"
$env:CI_BUILD = "no"
$env:SHOULD_BUILD = "yes"
$env:SKIP_ASSETS = "yes"
$env:SKIP_BUILD = "no"
$env:SKIP_SOURCE = "no"
$env:VSCODE_LATEST = "no"
$env:VSCODE_QUALITY = "stable"
$env:VSCODE_SKIP_NODE_VERSION_CHECK = "yes"

# Устанавливаем путь к Git bash
$env:Path = "C:\Program Files\Git\bin;" + $env:Path

# Запускаем сборку через bash
bash ./dev/build-researcherry.sh 