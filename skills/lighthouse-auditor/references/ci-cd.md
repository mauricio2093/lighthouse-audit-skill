# Lighthouse in CI/CD

Read this file when the user wants automated audits in GitHub Actions, GitLab CI, or Lighthouse CI.

## General Rules

- Use headless Chrome flags in CI.
- Save JSON and HTML artifacts.
- Fail or warn on thresholds that matter to the team.
- Prefer three runs for stable CI comparisons.

## GitHub Actions Example

```yaml
name: Lighthouse Audit

on:
  pull_request:
  push:
    branches: [main]

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install Lighthouse
        run: npm install -g lighthouse

      - name: Run Lighthouse
        run: |
          lighthouse https://example.com \
            --output json,html \
            --output-path ./lh-report \
            --chrome-flags="--headless --no-sandbox --disable-dev-shm-usage" \
            --quiet

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: lighthouse-report
          path: |
            lh-report.report.html
            lh-report.report.json
```

## GitLab CI Example

```yaml
lighthouse:
  stage: test
  image: node:20
  before_script:
    - apt-get update && apt-get install -y chromium jq
    - export CHROME_PATH=$(which chromium)
    - npm install -g lighthouse
  script:
    - |
      lighthouse "$CI_ENVIRONMENT_URL" \
        --output json,html \
        --output-path ./lh-report \
        --chrome-flags="--headless --no-sandbox --disable-dev-shm-usage" \
        --quiet
```

## Lighthouse CI Example

```javascript
module.exports = {
  ci: {
    collect: {
      url: ['https://example.com'],
      numberOfRuns: 3,
      settings: {
        chromeFlags: '--headless --no-sandbox',
      },
    },
    assert: {
      preset: 'lighthouse:recommended',
      assertions: {
        'categories:performance': ['warn', { minScore: 0.8 }],
        'categories:accessibility': ['error', { minScore: 0.9 }],
      },
    },
    upload: {
      target: 'temporary-public-storage',
    },
  },
};
```

## What to Report Back

When helping with CI/CD, explain:

- Where the reports are stored.
- Which thresholds fail the pipeline.
- Whether the setup is single-run or three-run.
- Whether the job uses raw Lighthouse CLI or Lighthouse CI.
