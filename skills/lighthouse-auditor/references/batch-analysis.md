# Batch Lighthouse Audits

Read this file when the user wants to audit many URLs, compare sections of a site, or generate a repeatable report set for a list of pages.

## Decide the Batch Strategy

Use a simple shell loop for a small list. Use a more structured approach when:

- The list is large.
- You need three runs per page.
- You want a summary CSV or comparison sheet.
- You need to control concurrency.

## Simple Loop

```bash
while IFS= read -r url; do
  [[ -z "$url" || "$url" == \#* ]] && continue
  bash scripts/run_lighthouse_audit.sh "$url" --output-dir ./lighthouse-audit-results
done < urls.txt
```

Example `urls.txt`:

```text
https://example.com
https://example.com/about
https://example.com/contact
```

## Comparison Rules

When comparing multiple URLs:

- Keep the same preset for all pages.
- Keep the same Chrome flags for all pages.
- Use the same run count for all pages.
- Compare medians or repeated patterns instead of trusting the best individual run.

## Suggested Output Set

For each URL, keep:

- The HTML report.
- The JSON report.
- A short summary extracted from the JSON report.

If the user wants a formal comparison, create a spreadsheet or Markdown table with:

- URL
- Performance
- Accessibility
- Best practices
- SEO
- LCP
- CLS
- TBT
- Notes on the biggest regression or opportunity

## Concurrency Guidance

Avoid launching too many Lighthouse runs at once. Heavy parallelism can distort results and overload local machines or staging servers. Favor a small concurrency level and stable conditions over speed.
