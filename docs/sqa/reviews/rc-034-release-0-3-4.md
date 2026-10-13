# SQA Review Record: Release 0.3.4

## Metadata
| Key | Value |
| --- | --- |
| ID | RC-034 |
| CrossReference | [MIL-011], [QC-MIL-001], [MIL-010], [BC-001], [US-001], [PP-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-13 | Accepted | Jens Tirsvad Nielsen | S02 | Initial version: draft for S02's decision | pending |

---

## Artifact Under Review

- Instance reviewed: [MIL-011], and the changes it causes in [US-001], [PP-001] and [TM-001].
- Why: the last release is `v0.3.3` (2026-10-09), `main` is 24 commits ahead and `VERSION` still says 0.3.3. [MIL-010] added no version bump, so the accepted `TOKEN_FOR_GITEA_WIKI` key and the wiki in three languages are in no release. The phase bumps the version to 0.3.4, writes the changelog entry and releases `v0.3.4` with the Release workflow, whose real run stays S01's decision.
- Checklist used: [QC-MIL-001] for [MIL-011]. The other artifacts were changed, not created; their change is checked below.
- Review date: 2026-10-13

## Checklist Results (QC-MIL-001)

| # | Criterion | Status | Evidence/Notes |
| --- | --- | --- | --- |
| 1 | A concrete deliverable is defined for every gate | Pass | Version 0.3.4: `VERSION` and the `--version` check, a dated `## [0.3.4]` changelog entry with `[Unreleased]` empty, the tag `v0.3.4` and its release page, and the moving tag `v0`. What does not change (credentials asked, host requests, steps, framework pin) is stated. |
| 2 | Explicit Go/No-Go criteria are stated for each gate | Pass | Six criteria, each with an objective Go and No-Go: the version output, the changelog entry, the Quality run and no new test failure, the dry run of the Release workflow, the tag and release page, and the moving tag. Criterion 2 is "Reviewed by S02"; criteria 5 and 6 are "Verified on Gitea". |
| 3 | Dependencies on other milestones are explicitly mapped | Pass | [MIL-010], whose key, wiki pages and guide the release ships and which must be merged first. |
| 4 | Each milestone is traceable to a Business Case objective or KPI | Pass | The Business Case ([BC-001]) as the script's release, and [US-001]. No objective is added or changed. |
| 5 | Milestone owner and approving reviewer are identified | Pass | Owner S01, approving reviewer S02. |
| 6 | Milestone has a defined target date consistent with project constraints | Pass | 2027-01-05, proposed in [PP-001]; the window 2027-01-04 (Monday) to 2027-01-05 (Tuesday) follows [MIL-010], which ends Wednesday 2026-12-30. The Business Case sets no deadline. |

## Change checks on the other artifacts

| Artifact | Change | Status | Evidence/Notes |
| --- | --- | --- | --- |
| [US-001] | [MIL-011] in the CrossReference | Pass | Link only; no story or acceptance criterion changes. |
| [PP-001] | Phase [MIL-011], its window, the Gantt, the scope coverage, the dependency chain, "eleven phases" and the end date | Pass | Proposed dates 2027-01-04 to 2027-01-05. |
| [TM-001] | Row for [MIL-011] and this record; Last Reviewed updated for each changed artifact | Pass | See the matrix. |

Mechanical checks run for this review: every link definition of the changed files points at an existing file and none is unused; the Gantt dates fall on the weekdays named above; [MIL-011] has 6 criteria and 2 tasks; `sync-project.sh --milestone MIL-011` parses it (milestone 104, issues #90 and #91 created on Gitea); the version appears only in `src/lib/constants.sh` and `tests/test-security.sh` outside the changelog and the review records.

Not covered by this review: the version bump, the changelog entry and the release are the tasks of [MIL-011] and are checked at its gate.

## Consequences S02 accepts with a Go

- The release ships everything on `main` since `v0.3.3`, including the wiki and documentation changes, not only the script change.
- The real run of the Release workflow is not started by this record; S01 starts it when the dry run is read.

## Overall Verdict

Go — every criterion of the checklist passes and the changed documents agree with each other. Drafted by Claude Code for S02; the author and reviewer are the same person for now, as in [RC-033]. S02 accepted [MIL-011] in chat on 2026-10-13 and asked for this record; the Version History rows of [MIL-011] and the changed documents were set to `Accepted` and the rows before them to `Deprecated`.

## Action Items

| Action | Owner | Due |
| --- | --- | --- |
| None | - | - |

---

[MIL-011]: ../../milestones/mil-011-release-0-3-4.md
[QC-MIL-001]: ../../../framework/qc/artifacts/qc-milestones-gateways.md
[MIL-010]: ../../milestones/mil-010-wiki-token-and-access-token-guide.md
[BC-001]: ../../business-case.md
[US-001]: ../../user-stories.md
[PP-001]: ../../project-plan.md
[TM-001]: ../traceability-matrix.md
[RC-033]: ./rc-033-wiki-token-and-access-token-guide.md
