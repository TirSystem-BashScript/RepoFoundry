# SQA Review Record: .env is optional, config.env is required

## Metadata
| Key | Value |
| --- | --- |
| ID | RC-030 |
| CrossReference | [MIL-007], [QC-MIL-001], [UC-002], [US-001], [OC-002], [DCD-003], [DCD-002], [RC-029] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-07 | Proposed | Jens Tirsvad Nielsen | S02 | Initial version | [24f1507] |

---

## Artifact Under Review

- Instance reviewed: the change that makes `.env` optional while `config.env` stays required, in [MIL-007], [UC-002], [US-001] (US-002), [OC-002], [DCD-003] and [DCD-002]. It follows the merge of the credentials work (MIL-005), where a credential that `.env` does not provide is asked; the first version of these documents, reviewed in [RC-029], said that a missing `.env` stops the run.
- Checklist used: [QC-MIL-001] for [MIL-007]; the checklists of the other types are applied to the changed parts below.
- Review date: 2026-10-07

## Checklist Results ([MIL-007], QC-MIL-001)

| # | Criterion | Status | Evidence/Notes |
| --- | --- | --- | --- |
| 1 | A concrete deliverable is defined for every gate | Pass | Unchanged; task 2 now says `config.env` required and `.env` optional. |
| 2 | Explicit Go/No-Go criteria are stated for each gate | Pass | Criterion 9 is objective in each case: no `config.env` stops the run and names both places; no `.env` goes on and asks for the token; a stop for a missing `.env` is a No-Go. |
| 3 | Dependencies on other milestones are explicitly mapped | Pass | Unchanged. The behaviour now agrees with the credentials milestone that merged first. |
| 4 | Each milestone is traceable to a Business Case objective or KPI | Pass | Unchanged: objective 11 and success criterion 11. |
| 5 | Milestone owner and approving reviewer are identified | Pass | Unchanged. |
| 6 | Milestone has a defined target date consistent with project constraints | Pass | Unchanged. |

## Change checks on the other artifacts

| Artifact | Change | Status | Evidence/Notes |
| --- | --- | --- | --- |
| [UC-002] | Precondition; extension 4b for `config.env` only; new extension 4d for a `.env` found nowhere | Pass | 4d refers to extension 2b of the main use case for the asking of the credential; the use case stays free of implementation detail. |
| [US-001] | US-002 acceptance criterion split in two | Pass | One given/when/then for a missing `config.env` or a broken link, one for a missing `.env`, which points to US-001.05. |
| [OC-002] | P5: `envFile` may be absent; the missing-file exception split | Pass | Declarative; the new row says no error and points to the postcondition of [OC-001] that enters the credential. |
| [DCD-003], [DCD-002] | `envFile` is `[0..1]` on `ConfigFiles` and on `Checkout` | Pass | Multiplicity given; the class table says when it is absent. |
| [SD-002] | Not changed | Pass | The `alt` for "both places for a config file are not found" still holds, because it concerns `config.env`. |

The code and tests were checked against the new wording: `locate_config_file` takes an `optional` word for `.env`, and the tests `test_a_config_file_found_nowhere_stops_before_any_request_and_names_both_places` and `test_a_credentials_file_found_nowhere_means_the_token_is_asked` cover the two cases. The full suite passed with 1136 checks.

## Overall Verdict

Go — the wording now agrees with the credentials behaviour on `main`, with the code and with the tests, and nothing else in the use case changes. Drafted by Claude Code for S02; the author and reviewer are the same person for now. The verdict takes effect, and the Version History rows of the reviewed documents change to `Accepted`, only when S02 confirms it. The open action items of [RC-028] and [RC-029] stay open.

## Action Items

| Action | Owner | Due |
| --- | --- | --- |
| None | - | - |

---

[MIL-007]: ../../milestones/mil-007-framework-checklists.md
[QC-MIL-001]: ../../../framework/qc/qc-milestones-gateways.md
[UC-002]: ../../uc-002/uc.md
[US-001]: ../../user-stories.md
[OC-002]: ../../uc-002/oc.md
[OC-001]: ../../uc-001/oc.md
[DCD-003]: ../../uc-002/dcd.md
[DCD-002]: ../../dcd.md
[RC-029]: ./rc-029-default-config-files.md
[RC-028]: ./rc-028-dcd-003.md
[24f1507]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/24f15070fc73fb06e61865141fe0b825ea9e821e
[SD-002]: ../../uc-002/sd.md
