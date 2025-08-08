#!/usr/bin/env bash
# Скрипт для сборки VSCodium с именем "Researcherry"

# Устанавливаем переменные окружения для Researcherry
export APP_NAME="Researcherry"
export APP_NAME_LC="researcherry"
export BINARY_NAME="researcherry"
export GH_REPO_PATH="VSCodium/vscodium"
export ORG_NAME="Researcherry"
export ASSETS_REPOSITORY="VSCodium/vscodium"
export CI_BUILD="no"
export SHOULD_BUILD="yes"
export SKIP_ASSETS="yes"
export SKIP_BUILD="no"
export SKIP_SOURCE="no"
export VSCODE_LATEST="no"
export VSCODE_QUALITY="stable"
export VSCODE_SKIP_NODE_VERSION_CHECK="yes"

echo "Building Researcherry with custom branding..."
echo "APP_NAME=\"${APP_NAME}\""
echo "BINARY_NAME=\"${BINARY_NAME}\""
echo "ORG_NAME=\"${ORG_NAME}\""

# Создаем папку для ресурсов Researcherry
mkdir -p "src/researcherry/resources"

# Определяем ОС
case "${OSTYPE}" in
  darwin*)
    export OS_NAME="osx"
    ;;
  msys* | cygwin*)
    export OS_NAME="windows"
    ;;
  *)
    export OS_NAME="linux"
    ;;
esac

# Определяем архитектуру
UNAME_ARCH=$( uname -m )

if [[ "${UNAME_ARCH}" == "aarch64" || "${UNAME_ARCH}" == "arm64" ]]; then
  export VSCODE_ARCH="arm64"
elif [[ "${UNAME_ARCH}" == "ppc64le" ]]; then
  export VSCODE_ARCH="ppc64le"
elif [[ "${UNAME_ARCH}" == "riscv64" ]]; then
  export VSCODE_ARCH="riscv64"
elif [[ "${UNAME_ARCH}" == "loongarch64" ]]; then
  export VSCODE_ARCH="loong64"
elif [[ "${UNAME_ARCH}" == "s390x" ]]; then
  export VSCODE_ARCH="s390x"
else
  export VSCODE_ARCH="x64"
fi

export NODE_OPTIONS="--max-old-space-size=8192"

echo "Building Researcherry..."
echo "OS_NAME=\"${OS_NAME}\""
echo "VSCODE_ARCH=\"${VSCODE_ARCH}\""
echo "APP_NAME=\"${APP_NAME}\""
echo "BINARY_NAME=\"${BINARY_NAME}\""

# Запускаем кастомный скрипт сборки
./dev/build-researcherry.sh 