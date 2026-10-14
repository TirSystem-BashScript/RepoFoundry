# MIL-013 Launch tests follow the qc layout

## Metadata
| Key | Value |
| --- | --- |
| ID | MIL-013 |
| CrossReference | [BC-001], [US-001], [MIL-012] |
| Language | en |
| Domain | it |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-14 | Accepted | Jens Tirsvad Nielsen | S02 | Initial version | pending |

---

## Purpose

Decide whether the two launch tests that fail since the framework pin moved are fixed. The full run of `tests/run-tests.sh` ends with 1198 checks and 2 failed: `test_the_framework_checklists_are_fetched` and `test_an_empty_qc_is_filled_by_a_second_run_and_a_complete_one_is_not_changed` in `tests/test-launch.sh`. Both look for `framework/qc/qc-business-case.md`. Since framework v0.8.0 the checklists are in `framework/qc/artifacts/` (and `framework/qc/code/`), so the file is `framework/qc/artifacts/qc-business-case.md`. The script (`src/`) is not at fault: it initialises the nested `qc` submodule and the tests show that it does. The tests only look for one of its files at the old place.

## Deliverable

`tests/test-launch.sh` looks for the checklist at `framework/qc/artifacts/qc-business-case.md` in the three places that name it. Nothing under `src/` changes. The full run of `tests/run-tests.sh` reports no failed check.

## Go / No-Go Criteria

| # | Criterion (objectively checkable) | Go | No-Go |
| --- | --- | --- | --- |
| 1 | `tests/run-tests.sh launch` reports no failed check | Tests pass | Any failed check |
| 2 | The full run of `tests/run-tests.sh` reports 0 failed checks and 0 failed static checks | Tests pass | A failed check |
| 3 | No file under `src/` changes, and the tests still check that the nested `qc` submodule is initialised and that a second run changes nothing | Reviewed by S02 | A source change, or a weaker assertion |
| 4 | The Quality run on the tip of `main` after the merge is green | Verified on Gitea | A red run |

## Dependencies

| Depends on | Reason |
| --- | --- |
| [MIL-012] | The framework pin at v0.8.0 is on `main`; the tests are fixed against that layout |

## Traceability

| Business Case objective / KPI / user story | Reference |
| --- | --- |
| Repeatable, tested creation of a project | [BC-001] |
| User story US-001 | [US-001] |

## Ownership

| Role | Stakeholder ID (SA) |
| --- | --- |
| Owner | S01 |
| Approving reviewer | S02 |

## Target Date

2027-01-08 — proposed; the Business Case sets no deadline.

## Tasks

| # | Task | Summary | Needs its own Use Case/User Story? | Reference |
| --- | --- | --- | --- | --- |
| 1 | Point the launch tests at `framework/qc/artifacts/` | In `tests/test-launch.sh` replace `framework/qc/qc-business-case.md` with `framework/qc/artifacts/qc-business-case.md` in the three assertions (the fetched checklists, the emptied qc and the repaired qc). Keep every other assertion. Run `tests/run-tests.sh launch` and then the full run. | No | |

---

[BC-001]: ../business-case.md
[US-001]: ../user-stories.md
[MIL-012]: ./mil-012-release-0-3-5.md
