# Lighthouse Auditor Skill

Repository focused on a specialized **Lighthouse** skill for auditing websites, fixing browser-launch issues in Linux and WSL, and generating technical HTML and JSON reports ready for analysis or CI/CD workflows.

## What This Repository Is

This project brings together the documentation, prompt structure, and packaged skill for **`lighthouse-auditor`**. Its goal is to help an agent or assistant work with Lighthouse more autonomously in order to:

- verify whether Lighthouse is installed
- detect missing Chrome or Chromium binaries
- fix common WSL browser-launch issues with `Google Chrome Stable`
- run complete Lighthouse audits
- generate `HTML` and `JSON` reports
- summarize results and prioritize findings

This is not a general end-user application. It is a reusable technical foundation for creating, maintaining, or installing a Lighthouse-focused skill for AI agents and QA workflows.

## Works with

Codex, Claude Code, Cursor, GitHub Copilot, Gemini CLI, OpenCode, Warp, Kimi Code CLI, and more.

## Install

```bash
npx skills install github:mauricio2093/lighthouse-audit-skill
```

## Installation Sources

```bash
# GitHub shorthand (owner/repo)
npx skills add mauricio2093/lighthouse-audit-skill

# Full GitHub URL
npx skills add https://github.com/mauricio2093/lighthouse-audit-skill

# Direct path to the skill inside the repo
npx skills add https://github.com/mauricio2093/lighthouse-audit-skill/tree/main/skills/lighthouse-auditor

# Any git URL
npx skills add git@github.com:mauricio2093/lighthouse-audit-skill.git

# Local path
npx skills add ./lighthouse-audit-skill
```

## Common Install Options

| Option | Description |
|--------|-------------|
| `-g, --global` | Install to the user skill directory instead of the current project |
| `-a, --agent <agents...>` | Install only for selected agents such as `codex`, `cursor`, or `cline` |
| `-s, --skill <skills...>` | Install only specific skills by name, such as `lighthouse-auditor` |
| `-l, --list` | List available skills in the repository without installing |
| `--copy` | Copy files instead of symlinking them into agent directories |
| `-y, --yes` | Skip confirmation prompts |
| `--all` | Install all detected skills for all supported agents without prompts |

## Install Location Scope

- Local: Flag `default`, location `./<agent>/skills/lighthouse-auditor`
- Global: Flag `-g`, location `~/<agent>/skills/lighthouse-auditor`

## Main Contents

- `skills/lighthouse-auditor/SKILL.md`: main usage instructions and workflow.
- `skills/lighthouse-auditor/scripts/`: scripts for environment checks, audit execution, and report summarization.
- `skills/lighthouse-auditor/references/`: WSL fixes, result interpretation, config guidance, batch analysis, and CI/CD references.
- `skills/lighthouse-auditor.skill`: packaged version of the skill.

## What It Is For

This repository is useful if you want to:

- audit a website with Lighthouse
- compare `mobile` and `desktop` results
- save reports directly inside the current project
- troubleshoot Lighthouse launcher issues in WSL
- standardize technical audit output for repeated use
- integrate Lighthouse checks into CI/CD pipelines

## Current Default Behavior

The current version of the skill does this by default:

- runs both `mobile` and `desktop`
- stores reports in `./lighthouse-audit-results`
- creates separate output files for each profile
- generates a manifest file for the audit run
- cleans temporary Chrome/Lighthouse profile directories automatically in WSL so only the final reports remain in the project

Example generated files:

- `site.timestamp.mobile.report.html`
- `site.timestamp.mobile.report.json`
- `site.timestamp.desktop.report.html`
- `site.timestamp.desktop.report.json`
- `site.timestamp.manifest.txt`

## General Workflow

1. Detect the audit context: URL, environment, profile, and audit type.
2. Verify Lighthouse, Node.js, npm, and browser dependencies.
3. Fix WSL-specific browser issues when needed.
4. Run the Lighthouse audit.
5. Save reports in a project-local results folder.
6. Summarize findings and explain priorities.

## Included Scripts

- `skills/lighthouse-auditor/scripts/ensure_lighthouse_env.sh`
  Checks Node.js, npm, Lighthouse, and browser availability. It also helps with WSL detection and environment setup.

- `skills/lighthouse-auditor/scripts/run_lighthouse_audit.sh`
  Runs the audit, saves reports in the current project, generates both `mobile` and `desktop` results by default, and cleans temporary WSL artifacts.

- `skills/lighthouse-auditor/scripts/summarize_lighthouse_report.py`
  Reads a Lighthouse `report.json` file and extracts scores, metrics, opportunities, and failing audits.

## Included References

- `skills/lighthouse-auditor/references/wsl-chrome-fix.md`
  Fix for Lighthouse and Chrome launcher problems in WSL.

- `skills/lighthouse-auditor/references/interpreting-results.md`
  Guidance for reading and explaining Lighthouse output.

- `skills/lighthouse-auditor/references/config-and-budgets.md`
  Advanced configuration and performance budget guidance.

- `skills/lighthouse-auditor/references/batch-analysis.md`
  Patterns for auditing multiple URLs.

- `skills/lighthouse-auditor/references/ci-cd.md`
  GitHub Actions, GitLab CI, and Lighthouse CI integration guidance.

## Example Usage

Check the environment:

```bash
bash skill-Lighthouse/skills/lighthouse-auditor/scripts/ensure_lighthouse_env.sh --check
```

Run an audit:

```bash
env PATH="/mnt/c/Users/your-user/AppData/Local/Temp:$PATH" \
CHROME_PATH=/usr/bin/google-chrome-stable \
bash skill-Lighthouse/skills/lighthouse-auditor/scripts/run_lighthouse_audit.sh https://example.com
```

Summarize a report:

```bash
python3 skill-Lighthouse/skills/lighthouse-auditor/scripts/summarize_lighthouse_report.py \
  lighthouse-audit-results/example-com.2026-03-20-120000.mobile.report.json
```

## Project Approach

This repository follows a technical and modular approach: instructions, scripts, and references are separated so the skill can evolve over time, be reused in other environments, and adapt to different web projects without turning into a one-off prompt.
