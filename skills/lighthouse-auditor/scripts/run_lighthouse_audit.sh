#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="./lighthouse-audit-results"
PRESET="both"
RUNS=1
ONLY_CATEGORIES="performance,accessibility,best-practices,seo"
LOCALE=""
THROTTLING_METHOD=""
CHROME_FLAGS=""
EXTRA_HEADERS=""
URL=""
CLEANUP_DIRS=()
LIGHTHOUSE_CMD=()

usage() {
  cat <<'EOF'
Usage:
  bash scripts/run_lighthouse_audit.sh <url> [options]

Options:
  --output-dir DIR             Directory for reports. Default: ./lighthouse-audit-results
  --preset mobile|desktop|both Audit preset. Default: both
  --runs N                     Number of repeated runs. Default: 1
  --only-categories CSV        Categories to audit. Default: performance,accessibility,best-practices,seo
  --locale CODE                Lighthouse locale
  --throttling-method METHOD   simulate, devtools, or provided
  --chrome-flags FLAGS         Override Chrome flags
  --extra-headers JSON         Pass headers for authenticated pages
  --help                       Show this help text
EOF
}

is_wsl() {
  [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

detect_lighthouse_command() {
  if has_cmd lighthouse; then
    LIGHTHOUSE_CMD=(lighthouse)
    return 0
  fi

  if has_cmd npx; then
    LIGHTHOUSE_CMD=(npx --yes lighthouse)
    return 0
  fi

  return 1
}

is_reserved_windows_profile() {
  case "$1" in
    "All Users"|"Default"|"Default User"|"Public"|"TEMP")
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

detect_windows_local_temp() {
  local local_appdata=""
  local candidate=""
  local profile_name=""

  if ! is_wsl; then
    return 1
  fi

  if has_cmd cmd.exe; then
    local_appdata="$(cmd.exe /c "echo %LOCALAPPDATA%" 2>/dev/null | tr -d '\r' | tail -n 1)"
    if [[ -n "$local_appdata" && "$local_appdata" != "%LOCALAPPDATA%" ]]; then
      if has_cmd wslpath; then
        local_appdata="$(wslpath -u "$local_appdata" 2>/dev/null || true)"
      fi
      profile_name="$(basename "$(dirname "$(dirname "$(dirname "$local_appdata")")")")"
      if is_reserved_windows_profile "$profile_name"; then
        local_appdata=""
      fi
      if [[ -n "$local_appdata" && -d "$local_appdata/Temp" ]]; then
        printf '%s\n' "$local_appdata/Temp"
        return 0
      fi
    fi
  fi

  for candidate in /mnt/c/Users/*/AppData/Local/Temp; do
    profile_name="$(basename "$(dirname "$(dirname "$(dirname "$candidate")")")")"
    if is_reserved_windows_profile "$profile_name"; then
      continue
    fi
    if [[ -d "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

ensure_wsl_launcher_path() {
  local windows_temp=""

  if ! is_wsl; then
    return 0
  fi

  if windows_temp="$(detect_windows_local_temp 2>/dev/null)"; then
    case ":$PATH:" in
      *":$windows_temp:"*)
        ;;
      *)
        export PATH="$windows_temp:$PATH"
        ;;
    esac
  fi
}

cleanup_run_artifacts() {
  local target

  for target in "${CLEANUP_DIRS[@]:-}"; do
    [[ -n "$target" ]] && rm -rf -- "$target"
  done

  find . -maxdepth 1 -mindepth 1 -type d \
    \( \
      -name 'C:*lighthouse.*' -o \
      -name 'C*Users*AppData*Local*lighthouse.*' -o \
      -name '*AppData*Local*lighthouse.*' -o \
      -name '*\\AppData\\Local\\lighthouse.*' -o \
      -name '@undefined' -o \
      -name '@undefined:*' -o \
      -name '*@undefined*' -o \
      -name '*undefined:*' -o \
      -name 'undefined:' \
    \) \
    -exec rm -rf -- {} +
}

trap cleanup_run_artifacts EXIT

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

slugify() {
  printf '%s' "$1" | sed -E 's#^https?://##; s#[^a-zA-Z0-9]+#-#g; s#^-+##; s#-+$##; s#-+#-#g' | cut -c1-80
}

build_profiles() {
  case "$1" in
    mobile)
      printf 'mobile\n'
      ;;
    desktop)
      printf 'desktop\n'
      ;;
    both)
      printf 'mobile\ndesktop\n'
      ;;
    *)
      echo "[ERROR] Invalid preset: $1"
      echo "        Expected one of: mobile, desktop, both"
      exit 1
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir)
      OUTPUT_DIR="$2"
      shift
      ;;
    --preset)
      PRESET="$2"
      shift
      ;;
    --runs)
      RUNS="$2"
      shift
      ;;
    --only-categories)
      ONLY_CATEGORIES="$2"
      shift
      ;;
    --locale)
      LOCALE="$2"
      shift
      ;;
    --throttling-method)
      THROTTLING_METHOD="$2"
      shift
      ;;
    --chrome-flags)
      CHROME_FLAGS="$2"
      shift
      ;;
    --extra-headers)
      EXTRA_HEADERS="$2"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    -*)
      echo "[ERROR] Unknown option: $1"
      usage
      exit 1
      ;;
    *)
      if [[ -z "$URL" ]]; then
        URL="$1"
      else
        echo "[ERROR] Unexpected argument: $1"
        usage
        exit 1
      fi
      ;;
  esac
  shift
done

if [[ -z "$URL" ]]; then
  echo "[ERROR] A URL is required."
  usage
  exit 1
fi

if ! detect_lighthouse_command; then
  echo "[ERROR] Lighthouse is not available. Run bash scripts/ensure_lighthouse_env.sh --check first."
  echo "        Install it globally with npm install -g lighthouse or use npm/npx so the wrapper can run npx --yes lighthouse."
  exit 1
fi

if [[ -z "${CHROME_PATH:-}" ]]; then
  if DETECTED_BROWSER="$(detect_browser 2>/dev/null)"; then
    export CHROME_PATH="$DETECTED_BROWSER"
  fi
fi

if [[ -z "$CHROME_FLAGS" ]]; then
  if is_wsl; then
    CHROME_FLAGS="--headless --no-sandbox --disable-gpu"
  else
    CHROME_FLAGS="--headless --no-sandbox --disable-dev-shm-usage"
  fi
fi

ensure_wsl_launcher_path

mkdir -p "$OUTPUT_DIR"

STAMP="$(date +%Y-%m-%d-%H%M%S)"
SLUG="$(slugify "$URL")"
MANIFEST="$OUTPUT_DIR/$SLUG.$STAMP.manifest.txt"

echo "url=$URL" > "$MANIFEST"
echo "preset=$PRESET" >> "$MANIFEST"
echo "runs=$RUNS" >> "$MANIFEST"
echo "chrome_path=${CHROME_PATH:-unset}" >> "$MANIFEST"
echo "chrome_flags=$CHROME_FLAGS" >> "$MANIFEST"
echo "profiles=$(build_profiles "$PRESET" | paste -sd, -)" >> "$MANIFEST"

while IFS= read -r PROFILE; do
  [[ -z "$PROFILE" ]] && continue
  for run in $(seq 1 "$RUNS"); do
    OUTPUT_BASE="$OUTPUT_DIR/$SLUG.$STAMP.$PROFILE"
    if [[ "$RUNS" -gt 1 ]]; then
      OUTPUT_BASE="$OUTPUT_BASE.run-$run"
    fi

    RUN_CHROME_FLAGS="$CHROME_FLAGS"
    RUN_USER_DATA_DIR=""

    if is_wsl && [[ "$RUN_CHROME_FLAGS" != *"--user-data-dir="* ]]; then
      RUN_USER_DATA_DIR="/tmp/lighthouse-user-data-$SLUG-$STAMP-$PROFILE-run-$run"
      RUN_CHROME_FLAGS="$RUN_CHROME_FLAGS --user-data-dir=$RUN_USER_DATA_DIR"
      CLEANUP_DIRS+=("$RUN_USER_DATA_DIR")
    fi

    CMD=(
      "${LIGHTHOUSE_CMD[@]}" "$URL"
      --output html,json
      --output-path "$OUTPUT_BASE"
      --only-categories "$ONLY_CATEGORIES"
      --chrome-flags="$RUN_CHROME_FLAGS"
    )

    if [[ "$PROFILE" == "desktop" ]]; then
      CMD+=(--preset=desktop)
    fi

    if [[ -n "$LOCALE" ]]; then
      CMD+=(--locale="$LOCALE")
    fi

    if [[ -n "$THROTTLING_METHOD" ]]; then
      CMD+=(--throttling-method="$THROTTLING_METHOD")
    fi

    if [[ -n "$EXTRA_HEADERS" ]]; then
      CMD+=(--extra-headers="$EXTRA_HEADERS")
    fi

    echo "[INFO] Running Lighthouse audit profile=$PROFILE run=$run/$RUNS"
    echo "[INFO] Output base: $OUTPUT_BASE"
    "${CMD[@]}"

    echo "json=$OUTPUT_BASE.report.json" >> "$MANIFEST"
    echo "html=$OUTPUT_BASE.report.html" >> "$MANIFEST"
  done
done < <(build_profiles "$PRESET")

echo "[OK] Audit complete."
echo "[OK] Manifest: $MANIFEST"
