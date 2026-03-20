# Interpreting Lighthouse Results

Read this file after generating a Lighthouse JSON report and before writing the final explanation to the user.

## What to Extract First

Start with four things:

1. Category scores.
2. Core Web Vitals and related timing metrics.
3. Top opportunities by estimated savings.
4. Failing or low-scoring audits that explain the score.

If you have the bundled Python helper available, run:

```bash
python3 scripts/summarize_lighthouse_report.py path/to/report.report.json
```

## Useful jq Queries

```bash
# Category scores
jq '.categories | to_entries[] | "\(.key): \(.value.score * 100 | round)"' report.json

# Core Web Vitals and related metrics
jq '{
  FCP: .audits["first-contentful-paint"].displayValue,
  LCP: .audits["largest-contentful-paint"].displayValue,
  TBT: .audits["total-blocking-time"].displayValue,
  CLS: .audits["cumulative-layout-shift"].displayValue,
  TTI: .audits["interactive"].displayValue,
  SI: .audits["speed-index"].displayValue
}' report.json

# Opportunities ordered by savings
jq '[.audits | to_entries[]
  | select(.value.details.type == "opportunity")
  | {id: .key, title: .value.title, savingsMs: (.value.details.overallSavingsMs // 0 | round)}
] | sort_by(-.savingsMs)' report.json
```

## Thresholds Worth Calling Out

Use these values when translating raw numbers into plain-English severity:

| Metric | Good | Needs work | Poor |
|---|---|---|---|
| LCP | < 2.5 s | 2.5-4 s | > 4 s |
| CLS | < 0.1 | 0.1-0.25 | > 0.25 |
| TBT | < 200 ms | 200-600 ms | > 600 ms |
| FCP | < 1.8 s | 1.8-3 s | > 3 s |
| TTI | < 3.8 s | 3.8-7.3 s | > 7.3 s |

## Symptom to Likely Cause

### LCP is poor

Check:

- `largest-contentful-paint-element`
- `server-response-time`
- `render-blocking-resources`

Likely causes:

- Large hero image
- Slow backend or CDN
- Render-blocking CSS or JS
- Fonts blocking first render

### TBT is poor

Check:

- `long-tasks`
- `bootup-time`
- `third-party-summary`

Likely causes:

- Large JavaScript bundles
- Heavy third-party tags
- Long main-thread tasks during startup

### CLS is poor

Check:

- `layout-shift-elements`
- `unsized-images`

Likely causes:

- Images or embeds without reserved space
- Late-loaded banners or widgets
- Font swaps that shift text

### Accessibility score is low

Look for zero-score audits in the accessibility category first. Typical failures include:

- Missing alt text
- Form controls without labels
- Low color contrast
- Buttons or links with weak accessible names
- Incorrect heading structure

## Reporting Structure

Present results in this order:

1. Scope: page, device profile, run count, and any special flags.
2. Scores: performance, accessibility, best practices, SEO, and PWA if available.
3. Metrics: call out LCP, CLS, TBT, FCP, and TTI.
4. Opportunities: focus on the three highest estimated savings.
5. Root causes: connect the metrics to specific audit entries.
6. Next actions: order by impact first, then effort.

## Recommendation Pattern

Use a short priority stack:

- Critical: issues causing very poor metrics or broken audits.
- Important: fixes with significant savings or user impact.
- Nice to have: smaller wins that polish the score.

Avoid dumping every failed audit. Group related issues and explain why they matter.
