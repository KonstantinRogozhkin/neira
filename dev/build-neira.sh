#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2129

### Windows
# to run with Bash: "C:\\Program Files\\Git\\bin\\bash.exe" ./dev/build-neira.sh
###

export APP_NAME="Neira"
export ASSETS_REPOSITORY="VSCodium/vscodium"
export BINARY_NAME="neira"
export CI_BUILD="no"
export GH_REPO_PATH="VSCodium/vscodium"
export ORG_NAME="Neira"
export SHOULD_BUILD="yes"
export SKIP_ASSETS="yes"
export SKIP_BUILD="no"
export SKIP_SOURCE="no"
export VSCODE_LATEST="no"
export VSCODE_QUALITY="stable"
export VSCODE_SKIP_NODE_VERSION_CHECK="yes"

while getopts ":ilops" opt; do
  case "$opt" in
    i)
      export ASSETS_REPOSITORY="VSCodium/vscodium-insiders"
      export BINARY_NAME="neira-insiders"
      export VSCODE_QUALITY="insider"
      ;;
    l)
      export VSCODE_LATEST="yes"
      ;;
    o)
      export SKIP_BUILD="yes"
      ;;
    p)
      export SKIP_ASSETS="no"
      ;;
    s)
      export SKIP_SOURCE="yes"
      ;;
    *)
      ;;
  esac
done

case "${OSTYPE}" in
  darwin*) export OS_NAME="osx" ;;
  msys*|cygwin*) export OS_NAME="windows" ;;
  *) export OS_NAME="linux" ;;
esac

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

echo "OS_NAME=\"${OS_NAME}\""
echo "SKIP_SOURCE=\"${SKIP_SOURCE}\""
echo "SKIP_BUILD=\"${SKIP_BUILD}\""
echo "SKIP_ASSETS=\"${SKIP_ASSETS}\""
echo "VSCODE_ARCH=\"${VSCODE_ARCH}\""
echo "VSCODE_LATEST=\"${VSCODE_LATEST}\""
echo "VSCODE_QUALITY=\"${VSCODE_QUALITY}\""

if [[ "${SKIP_SOURCE}" == "no" ]]; then
  rm -rf vscode* VSCode*
  . get_repo.sh
  . version.sh
  echo "MS_TAG=\"${MS_TAG}\"" > dev/build.env
  echo "MS_COMMIT=\"${MS_COMMIT}\"" >> dev/build.env
  echo "RELEASE_VERSION=\"${RELEASE_VERSION}\"" >> dev/build.env
  echo "BUILD_SOURCEVERSION=\"${BUILD_SOURCEVERSION}\"" >> dev/build.env
else
  if [[ "${SKIP_ASSETS}" != "no" ]]; then
    rm -rf vscode-* VSCode-*
  fi
  . dev/build.env
fi

if [[ "${SKIP_BUILD}" == "no" ]]; then
  if [[ "${SKIP_SOURCE}" != "no" ]]; then
    cd vscode || { echo "'vscode' dir not found"; exit 1; }
    git add .
    git reset -q --hard HEAD
    rm -rf .build out*
    cd ..
  fi
  . build-neira-main.sh
fi

if [[ "${SKIP_ASSETS}" == "no" ]]; then
  if [[ "${OS_NAME}" == "windows" ]]; then
    rm -rf build/windows/msi/releasedir
  fi
  . prepare_assets.sh
fi 