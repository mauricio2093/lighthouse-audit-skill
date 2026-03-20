#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


CATEGORY_ORDER = [
    "performance",
    "accessibility",
    "best-practices",
    "seo",
    "pwa",
]

METRICS = [
    ("first-contentful-paint", "FCP"),
    ("largest-contentful-paint", "LCP"),
    ("total-blocking-time", "TBT"),
    ("cumulative-layout-shift", "CLS"),
    ("interactive", "TTI"),
    ("speed-index", "Speed Index"),
]


def label_for_score(score):
    if score is None:
        return "n/a"
    if score >= 90:
        return "green"
    if score >= 50:
        return "yellow"
    return "red"


def load_report(path: Path):
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def format_score(value):
    if value is None:
        return "n/a"
    return f"{round(value * 100)} ({label_for_score(value * 100)})"


def top_opportunities(audits, limit):
    opportunities = []
    for audit_id, audit in audits.items():
        details = audit.get("details") or {}
        if details.get("type") != "opportunity":
            continue
        savings_ms = round(details.get("overallSavingsMs") or 0)
        if savings_ms <= 0:
            continue
        opportunities.append(
            {
                "id": audit_id,
                "title": audit.get("title", audit_id),
                "savings_ms": savings_ms,
            }
        )
    opportunities.sort(key=lambda item: item["savings_ms"], reverse=True)
    return opportunities[:limit]


def failing_audits(audits, limit):
    failures = []
    for audit_id, audit in audits.items():
        score = audit.get("score")
        if score is None or score >= 1:
            continue
        failures.append(
            {
                "id": audit_id,
                "title": audit.get("title", audit_id),
                "score": score,
            }
        )
    failures.sort(key=lambda item: item["score"])
    return failures[:limit]


def main():
    parser = argparse.ArgumentParser(description="Summarize a Lighthouse JSON report.")
    parser.add_argument("report_json", help="Path to a *.report.json file")
    parser.add_argument("--top", type=int, default=3, help="Number of opportunities to print")
    args = parser.parse_args()

    path = Path(args.report_json).resolve()
    report = load_report(path)

    categories = report.get("categories", {})
    audits = report.get("audits", {})

    print(f"# Lighthouse Summary")
    print(f"report: {path}")
    print("")
    print("## Category scores")
    for category in CATEGORY_ORDER:
        score = categories.get(category, {}).get("score")
        if score is None and category not in categories:
            continue
        print(f"- {category}: {format_score(score)}")

    print("")
    print("## Key metrics")
    for audit_id, label in METRICS:
        audit = audits.get(audit_id, {})
        value = audit.get("displayValue", "n/a")
        print(f"- {label}: {value}")

    print("")
    print("## Top opportunities")
    opportunities = top_opportunities(audits, args.top)
    if not opportunities:
        print("- No opportunity entries with estimated savings were found.")
    else:
        for item in opportunities:
            print(f"- {item['title']} ({item['id']}): {item['savings_ms']} ms estimated savings")

    print("")
    print("## Failing audits")
    failures = failing_audits(audits, 8)
    if not failures:
        print("- No failing scored audits were found.")
    else:
        for item in failures:
            print(f"- {item['title']} ({item['id']}): score {item['score']}")


if __name__ == "__main__":
    main()
