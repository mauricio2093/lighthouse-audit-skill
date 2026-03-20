#!/usr/bin/env bash
set -euo pipefail

ACTION="check"
PRINT_SHELL=0

usage() {
  cat <<'EOF'
Usage:
  bash scripts/ensure_lighthouse_env.sh [--check] [--install-lighthouse] [--install-browser] [--install-all] [--print-shell]

Options:
  --check              Validate the environment only. This is the default.
  --install-lighthouse Install Lighthouse globally with npm if it is missing.
  --install-browser    Install Google Chrome Stable on Debian/Ubuntu systems.
  --install-all        Install missing Lighthouse and the preferred browser when possible.
  --print-shell        Print export commands that can be eval'd or sourced by the caller.
  --help               Show this help text.
EOF
}

is_wsl() {
  [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

first_existing() {
  local candidate
  for candidate in "$@"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
    if has_cmd "$candidate"; then
      command -v "$candidate"
      return 0
    fi
  done
  return 1
}

detect_browser() {
  if is_wsl; then
    first_existing \
      /usr/bin/google-chrome-stable \
      google-chrome-stable \
      /usr/bin/google-chrome \
      google-chrome \
      /usr/bin/chromium-browser \
      chromium-browser \
      /usr/bin/chromium \
      chromium
    return
  fi

  first_existing \
    /usr/bin/google-chrome-stable \
    google-chrome-stable \
    /usr/bin/google-chrome \
    google-chrome \
    /usr/bin/chromium-browser \
    chromium-browser \
    /usr/bin/chromium \
    chromium
}

install_lighthouse() {
  if has_cmd lighthouse; then
    echo "[OK] Lighthouse is already installed."
    return 0
  fi

  if ! has_cmd npm; then
    echo "[ERROR] npm is not available. Install Node.js 18+ LTS first."
    return 1
  fi

  echo "[INFO] Installing Lighthouse globally with npm..."
  npm install -g lighthouse
}

install_google_chrome_stable() {
  if [[ -x /usr/bin/google-chrome-stable ]]; then
    echo "[OK] Google Chrome Stable is already installed."
    return 0
  fi

  if ! has_cmd apt-get; then
    echo "[ERROR] Automatic browser installation currently supports Debian/Ubuntu with apt-get."
    return 1
  fi

  if ! has_cmd sudo; then
    echo "[ERROR] sudo is required to install Google Chrome Stable."
    return 1
  fi

  echo "[INFO] Installing Google Chrome Stable..."
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg
  curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y google-chrome-stable
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      ACTION="check"
      ;;
    --install-lighthouse)
      ACTION="install-lighthouse"
      ;;
    --install-browser)
      ACTION="install-browser"
      ;;
    --install-all)
      ACTION="install-all"
      ;;
    --print-shell)
      PRINT_SHELL=1
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "[ERROR] Unknown option: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

case "$ACTION" in
  install-lighthouse)
    install_lighthouse
    ;;
  install-browser)
    install_google_chrome_stable
    ;;
  install-all)
    install_lighthouse
    install_google_chrome_stable
    ;;
esac

NODE_VERSION="missing"
NPM_VERSION="missing"
LIGHTHOUSE_VERSION="missing"
BROWSER_PATH=""
CHROME_CURRENT="${CHROME_PATH:-}"
ENV_IS_WSL="no"

if is_wsl; then
  ENV_IS_WSL="yes"
fi

if has_cmd node; then
  NODE_VERSION="$(node --version)"
fi

if has_cmd npm; then
  NPM_VERSION="$(npm --version)"
fi

if has_cmd lighthouse; then
  LIGHTHOUSE_VERSION="$(lighthouse --version)"
fi

if BROWSER_PATH="$(detect_browser 2>/dev/null)"; then
  :
else
  BROWSER_PATH=""
fi

if [[ "$PRINT_SHELL" -eq 1 ]]; then
  if [[ -n "$BROWSER_PATH" ]]; then
    printf 'export CHROME_PATH=%q\n' "$BROWSER_PATH"
  fi
  if is_wsl; then
    printf 'export LIGHTHOUSE_CHROME_FLAGS=%q\n' "--headless --no-sandbox --disable-gpu"
  else
    printf 'export LIGHTHOUSE_CHROME_FLAGS=%q\n' "--headless --no-sandbox --disable-dev-shm-usage"
  fi
  exit 0
fi

echo "Environment summary"
echo "  WSL: $ENV_IS_WSL"
echo "  node: $NODE_VERSION"
echo "  npm: $NPM_VERSION"
echo "  lighthouse: $LIGHTHOUSE_VERSION"
echo "  CHROME_PATH: ${CHROME_CURRENT:-unset}"
echo "  detected_browser: ${BROWSER_PATH:-missing}"

if [[ "$LIGHTHOUSE_VERSION" == "missing" ]]; then
  echo "[WARN] Lighthouse is missing."
  echo "       If npm is available, run: npm install -g lighthouse"
fi

if [[ -n "$CHROME_CURRENT" && ! -e "$CHROME_CURRENT" ]]; then
  echo "[WARN] CHROME_PATH points to a missing path: $CHROME_CURRENT"
fi

if [[ -n "$CHROME_CURRENT" && "$CHROME_CURRENT" == /mnt/c/* ]]; then
  echo "[WARN] CHROME_PATH points to a Windows path. Prefer a Linux-native browser inside WSL."
fi

if [[ -z "$BROWSER_PATH" ]]; then
  echo "[WARN] No compatible browser was detected."
  if is_wsl; then
    echo "       Preferred fix: install Google Chrome Stable and export CHROME_PATH=/usr/bin/google-chrome-stable"
  fi
else
  echo "[OK] Suggested browser path: $BROWSER_PATH"
  echo "     Export with: export CHROME_PATH=$BROWSER_PATH"
fi

if is_wsl && [[ ! -x /usr/bin/google-chrome-stable ]]; then
  if [[ -n "$BROWSER_PATH" ]]; then
    echo "[WARN] WSL browser fallback was detected, but Google Chrome Stable is not installed."
    echo "       Prefer installing Chrome Stable to avoid launcher and cross-environment issues."
  else
    echo "[WARN] WSL was detected and Google Chrome Stable is missing."
  fi
fi

if is_wsl; then
  echo "[INFO] Recommended WSL Chrome flags: --headless --no-sandbox --disable-gpu"
else
  echo "[INFO] Recommended Linux/CI Chrome flags: --headless --no-sandbox --disable-dev-shm-usage"
fi
