# Lighthouse Config and Performance Budgets

Read this file when the user needs a custom `lighthouse.config.js`, a `budget.json`, desktop-vs-mobile tuning, or repeatable settings for teams and CI.

## Minimal Config File

```javascript
// lighthouse.config.js
module.exports = {
  extends: 'lighthouse:default',
  settings: {
    onlyCategories: ['performance', 'accessibility', 'best-practices', 'seo'],
    formFactor: 'mobile',
    locale: 'en',
    maxWaitForLoad: 45000,
  },
};
```

Run with:

```bash
lighthouse https://example.com --config-path=./lighthouse.config.js
```

## Desktop Profile

```javascript
module.exports = {
  extends: 'lighthouse:default',
  settings: {
    formFactor: 'desktop',
    screenEmulation: {
      mobile: false,
      width: 1350,
      height: 940,
      deviceScaleFactor: 1,
      disabled: false,
    },
  },
};
```

## Throttling Guidance

Use the throttling method that matches the task:

- `simulate`: default for comparable production-style reports.
- `devtools`: useful when you want a more literal browser throttling run.
- `provided`: best for localhost and development servers where you do not want artificial throttling.

Example:

```bash
lighthouse http://localhost:3000 --throttling-method=provided
```

## Budget File

```json
[
  {
    "path": "/*",
    "timings": [
      { "metric": "largest-contentful-paint", "budget": 3000 },
      { "metric": "total-blocking-time", "budget": 300 },
      { "metric": "cumulative-layout-shift", "budget": 0.1 }
    ],
    "resourceSizes": [
      { "resourceType": "script", "budget": 300 },
      { "resourceType": "image", "budget": 500 },
      { "resourceType": "total", "budget": 1500 }
    ]
  }
]
```

Run with:

```bash
lighthouse https://example.com --budget-path=./budget.json --output json,html --output-path=./budget-report
```

## Practical Rules

- Use a normal one-off audit for exploration.
- Use three runs when comparing pages or defending a performance claim.
- Keep mobile and desktop reports separate, even when the wrapper runs both by default.
- Reuse one config file per project instead of rebuilding flags by hand in every run.
