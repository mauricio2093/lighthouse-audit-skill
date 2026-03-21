# WSL Chrome Launcher Fix

Read this file when Lighthouse is running inside WSL and Chrome fails to launch, Lighthouse cannot find a usable browser, or the run dies with launcher errors such as `ECONNREFUSED 127.0.0.1`.

## Goal

Use a Linux-native browser inside WSL, preferably `Google Chrome Stable`, and make Lighthouse launch it explicitly with `CHROME_PATH`.

## Typical Symptoms

- `LH:ChromeLauncher:error connect ECONNREFUSED 127.0.0.1:XXXXX`
- `Unable to connect to Chrome`
- `Could not find Chrome`
- A browser exists in Windows, but Lighthouse still fails inside WSL

## Recommended Fix

### 1. Confirm the environment

```bash
echo "${WSL_DISTRO_NAME:-not-wsl}"
uname -a
```

### 2. Check the current browser setup

```bash
echo "$CHROME_PATH"
ls -l "$CHROME_PATH"
which google-chrome-stable || true
which chromium || true
which chromium-browser || true
```

If `CHROME_PATH` points to a Windows path under `/mnt/c/...`, replace it with a Linux-native browser path.

### 3. Prefer Google Chrome Stable in WSL

If `/usr/bin/google-chrome-stable` exists, export it:

```bash
export CHROME_PATH=/usr/bin/google-chrome-stable
```

If it is missing and the user allows installation, install it:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
sudo apt-get update
sudo apt-get install -y google-chrome-stable
export CHROME_PATH=/usr/bin/google-chrome-stable
```

Do not default to a Windows Chrome binary. Use Chromium in WSL only if the user declines Chrome Stable or installation is impossible.

### 4. Export the launcher environment fix

This specific `ENOENT ... /mnt/undefined/Users/undefined/AppData/Local/lighthouse...` error is not fixed by `CHROME_PATH` alone.
It happens before the report is generated, when `chrome-launcher` tries to derive a Windows temp directory from `PATH`.

Preferred fix:

```bash
eval "$(bash scripts/ensure_lighthouse_env.sh --print-shell)"
bash scripts/clean_lighthouse_temp.sh
```

Manual fallback:

```bash
export PATH="/mnt/c/Users/<windows-user>/AppData/Local/Temp:$PATH"
export CHROME_PATH=/usr/bin/google-chrome-stable
```

### 5. Run Lighthouse with WSL-friendly flags

```bash
lighthouse https://example.com --chrome-flags="--headless --no-sandbox --disable-gpu"
```

If the global `lighthouse` binary is not installed but `npx` is available, use:

```bash
npx --yes lighthouse https://example.com --chrome-flags="--headless --no-sandbox --disable-gpu"
```

The known-good combination is:

```bash
export PATH="/mnt/c/Users/<windows-user>/AppData/Local/Temp:$PATH"
export CHROME_PATH=/usr/bin/google-chrome-stable
lighthouse https://example.com --chrome-flags="--headless --no-sandbox --disable-gpu"
```

When using the skill from its own folder, the preferred literal fallback is:

```bash
eval "$(bash scripts/ensure_lighthouse_env.sh --print-shell)"
lighthouse https://example.com --chrome-flags="--headless --no-sandbox --disable-gpu"
```

If the environment only has `npx`, use this exact variant instead:

```bash
eval "$(bash scripts/ensure_lighthouse_env.sh --print-shell)"
npx --yes lighthouse https://example.com --chrome-flags="--headless --no-sandbox --disable-gpu"
```

Do not skip this exact test and then claim the environment is blocked based only on similar variants such as different headless flags, extra hostname or port settings, or a different Chrome binary path.

If WSL plus Chrome launcher behavior starts leaving literal directories such as `C:\Users\...\AppData\Local\lighthouse.*`, `undefined:`, or `@undefined` inside the project root, force a Linux temp profile with:

```bash
lighthouse https://example.com --chrome-flags="--headless --no-sandbox --disable-gpu --user-data-dir=/tmp/lighthouse-user-data"
```

Then clean the project root explicitly:

```bash
bash scripts/clean_lighthouse_temp.sh
```

### 6. Verify success

The fix is confirmed only when Lighthouse finishes and produces normal output:

- HTML and JSON reports are generated.
- The launcher error disappears.
- The run no longer fails before report creation.

## Permanent Fix

If the export solves the issue, persist it:

```bash
echo 'export CHROME_PATH=/usr/bin/google-chrome-stable' >> ~/.bashrc
source ~/.bashrc
```

## Decision Rules

- Treat WSL browser-launch failures as browser resolution problems first, not Lighthouse reinstall problems.
- Prefer `google-chrome-stable` before `chromium` in WSL.
- If you see `ECONNREFUSED`, assume Chrome did not launch correctly.
- Validate with a real Lighthouse run, not just `which` checks.
