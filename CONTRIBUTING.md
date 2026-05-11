# Contributing

Thanks for considering a contribution to republic-ai-node.

## What this repo is
A collection of validator operation notes, runbooks, and helper
scripts. It is not the upstream chain code - that lives elsewhere.

## What good contributions look like

### Documentation
- Fix typos and broken links freely - no issue needed
- Clarify a runbook step that bit you in production
- Add a new scenario to FAQ.md that you wished was answered

### Scripts
- Keep them POSIX-friendly where possible
- Read configuration from env vars with sensible defaults
- Include a header comment explaining what and why
- chmod +x before committing

### Larger changes
Open an issue first. A two-line discussion saves an hour of
rebasing.

## Style
- Markdown: short paragraphs, code in fenced blocks
- Shell: set -e at the top, quote variables, prefer jq over awk for JSON
- Commit messages: imperative mood, first line under 72 chars,
  body explains why if non-obvious

## Testing
For shell scripts, at minimum:
- shellcheck clean
- runs without error on a fresh Ubuntu 22.04 host

For docs, at minimum:
- markdown renders correctly on GitHub
- no broken cross-references

## Reporting issues
Include:
- What you tried
- What you expected
- What actually happened
- Host/OS/chain version
- Relevant log excerpt (redact keys!)

## Security
If you find something that could compromise validator keys or
funds, do NOT open a public issue. Reach out privately first.
