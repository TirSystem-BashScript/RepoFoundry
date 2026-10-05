# SQA Review Record: create-project.sh (MIL-001)

## Metadata
| Key | Value |
| --- | --- |
| ID | RC-016 |
| CrossReference | [MIL-001], [QC-SH-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-05 | Proposed | Jens Tirsvad Nielsen | S02 | Initial version | pending |

---

## Artifact Under Review

- Instance reviewed: `create-project.sh` and `tests/` on branch `mil-001-foundation` (reviewed at `102dd24` plus the fixes listed below), the deliverable of [MIL-001]
- Checklist used: [QC-SH-001]
- Review date: 2026-10-05
- Tool versions: bash 5.2.37, shellcheck 0.11.0, shfmt 3.14.1 (Windows, Git Bash)

## Checklist Results

| # | Criterion | Status | Evidence/Notes |
| --- | --- | --- | --- |
| 1 | Starts with `#!/usr/bin/env bash` and `set -euo pipefail` (or a comment explains the exception) | Pass | `set -Eeuo pipefail` follows the header comment. |
| 2 | Every expansion is quoted; lists are arrays; tests use `[[ ]]` and `$(...)` | Pass | `shellcheck` is clean; no backticks or `[ ]`. |
| 3 | Names follow the conventions: `kebab-case.sh` files, `snake_case` functions and variables, `UPPER_SNAKE` constants and environment variables | Pass | Fixed during this review: the boolean keys `use_github` and `plan_gate` were renamed `has_github` and `is_plan_gate_enabled` (the `is_` / `has_` rule). |
| 4 | Passes `shellcheck` and `bash -n` with no unexplained `disable` comments | Pass | Clean with the tools above. Every `disable` carries its reason: SC2034 (namerefs and results read by callers), SC2094 (loop only uses the file name in messages), SC2004 (associative array key), and in `tests/` SC2016 and SC2034 (literal snippet text, results read by other files). |
| 5 | Errors go to standard error with an `error:` message and a non-zero exit code; bad or missing arguments print a usage line | Pass | `die` and `usage_error` (exit 1 and 2); tests cover an unknown option and an option without a value. |
| 6 | Temporary files use `mktemp` with a `trap ... EXIT` cleanup; no fixed `/tmp` names | Pass | Private directory created with `umask 077`; files removed one by one, directory with `rmdir`. Verified after a normal run, a failed run and SIGTERM (test added). SIGINT was not verified: see the action items. |
| 7 | No secret is written in the script, echoed, or put on a command line; secrets come from the environment or a gitignored file | Pass | Fixed during this review: under `bash -x` the script printed the token 47 times in the trace. Tracing is now switched off with a warning, and a test fails if the guard is removed (checked by mutation). Tokens go through a private curl config file, never the command line; output is redacted; error messages name the key and line, never the value. |
| 8 | A script that changes state outside its own directory defaults to a dry run or needs an explicit flag, and says so in its header | Pass | This version contacts no host and changes nothing; the header says so. It only creates a private temporary directory, removed on exit. |
| 9 | A header comment states purpose, usage, options, environment variables and exit codes | Pass | All present, plus files, requirements, tracing and what the script implements; `--help` prints it. |
| 10 | The script implements a task or design it cites; deviations are recorded | Pass | Fixed during this review: the header now cites MIL-001 tasks 1 to 6 (issues #3 to #8), US-001.01 and UC-001, and records the one deviation (the second `GITEA_URL` key is `GITEA_API_URL`). |
| 11 | Behaviour is tested for success, failure and any disabled or bypass path | Pass | 209 checks: successful runs with and without GitHub, bad input, missing tools, network failure, redaction, tracing, termination. The script has no bypass flag. Mutation checks: a planted token leak and the removed tracing guard were both caught. |
| 12 | Formatted with `shfmt` (or the project's formatter) | Pass | `shfmt -i 2 -ci` reports no difference. |
| 13 | Safe to re-run: a second run does not duplicate or corrupt what the first did | Pass | The script keeps no state. |
| 14 | Bash version and external tools it needs are stated; GNU-only options are named | Pass | Fixed during this review: the header now lists bash 4.4, git, curl, mktemp, optional jq, the base tools it calls and the GNU or BSD `stat` form. |

## Defects found and fixed during this review

| Defect | Fix | Test |
| --- | --- | --- |
| `bash -x` printed the tokens in the trace | Tracing is switched off with a warning | `test_tracing_does_not_leak_secrets` |
| A byte order mark on the first line of a config file gave an unclear "expected KEY=VALUE" error | The mark is ignored | `test_byte_order_mark_is_accepted` |
| `jq` on Windows added a carriage return to every value `json_get` returned | The carriage return is stripped | `test_json_get_with_and_without_jq` |
| `json_get` without `jq` returned the last occurrence of a key on one-line JSON | It returns the first occurrence | `test_json_get_with_and_without_jq` |

## MIL-001 Go/No-Go check

| # | Criterion | Result |
| --- | --- | --- |
| 1 | `shellcheck create-project.sh` reports no errors | Go: clean |
| 2 | Neither config file is `source`d; unknown keys and malformed lines are rejected | Go: parser tests, including values that would run a command |
| 3 | No token appears in stdout, stderr or a log in any test, including failure paths | Go: end-to-end and trace tests |
| 4 | Missing `git` or `curl` stops the script before any change | Go: empty `PATH` test, nothing created |
| 5 | `.env` is ignored by git; both example files contain placeholders only | Go: tested |
| 6 | All acceptance criteria of US-001.01 are met | Go: validation without execution, stop on a missing tool or bad value, prompts for every detail |

## Overall Verdict

Go — All mandatory criteria of QC-SH-001 pass after the fixes above, and all six MIL-001 Go/No-Go criteria are met. Author and reviewer are the same person for now (S01 and S02 are both held by the Maintainer), so the framework independence rule is not met; re-review when a second person takes S02.

## Action Items

These are follow-ups, not conditions on the Go.

| Action | Owner | Due |
| --- | --- | --- |
| Run `tests/run-tests.sh` on Linux and macOS (bash 4.4 or later), including the `.env` permission warning, which is skipped on Windows | S02 | 2026-10-30 |
| Check by hand that Ctrl-C removes the temporary directory (a background test cannot send SIGINT) | S02 | 2026-10-30 |
| Check the repository name rules of GitHub and Gitea in the MIL-002 preflight; the script only checks a common safe subset | S02 | 2026-10-30 |

---

[MIL-001]: ../milestones/mil-001-foundation.md
[QC-SH-001]: ../../../framework/qc/qc-programming-shell.md
