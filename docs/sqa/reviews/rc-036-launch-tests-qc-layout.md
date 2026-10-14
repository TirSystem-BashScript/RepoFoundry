# SQA Review Record: Launch tests follow the qc layout

## Metadata
| Key | Value |
| --- | --- |
| ID | RC-036 |
| CrossReference | [MIL-013], [QC-MIL-001], [MIL-012], [BC-001], [US-001], [PP-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-14 | Accepted | Jens Tirsvad Nielsen | S02 | Initial version: Go, accepted by S02 in chat | pending |

---

## Artifact Under Review

- Instance reviewed: [MIL-013], and the changes it causes in [US-001], [PP-001] and [TM-001].
- Checklist used: [QC-MIL-001]
- Scope: full review of [MIL-013]; the other artifacts were changed, not created, and their change is checked below.
- Language and domain: en / it (the Metadata rows of [MIL-013])
- Language reviewer: none; the reviewer reads the language and knows the domain
- Mode: supervised
- Why: the full test run ends with 2 failed checks in `tests/test-launch.sh` since framework v0.8.0 moved the checklists to `framework/qc/artifacts/`. The phase points the three assertions at the new path; `src/` does not change.
- Review date: 2026-10-14

## Checklist Results

| # | Criterion | Status | Evidence/Notes |
| --- | --- | --- | --- |
| 1 | A concrete deliverable is defined for every gate | Pass | The three assertions of `tests/test-launch.sh` at `framework/qc/artifacts/qc-business-case.md`; no change under `src/`; a full run with no failed check. |
| 2 | Explicit Go/No-Go criteria are stated for each gate | Pass | Four criteria with an objective Go and No-Go: the launch tests, the full run, no source change and no weaker assertion, and the Quality run on `main`. |
| 3 | Dependencies on other milestones are explicitly mapped | Pass | [MIL-012], whose framework pin at v0.8.0 is on `main`. |
| 4 | Each milestone is traceable to a Business Case objective or KPI | Pass | The Business Case ([BC-001]) as tested creation of a project, and [US-001]. No objective is added or changed. |
| 5 | Milestone owner and approving reviewer are identified | Pass | Owner S01, approving reviewer S02. |
| 6 | Milestone has a defined target date consistent with project constraints | Pass | 2027-01-08, proposed in [PP-001]; the day after [MIL-012], which ends Thursday 2027-01-07. The Business Case sets no deadline. |

## Language and Domain Results

| # | Criterion | Status | Evidence/Notes |
| --- | --- | --- | --- |
| 1 | The Metadata table has a `Language` row and a `Domain` row, and neither is a placeholder | Pass | `en` and `it`. |
| 2 | `Language` is a BCP 47 code and `Domain` is a value from the registry's domain list | Pass | `en` is a BCP 47 code. The registry holds no domain list to check `it` against; the action item of [RC-035] still stands. |
| 3 | The content is written in the stated language | Pass | English throughout. |
| 4 | The register matches the one the registry gives for the artifact type | Pass | IT Executive English for MIL. |
| 5 | Domain terms are the PO terms of the domain's dictionary | Pass | |
| 6 | Metadata keys, section headings, IDs and statuses are in English | Pass | |
| 7 | No translated twin exists beside the document | Pass | |
| 8 | A change of language or domain since the previous accepted version has a Version History row | N-A | First version. |
| 9 | A reviewer competent in the domain and the language has confirmed the domain terms | Pass | S02 reads English and knows the domain. |
| 10 | Abbreviations are spelled out on first use | Pass | |

## Change checks on the other artifacts

| Artifact | Change | Status | Evidence/Notes |
| --- | --- | --- | --- |
| [US-001] | [MIL-013] in the CrossReference | Pass | Link only; no story or acceptance criterion changes. |
| [PP-001] | Phase [MIL-013], its window, the Gantt, the scope coverage, the dependency chain, "thirteen phases" and the end date | Pass | Proposed date 2027-01-08. |
| [TM-001] | Row for [MIL-013] and this record; Last Reviewed updated for each changed artifact | Pass | See the matrix. |

Not covered by this review: the test change is the task of [MIL-013] and is checked at its gate.

## Overall Verdict

Go: every criterion of the checklist passes and the changed documents agree with each other. Drafted by Claude Code for S02; the author and reviewer are the same person for now, as in [RC-035]. S02 accepted [MIL-013] in chat on 2026-10-14; the Version History rows of [MIL-013] and the changed documents were set to `Accepted` and the rows before them to `Deprecated`.

## Action Items

| Action | Owner | Due |
| --- | --- | --- |
| None | - | - |

---

[MIL-013]: ../../milestones/mil-013-launch-tests-qc-layout.md
[QC-MIL-001]: ../../../framework/qc/artifacts/qc-milestones-gateways.md
[MIL-012]: ../../milestones/mil-012-release-0-3-5.md
[BC-001]: ../../business-case.md
[US-001]: ../../user-stories.md
[PP-001]: ../../project-plan.md
[TM-001]: ../traceability-matrix.md
[RC-035]: ./rc-035-release-0-3-5.md
