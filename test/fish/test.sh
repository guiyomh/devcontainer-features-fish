#!/usr/bin/env bash

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

NON_ROOT_USER=""
POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
  if id -u ${CURRENT_USER} >/dev/null 2>&1; then
    NON_ROOT_USER=${CURRENT_USER}
    break
  fi
done
if [ "${NON_ROOT_USER}" = "" ]; then
  NON_ROOT_USER=root
fi

apt_get_update() {
  if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
    echo "Running apt-get update..."
    apt-get update -y
  fi
}

# Checks if packages are installed and installs them if not
check_packages() {
  if ! dpkg -s "$@" >/dev/null 2>&1; then
    apt_get_update
    apt-get -y install --no-install-recommends "$@"
  fi
}

check_packages git
LATEST_FISH_VERSION="$(git ls-remote --tags https://github.com/fish-shell/fish-shell | grep -oP "[0-9]+\\.[0-9]+\\.[0-9]+" | sort -V | tail -n 1)"

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "fish" fish -v | grep "$LATEST_FISH_VERSION"
echo "Testing with user: ${NON_ROOT_USER}"
check "fisher" su "${NON_ROOT_USER}" -c 'fish -c "fisher -v"'

# Report result
reportResults
