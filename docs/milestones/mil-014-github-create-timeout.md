# MIL-014 Timeout of a repository create request

## Metadata
| Key | Value |
| --- | --- |
| ID | MIL-014 |
| CrossReference | [BC-001], [US-001], [MIL-013] |
| Language | en |
| Domain | it |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-14 | Accepted | Jens Tirsvad Nielsen | S02 | Initial version | pending |

---

## Purpose

Decide whether the script handles the timeout of a create request, reported in issue 107. With `PROJECT_VISIBILITY=private` the run passed every read-only check and stopped at its first step with `could not reach api.github.com: the request timed out`. Nothing was created on either host. The cause is not known: the log shows curl exit 28 (`--max-time`, 30 seconds, `HTTP_TIMEOUT_SECONDS`), not a difference between private and public. A timeout of a create request has an unknown outcome: the host may have created the repository after the client gave up. The script reports it like a refused request, so a second run may find a repository it does not recognise as its own.

## Deliverable

1. The finding on issue 107: whether the failure repeats, whether it differs for `public`, and how long the create request takes on that network, written as a comment on the issue.
2. A change to the script that treats a timeout of a create request as an unknown outcome: it asks the host whether the repository exists and is empty, continues as for a reused repository when it is, and otherwise stops with a message that says what exists and what does not. The timeout of the create request is set from the finding of item 1.
3. Tests with a stub `curl` that exits 28 on the create request, for both hosts.

No credential, host request or step is added. The read-only checks do not change.

## Go / No-Go Criteria

| # | Criterion (objectively checkable) | Go | No-Go |
| --- | --- | --- | --- |
| 1 | Issue 107 has a comment with the repeated run, the run with `public`, and the time of the create request | Reviewed by S02 | No comment, or a cause stated without a run |
| 2 | With a stub that times out the create request and answers the next read as "repository exists and is empty", the run continues and the step is reported as reused | Tests pass | The run stops, or the step says "created" |
| 3 | With a stub that times out the create request and answers the next read as "not found", the run stops and the message says that nothing was created on that host | Tests pass | A message that implies a repository exists |
| 4 | With a stub that times out the create request and answers the next read with a non-empty repository, the run stops and does not touch it | Tests pass | The run reuses or changes a non-empty repository |
| 5 | The timeout of the create request is the value chosen in the finding, and it appears once in `src/lib/constants.sh` | Reviewed by S02 | A value with no finding behind it, or a second copy |
| 6 | The full run of `tests/run-tests.sh` reports 0 failed checks and 0 failed static checks | Tests pass | A failed check |
| 7 | The Quality run on the tip of `main` after the merge is green | Verified on Gitea | A red run |

## Dependencies

| Depends on | Reason |
| --- | --- |
| [MIL-013] | The full test run has no failed check, so a new failure is told from an old one |

## Traceability

| Business Case objective / KPI / user story | Reference |
| --- | --- |
| Repeatable creation of the repositories and the mirror, with a clear message when it stops | [BC-001] |
| User story US-001.02, repositories and mirror | [US-001] |

## Ownership

| Role | Stakeholder ID (SA) |
| --- | --- |
| Owner | S01 |
| Approving reviewer | S02 |

## Target Date

2027-01-13 — proposed; the Business Case sets no deadline.

## Tasks

| # | Task | Summary | Needs its own Use Case/User Story? | Reference |
| --- | --- | --- | --- | --- |
| 1 | Reproduce the timeout and find the cause | Run the same command again with `--apply`, then once with `PROJECT_VISIBILITY=public` and a throw-away repository name, and time the create request of each (a curl call with `--write-out '%{time_total}'` is enough). Write the result as a comment on issue 107: repeated or not, private against public, the time. Delete the throw-away repositories by hand. No change to the repository. | No | |
| 2 | Handle the timeout of a create request | In `src/lib/repositories.sh` and `src/lib/http.sh`: on curl exit 28 of a create request, read the repository back; continue as reused when it exists and is empty, stop with a message that says what exists when it is not empty or is not found. Set the create timeout in `src/lib/constants.sh` from the finding of task 1. Add the three stub tests of criteria 2 to 4 to `tests/`. Run the full suite. | No | |

---

[BC-001]: ../business-case.md
[US-001]: ../user-stories.md
[MIL-013]: ./mil-013-launch-tests-qc-layout.md
