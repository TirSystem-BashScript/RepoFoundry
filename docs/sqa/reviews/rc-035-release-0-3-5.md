# SQA Review Record: Release 0.3.5

## Metadata
| Key | Value |
| --- | --- |
| ID | RC-035 |
| CrossReference | [MIL-012], [QC-MIL-001], [MIL-011], [BC-001], [US-001], [PP-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-14 | Accepted | Jens Tirsvad Nielsen | S02 | Initial version: Go, accepted by S02 in chat | [4b4ec59] |

---

## Artifact Under Review

- Instance reviewed: [MIL-012], and the changes it causes in [US-001], [PP-001] and [TM-001].
- Checklist used: [QC-MIL-001]
- Scope: full review of [MIL-012]; the other artifacts were changed, not created, and their change is checked below.
- Language and domain: en / it (the Metadata rows of [MIL-012])
- Language reviewer: none; the reviewer reads the language and knows the domain
- Mode: supervised
- Why: the last release is `v0.3.4` (2026-10-13). `CHANGELOG.md` has the `## [0.3.5]` entry since pull request 101, but `VERSION` and the `--version` check still say 0.3.4. The phase bumps the version to 0.3.5 and releases `v0.3.5` with the Release workflow, whose real run stays S01's decision.
- Review date: 2026-10-14

## Checklist Results

| # | Criterion | Status | Evidence/Notes |
| --- | --- | --- | --- |
| 1 | A concrete deliverable is defined for every gate | Pass | Version 0.3.5: `VERSION` and the `--version` check, the existing `## [0.3.5]` changelog entry with `[Unreleased]` empty, the tag `v0.3.5` and its release page, and the moving tag `v0`. What does not change (credentials asked, host requests, steps) is stated. |
| 2 | Explicit Go/No-Go criteria are stated for each gate | Pass | Six criteria, each with an objective Go and No-Go: the version output, the changelog entry, the Quality run and no new test failure, the dry run of the Release workflow, the tag and release page, and the moving tag. |
| 3 | Dependencies on other milestones are explicitly mapped | Pass | [MIL-011], the release process and `0.3.4` baseline it follows. |
| 4 | Each milestone is traceable to a Business Case objective or KPI | Pass | The Business Case ([BC-001]) as the script's release, and [US-001]. No objective is added or changed. |
| 5 | Milestone owner and approving reviewer are identified | Pass | Owner S01, approving reviewer S02. |
| 6 | Milestone has a defined target date consistent with project constraints | Pass | 2027-01-07, proposed in [PP-001]; the window 2027-01-06 (Wednesday) to 2027-01-07 (Thursday) follows [MIL-011], which ends Tuesday 2027-01-05. The Business Case sets no deadline. |

## Language and Domain Results

| # | Criterion | Status | Evidence/Notes |
| --- | --- | --- | --- |
| 1 | The Metadata table has a `Language` row and a `Domain` row, and neither is a placeholder | Pass | `en` and `it`. The registry lists no `PO domain` setting; `it` is the value the artifact skill gives as its example. |
| 2 | `Language` is a BCP 47 code and `Domain` is a value from the registry's domain list | Pass | `en` is a BCP 47 code. The registry holds no domain list to check `it` against; see the action item. |
| 3 | The content is written in the stated language | Pass | English throughout. |
| 4 | The register matches the one the registry gives for the artifact type | Pass | IT Executive English for MIL. |
| 5 | Domain terms are the PO terms of the domain's dictionary | Pass | The terms are those of [MIL-011]. |
| 6 | Metadata keys, section headings, IDs and statuses are in English | Pass | |
| 7 | No translated twin exists beside the document | Pass | |
| 8 | A change of language or domain since the previous accepted version has a Version History row | N-A | First version. |
| 9 | A reviewer competent in the domain and the language has confirmed the domain terms | Pass | S02 reads English and knows the domain. |
| 10 | Abbreviations are spelled out on first use | Pass | |

## Change checks on the other artifacts

| Artifact | Change | Status | Evidence/Notes |
| --- | --- | --- | --- |
| [US-001] | [MIL-012] in the CrossReference | Pass | Link only; no story or acceptance criterion changes. |
| [PP-001] | Phase [MIL-012], its window, the Gantt, the scope coverage, the dependency chain, "twelve phases" and the end date | Pass | Proposed dates 2027-01-06 to 2027-01-07. |
| [TM-001] | Row for [MIL-012] and this record; Last Reviewed updated for each changed artifact | Pass | See the matrix. |

Not covered by this review: the version bump and the release are the tasks of [MIL-012] and are checked at its gate.

## Overall Verdict

Go — every criterion of the checklist passes and the changed documents agree with each other. Drafted by Claude Code for S02; the author and reviewer are the same person for now, as in [RC-034]. S02 accepted [MIL-012] in chat on 2026-10-14; the Version History rows of [MIL-012] and the changed documents were set to `Accepted` and the rows before them to `Deprecated`.

## Action Items

| Action | Owner | Due |
| --- | --- | --- |
| Add a `PO domain` setting and a domain list to the `Languages` section of `docs/artifact-registry.md`, so the `Domain` row can be checked against it | S01 | before the next milestone |

---

[MIL-012]: ../../milestones/mil-012-release-0-3-5.md
[QC-MIL-001]: ../../../framework/qc/artifacts/qc-milestones-gateways.md
[MIL-011]: ../../milestones/mil-011-release-0-3-4.md
[BC-001]: ../../business-case.md
[US-001]: ../../user-stories.md
[PP-001]: ../../project-plan.md
[TM-001]: ../traceability-matrix.md
[RC-034]: ./rc-034-release-0-3-4.md
[4b4ec59]: https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/commit/4b4ec5914d18837229296562d3a7d2283e9aa5fb
