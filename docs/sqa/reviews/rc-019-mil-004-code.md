# SQA Review Record: Shell code review of the MIL-004 change

## Metadata
| Key | Value |
| --- | --- |
| ID | RC-019 |
| CrossReference | [MIL-004], [QC-SH-001], [RC-016] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-05 | Proposed | Jens Tirsvad Nielsen | S02 | Initial version | [ceaa7d1] |

---

## Artifact Under Review

- Instance reviewed: the MIL-004 change to `src/create-project.sh` and `src/lib/` (`config.sh`, `constants.sh`, `project.sh`), `tests/test-presets.sh`, the README and `config.env.example`, on branch `mil-004-configurable-details` (commit `75e8e91` plus the fixes listed below), tasks 1 to 5 (issues #27 to #31) of [MIL-004].
- Checklist used: [QC-SH-001]. The rest of the code was reviewed in [RC-016].
- Review date: 2026-10-05
- Tool versions: bash 5.2.37, shellcheck 0.11.0, shfmt 3.14.1 (Windows, Git Bash)

## Checklist Results

| # | Criterion | Status | Evidence/Notes |
| --- | --- | --- | --- |
| 1 | Starts with `#!/usr/bin/env bash` and `set -euo pipefail` | Pass | Unchanged. |
| 2 | Every expansion is quoted; lists are arrays; tests use `[[ ]]` and `$(...)` | Pass | `shellcheck` is clean. Values from `config.env` are only ever compared, matched against validators or printed; none reaches `eval`, a command line or a file name before it passed a validator. |
| 3 | Names follow the conventions | Pass | `check_preset`, `preset_detail`, `source_note` and the `HINT_*` constants follow the rules. See finding F4 on the name `PROJECT_NAME`. |
| 4 | Passes `shellcheck` and `bash -n` with no unexplained `disable` comments | Pass | No new `disable`. |
| 5 | Errors go to standard error with an `error:` message and a non-zero exit code | Pass | Every refusal goes through `die`, names the key and the file, never the value. |
| 6 | Temporary files use `mktemp` with a `trap` cleanup | Pass | Not touched. |
| 7 | No secret is written in the script, echoed, or put on a command line | Pass | The new keys carry no credential; they are rejected in `.env`, and credential keys stay rejected in `config.env` (tests). The description is printed in the summary, as it was when asked. |
| 8 | A script that changes state defaults to a dry run | Pass | Unchanged: a preset never skips the dry run or "Create these now". Tests prove that with all eight keys set, an empty or missing answer creates nothing. |
| 9 | A header comment states purpose, usage, options, environment variables and exit codes | Pass | Fixed during this review: the header said only "asks for the project details"; it now says that details set in `config.env` are not asked. |
| 10 | The script implements a task or design it cites; deviations are recorded | Pass | Tasks 1 to 5 of [MIL-004] and extensions 3a and 3b of [UC-001]. Deviations: values are accepted in any case, and `USE_GITHUB`/`ENABLE_PLAN_GATE` take `yes` or `no` only; both are in the README. |
| 11 | Behaviour is tested for success, failure and any disabled or bypass path | Pass | 919 checks in the full suite before the review, 0 failed. New: each key set, absent, empty and invalid; mixed asked and preset; `USE_GITHUB` interplay; the summary marker; no prompt text for a preset; the confirmations. Mutation check: making the preset lookup always fail made the tests fail. |
| 12 | Formatted with `shfmt` | Pass | No difference. |
| 13 | Safe to re-run | Pass | No state is kept. |
| 14 | Bash version and external tools stated | Pass | Unchanged. |

## Findings

| # | Finding | Severity | Status |
| --- | --- | --- | --- |
| F1 | An unquoted `PROJECT_DESCRIPTION` containing ` #` is silently cut at the comment mark (`Tool # for mirrors` becomes `Tool`), with no message. This is how the parser reads every value, but a description is the one free-text key, so it is where it bites. A value with both kinds of quote cannot be set at all (it can still be typed at the prompt). | Low (surprise, no data loss or security effect) | Fixed: the README and `config.env.example` say to put such a value in double quotes; a test pins both behaviours. The both-quotes case is documented as a limit of the parser. |
| F2 | The header of `create-project.sh` and the README sentence "The script asks for, in this order" did not mention that preset details are not asked. | Low (documentation) | Fixed. |
| F3 | The summary marks the source after the value, so a fully preset run reads `my-app (from config.env) (private (from config.env))`. Correct but noisy, and `USE_GITHUB=yes` is not marked on the GitHub line (only the owner is). | Low (readability) | Accepted: the marker is asserted by the tests and the wording is not a requirement; revisit if the Maintainer wants a table layout. |
| F4 | The constant `PROJECT_NAME` (the name of this tool, `RepoFoundry`) and the config key `PROJECT_NAME` (the name of the new project) share a spelling. They never meet in code (the key lives in `CONFIG`), but a reader can confuse them. | Low (maintainability) | Open: renaming the constant is out of scope for this change; a candidate for a later clean-up. |
| F5 | A `config.env` that sets `PROJECT_NAME` and `GITEA_OWNER` makes every run use them. Existing repositories are still detected and need the reuse confirmation, so nothing is overwritten. | Info | Documented in the README (per-project configuration). |

No finding affects credentials, ownership, the mirror direction or the confirmations.

## Overall Verdict

Go — all mandatory criteria pass after the fixes for F1 and F2 (found and fixed during this review; the test for F1 was added; the full suite was rerun afterwards: 923 checks, 0 failed). F3 and F4 are recorded and not blocking. Author and reviewer are the same person for now (S01 and S02 are both held by the Maintainer), so the framework independence rule is not met; re-review when a second person takes S02.

## Action Items

| Action | Owner | Due |
| --- | --- | --- |
| Decide whether to rename the constant `PROJECT_NAME` (F4) and whether to restyle the summary markers (F3) | S02 | 2026-10-30 |

---

[MIL-004]: ../../milestones/mil-004-configurable-details.md
[UC-001]: ../../uc-001/uc.md
[RC-016]: ./rc-016-create-project-sh.md
[QC-SH-001]: ../../../framework/qc/qc-programming-shell.md
[ceaa7d1]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/ceaa7d18d8908b4d1e3fb089f238c99b883d71e0
