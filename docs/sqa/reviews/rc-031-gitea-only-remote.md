# SQA Review Record: Gitea is the only remote

## Metadata
| Key | Value |
| --- | --- |
| ID | RC-031 |
| CrossReference | [MIL-008], [QC-MIL-001], [MIL-003], [BC-001], [US-001], [UC-001], [OC-001], [SD-001], [DCD-001], [DCD-002], [DM-001], [DM-002], [PP-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-08 | Proposed | Jens Tirsvad Nielsen | S02 | Initial version | [039a28c] |
| 2026-10-08 | Proposed | Jens Tirsvad Nielsen | S02 | Criterion count of MIL-008 is seven (the version criterion) | pending |

---

## Artifact Under Review

- Instance reviewed: [MIL-008], and the changes it causes in [MIL-003], [BC-001], [US-001], [UC-001], [OC-001], [SD-001], [DCD-001], [DCD-002], [DM-001], [DM-002], [PP-001] and [TM-001].
- Why: a project created by the script had two remotes, `origin` (Gitea) and `github`. The documents required the second one when GitHub was chosen (objective 4, US-001.03, step 8 of [UC-001], P9 of [OC-001]). Gitea already pushes to GitHub through the push mirror, so the second remote is not needed and invites a push that goes around the mirror. The Business Case already expects "a push to `origin` appears on GitHub" (success criterion 3 of [BC-001]).
- Checklist used: [QC-MIL-001] for [MIL-008]. The other artifacts were changed, not created; their change is checked below.
- Review date: 2026-10-08

## Checklist Results (QC-MIL-001)

| # | Criterion | Status | Evidence/Notes |
| --- | --- | --- | --- |
| 1 | A concrete deliverable is defined for every gate | Pass | The script that adds `origin` only, the documents that agree with it, the README and the tests. |
| 2 | Explicit Go/No-Go criteria are stated for each gate | Pass | Seven criteria, each with an objective Go and No-Go: the remote list with and without GitHub, the contents of `.git/config`, an existing `github` remote kept, the other steps unchanged, the documents in agreement, the acceptance criteria of US-001.03, and the version printed by `--version`. |
| 3 | Dependencies on other milestones are explicitly mapped | Pass | [MIL-002] (the mirror makes the second remote unnecessary) and [MIL-003] (the step that changes), each with its reason. |
| 4 | Each milestone is traceable to a Business Case objective or KPI | Pass | Objective 4 and success criteria 1 and 3 of [BC-001], and US-001.03. |
| 5 | Milestone owner and approving reviewer are identified | Pass | Owner S01, approving reviewer S02. |
| 6 | Milestone has a defined target date consistent with project constraints | Pass | 2026-12-18, proposed in [PP-001]; the Business Case sets no deadline. |

## Change checks on the other artifacts

| Artifact | Change | Status | Evidence/Notes |
| --- | --- | --- | --- |
| [BC-001] | Objective 4 names `origin` as the only remote | Pass | Success criterion 3 already says a push to `origin` appears on GitHub. |
| [US-001] | US-001.03 acceptance criterion; [MIL-008] added to the CrossReference | Pass | One given/when/then; it says there is no `github` remote and why. |
| [UC-001] | Postcondition, step 8 and the rule for step 8; the rule for steps 3, 5 and 7 no longer names the remote | Pass | The rule says an existing remote of another name is never removed or replaced. |
| [OC-001] | P9 | Pass | Numbering is kept: P9 now says no other remote was associated, so the references to P10 to P14 in [SD-001] and [DCD-002] still hold. |
| [SD-001] | `build(directory, giteaRepository, sshPassed)`, the returned `localProject (remote origin)` and the P9 row | Pass | The GitHub repository is no longer passed to `LocalProjectBuilder`. |
| [DCD-001], [DCD-002] | `build` loses its `target` parameter; `Remote` lists `origin` only; a Local Project has 1 Remote; the `build` mapping row | Pass | Names match [SD-001]; the class table and the mapping table agree with the diagram. |
| [DM-001], [DM-002] | A Local Project has 1 Remote (was 1..2); the Remote description | Pass | Names unchanged. The dictionary needs no change: the term Remote and its definition do not name `github`. |
| [MIL-003] | Criterion 1 and task 1 | Pass | They now say `origin` only and point to [MIL-008]. |
| [PP-001] | Phase [MIL-008], its window, the Gantt, the scope coverage and the dependency chain | Pass | Proposed dates 2026-12-14 to 2026-12-18. |
| [TM-001] | Rows for [MIL-008] and this record; Last Reviewed updated | Pass | See the matrix. |

The code, the README and the tests (the three tasks of [MIL-008]) were changed after S01 waived the plan in chat for this request, so the milestone was not synced as issues first. `create_local_project` adds `origin` only, `github_remote_url` is gone, the README describes the one remote, and `tests/test-local.sh` checks the remote list with and without GitHub, no GitHub address in `.git/config`, and a `github` remote from an earlier version kept. The full suite passed with 1141 checks and no failed static check. Criterion 5 of [MIL-008] is still for S02 to check against the documents.

## Overall Verdict

Pending S02 — drafted by Claude Code for S02. The documents, the code, the README and the tests agree with each other. On a Go from S02 the Version History rows of the changed documents become `Accepted` and the rows before them `Deprecated`.

## Action Items

| Action | Owner | Due |
| --- | --- | --- |
| Confirm the verdict and the proposed dates of [MIL-008] | S02 | 2026-10-15 |
| Decide whether to sync the tasks of [MIL-008] as issues now that the work is done (the plan was waived for this change) | S01 | 2026-10-15 |

---

[MIL-008]: ../../milestones/mil-008-gitea-only-remote.md
[MIL-002]: ../../milestones/mil-002-repositories-and-mirror.md
[MIL-003]: ../../milestones/mil-003-scaffold-and-release.md
[QC-MIL-001]: ../../../framework/qc/qc-milestones-gateways.md
[BC-001]: ../../business-case.md
[US-001]: ../../user-stories.md
[UC-001]: ../../uc-001/uc.md
[OC-001]: ../../uc-001/oc.md
[SD-001]: ../../uc-001/sd.md
[DCD-001]: ../../uc-001/dcd.md
[DCD-002]: ../../dcd.md
[DM-001]: ../../uc-001/dm.md
[DM-002]: ../../domain-model.md
[PP-001]: ../../project-plan.md
[TM-001]: ../traceability-matrix.md
[039a28c]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/039a28c01b56f8cf0af73f55d1a604b43d67ba03
