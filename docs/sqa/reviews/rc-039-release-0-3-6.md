# SQA Review Record: Release 0.3.6

## Metadata
| Key | Value |
| --- | --- |
| ID | RC-039 |
| CrossReference | [MIL-015], [QC-MIL-001], [MIL-014], [BC-001], [US-001], [PP-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-15 | Accepted | Jens Tirsvad Nielsen | AI as stand-in for S02 | Initial version: Go | pending |

---

## Artifact Under Review

- Instance reviewed: [MIL-015], and the changes it causes in [US-001], [PP-001] and [TM-001].
- Checklist used: [QC-MIL-001]
- Scope: full review of [MIL-015]; the other artifacts were changed, not created, and their change is checked below.
- Language and domain: en / it (the Metadata rows of [MIL-015])
- Language reviewer: none; the reviewer reads the language and knows the domain
- Mode: autonomous, not independent (the reviewer is `AI as stand-in for S02`)
- Why: the last release is `v0.3.5` (2026-10-14). `CHANGELOG.md` holds the timeout changes of [MIL-014] and other changes under `[Unreleased]`, and `VERSION` still says 0.3.5. The phase bumps the version to 0.3.6 and releases `v0.3.6` with the Release workflow, whose real run stays S01's decision.
- Review date: 2026-10-15

## Checklist Results

| # | Criterion | Status | Evidence/Notes |
| --- | --- | --- | --- |
| 1 | A concrete deliverable is defined for every gate | Pass | Version 0.3.6: `VERSION` and the `--version` check, a dated `## [0.3.6]` changelog entry with `[Unreleased]` empty, the tag `v0.3.6` and its release page, and the moving tag `v0`. |
| 2 | Explicit Go/No-Go criteria are stated for each gate | Pass | Six criteria, each with an objective Go and No-Go, as in the release of 0.3.5. |
| 3 | Dependencies on other milestones are explicitly mapped | Pass | [MIL-014], the main change of the release. |
| 4 | Each milestone is traceable to a Business Case objective or KPI | Pass | [BC-001] as the script's release, and [US-001]. No objective is added or changed. |
| 5 | Milestone owner and approving reviewer are identified | Pass | Owner S01, approving reviewer S02. |
| 6 | Milestone has a defined target date consistent with project constraints | Pass | 2027-01-15, proposed in [PP-001]; the window 2027-01-14 to 2027-01-15 follows [MIL-014], which ends 2027-01-13. The Business Case sets no deadline. |

## Language and Domain Results

| # | Criterion | Status | Evidence/Notes |
| --- | --- | --- | --- |
| 1 | The Metadata table has a `Language` row and a `Domain` row, and neither is a placeholder | Pass | `en` and `it`, as in the earlier release milestones. |
| 2 | `Language` is a BCP 47 code and `Domain` is a value from the registry's domain list | Pass | `en` is a BCP 47 code; the registry still holds no domain list, see the action item of [RC-035]. |
| 3 | The content is written in the stated language | Pass | English throughout. |
| 4 | The register matches the one the registry gives for the artifact type | Pass | IT Executive English for MIL. |
| 5 | Domain terms are the PO terms of the domain's dictionary | Pass | The terms are those of the earlier release milestones. |
| 6 | Metadata keys, section headings, IDs and statuses are in English | Pass | |
| 7 | No translated twin exists beside the document | Pass | |
| 8 | A change of language or domain since the previous accepted version has a Version History row | N-A | First version. |
| 9 | A reviewer competent in the domain and the language has confirmed the domain terms | Pass | Stand-in for S02, who reads English and knows the domain; open to S02's challenge. |
| 10 | Abbreviations are spelled out on first use | Pass | |

## Change checks on the other artifacts

| Artifact | Change | Status | Evidence/Notes |
| --- | --- | --- | --- |
| [US-001] | [MIL-015] in the CrossReference | Pass | Link only; no story or acceptance criterion changes. |
| [PP-001] | Phase [MIL-015], its window, the Gantt, the scope coverage, the dependency chain, "fifteen phases" and the end date | Pass | Proposed dates 2027-01-14 to 2027-01-15. |
| [TM-001] | Row for [MIL-015] and this record; the downstream and review columns of [BC-001], [PP-001] and [US-001] | Pass | See the matrix. |

Not covered by this review: the version bump and the release are the tasks of [MIL-015] and are checked at its gate.

## Overall Verdict

Go — every criterion of the checklist passes and the changed documents agree with each other. Autonomous mode: reviewed by Claude Code as stand-in for S02, so the review is not independent and stays open to S02's challenge. The Version History rows of [MIL-015] and the changed documents were set to `Accepted` and the rows before them to `Deprecated`.

## Action Items

| Action | Owner | Due |
| --- | --- | --- |
| Confirm or challenge this stand-in review | S02 | with the release decision |

---

[MIL-015]: ../../milestones/mil-015-release-0-3-6.md
[QC-MIL-001]: ../../../framework/qc/artifacts/qc-milestones-gateways.md
[MIL-014]: ../../milestones/mil-014-github-create-timeout.md
[BC-001]: ../../business-case.md
[US-001]: ../../user-stories.md
[PP-001]: ../../project-plan.md
[TM-001]: ../traceability-matrix.md
[RC-035]: ./rc-035-release-0-3-5.md
