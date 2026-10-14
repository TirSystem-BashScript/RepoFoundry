# SQA Review Record: Shell code review of the MIL-014 change

## Metadata
| Key | Value |
| --- | --- |
| ID | RC-038 |
| CrossReference | [MIL-014], [QC-SH-001], [RC-019] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-14 | Proposed | Jens Tirsvad Nielsen | AI as stand-in for S02 | Initial version | [0db0fdf] |

---

## Artifact Under Review

- Instance reviewed: the change of task 2 of [MIL-014] (issue #110): `src/lib/api.sh`, `src/lib/constants.sh`, `src/lib/http.sh`, `src/lib/repositories.sh`, `tests/test-hosts.sh` and `CHANGELOG.md`, on branch `handle-create-timeout` (commit `ac6dacd` plus the fix listed below).
- Checklist used: [QC-SH-001]. The rest of the code was reviewed in [RC-019] and the reviews before it.
- Review date: 2026-10-14
- Mode: autonomous, not independent (the reviewer is `AI as stand-in for S02`)
- Tool versions: bash 5.2.37, shellcheck 0.11.0, shfmt 3.14.1 (Windows, Git Bash)

## Checklist Results

| # | Criterion | Status | Evidence/Notes |
| --- | --- | --- | --- |
| 1 | Starts with `#!/usr/bin/env bash` and `set -euo pipefail` | Pass | Unchanged; the library files are sourced. |
| 2 | Every expansion is quoted; lists are arrays; tests use `[[ ]]` and `$(...)` | Pass | `shellcheck` is clean. The new arithmetic test `((HTTP_CURL_STATUS == 28))` compares a number set by `http_request` from curl's exit code. |
| 3 | Names follow the conventions | Pass | `try_api_call`, `settle_timed_out_create` and `HTTP_CURL_STATUS` follow the rules. |
| 4 | Passes `shellcheck` and `bash -n` with no unexplained `disable` comments | Pass | No new `disable`. |
| 5 | Errors go to standard error with an `error:` message and a non-zero exit code | Pass | Every stop goes through `die`; the new messages name the host, the repository and what exists. |
| 6 | Temporary files use `mktemp` with a `trap` cleanup | Pass | Not touched. |
| 7 | No secret is written in the script, echoed, or put on a command line | Pass | The new messages hold the host, the owner and the repository name only. `http_request` is unchanged apart from recording curl's exit code. |
| 8 | A script that changes state defaults to a dry run | Pass | Unchanged. The change adds read requests only (`GET` of the repository and its contents) and no request that changes a host. |
| 9 | A header comment states purpose, usage, options, environment variables and exit codes | Pass | The `Provides:` lines of `api.sh` and `repositories.sh` and the comment of `http_request` name the new functions and `HTTP_CURL_STATUS`. |
| 10 | The script implements a task or design it cites; deviations are recorded | Pass | Task 2 of [MIL-014]. One deviation: the step is reported as `reused` for a repository this run made, as criterion 2 of [MIL-014] says; see finding F2. |
| 11 | Behaviour is tested for success, failure and any disabled or bypass path | Pass | Six new tests with a stub curl that exits 28: GitHub exists and empty, not found, holds content; Gitea exists and empty, not found; and a connection failure that is not read back. The full suite before the fix of F1: 1223 checks, 0 failed; the run after it is recorded on the pull request. |
| 12 | Formatted with `shfmt` | Pass | No difference. |
| 13 | Safe to re-run | Pass | After a stop on "nothing was created" the same command runs again; after "holds content" the existing check of the next run refuses it before any create request. |
| 14 | Bash version and external tools stated | Pass | Unchanged. |
| 15 | A command sequence, constant, path or message used more than once is defined once | Pass | The read-back is the existing `inspect_repository`; `api_call` calls `try_api_call`, so the host switch exists once; the timeout is the one constant `HTTP_TIMEOUT_SECONDS`. |

## Findings

| # | Finding | Severity | Status |
| --- | --- | --- | --- |
| F1 | If the read-back itself times out, the run ended on a plain "request timed out" with no hint that the create request may have succeeded. | Medium | Fixed: `settle_timed_out_create` warns "the request to create the ... timed out; asking ... whether it exists" before it asks; one test asserts the line. |
| F2 | A repository this run made is reported as `reused`, because it takes the same path as an existing empty repository. The `reused` label can read as if it existed before. | Low | Open; follows criterion 2 of [MIL-014]. The warning of F1 says what happened. |
| F3 | Right after a timeout the host may still be filling the repository (for a Gitea license), so the read-back can see `empty` and the license warning of `confirm_reuse` does not appear. The repository is still reused as it is. | Info | Recorded. |
| F4 | `HTTP_TIMEOUT_SECONDS` is 240 for every request, not only the create request, so a host that does not answer holds a read-only check for four minutes. That is S01's chosen value. | Info | Recorded for S01. |

No finding affects credentials, ownership, the mirror direction or the confirmations.

## Overall Verdict

Go once the full suite, rerun after the fix for F1, reports no failed check; every mandatory criterion passes. Reviewed by Claude Code as stand-in for S02 in autonomous mode, not an independent review; S02 may challenge it in the run summary. The status of this record is set to `Accepted` when that run is recorded.

## Action Items

| Action | Owner | Due |
| --- | --- | --- |
| Decide whether the step of a repository made by a timed-out request should be reported as `created` instead of `reused` (F2), and whether read-only checks keep the 240 second wait (F4) | S02 | 2026-10-30 |

---

[MIL-014]: ../../milestones/mil-014-github-create-timeout.md
[QC-SH-001]: ../../../framework/qc/code/qc-programming-shell.md
[RC-019]: ./rc-019-mil-004-code.md
[0db0fdf]: https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/commit/0db0fdf20b59f7d841637fa63b6414e6571d9b59
