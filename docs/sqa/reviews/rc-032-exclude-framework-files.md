# SQA Review Record: Framework files excluded from git

## Metadata
| Key | Value |
| --- | --- |
| ID | RC-032 |
| CrossReference | [MIL-009], [QC-MIL-001], [MIL-003], [MIL-005], [BC-001], [US-001], [UC-001], [OC-001], [SD-001], [DCD-001], [DCD-002], [DM-001], [DM-002], [DICT-001], [PP-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-08 | Accepted | Jens Tirsvad Nielsen | S02 | Initial version: draft for S02's decision | pending |

---

## Artifact Under Review

- Instance reviewed: [MIL-009], and the changes it causes in [BC-001], [US-001], [UC-001], [OC-001], [SD-001], [DCD-001], [DCD-002], [DM-001], [DM-002], [DICT-001], [PP-001] and [TM-001].
- Why: a new project gets `.claude` and `.agents` (the framework's skills, made by `install-skills.sh`) and `AGENTS.md` (copied from a framework template). The request is that git excludes these three in the new project after the framework is installed. The phase adds that step, using the `.git/info/exclude` mechanism that [MIL-005] already uses for the project's `.env`.
- Checklist used: [QC-MIL-001] for [MIL-009]. The other artifacts were changed, not created; their change is checked below.
- Review date: 2026-10-08

## Checklist Results (QC-MIL-001)

| # | Criterion | Status | Evidence/Notes |
| --- | --- | --- | --- |
| 1 | A concrete deliverable is defined for every gate | Pass | The script with a new "Git excludes" step that writes `/.claude`, `/.agents` and `/AGENTS.md` to `.git/info/exclude`, shown in the dry-run plan and the summary; the documents that agree with it; the README; the tests; version 0.3.2 and release `v0.3.2`. The cases that are not excluded (framework steps skipped, a tracked path, `framework`, `.gitmodules`, the registry) are stated. |
| 2 | Explicit Go/No-Go criteria are stated for each gate | Pass | Eleven criteria, each with an objective Go and No-Go: ignored and absent from `git status`, only `.git/info/exclude` written, a second run and a file without a final newline, a tracked path, framework steps skipped, paths that must stay visible, dry run and summary, the `.env` exclusion unchanged, the documents in agreement, the acceptance criteria of US-001.03, and the version. Criteria 9 and 10 are "Reviewed by S02" and "Verified", as in [MIL-007] and [MIL-008]. |
| 3 | Dependencies on other milestones are explicitly mapped | Pass | [MIL-003] (the framework, skills and templates steps install the files) and [MIL-005] (the `.git/info/exclude` code is reused), each with its reason. |
| 4 | Each milestone is traceable to a Business Case objective or KPI | Pass | Objective 5 of [BC-001], which this phase extends, and US-001.03. No success criterion fits, so none is cited. |
| 5 | Milestone owner and approving reviewer are identified | Pass | Owner S01, approving reviewer S02. |
| 6 | Milestone has a defined target date consistent with project constraints | Pass | 2026-12-23, proposed in [PP-001]; the window 2026-12-21 (Monday) to 2026-12-23 (Wednesday) follows [MIL-008], which ends Friday 2026-12-18. The Business Case sets no deadline. |

## Change checks on the other artifacts

| Artifact | Change | Status | Evidence/Notes |
| --- | --- | --- | --- |
| [BC-001] | Objective 5 and one in-scope item name the exclusion | Pass | The out-of-scope list (no first commit) is consistent: nothing is committed. |
| [US-001] | US-001.03 acceptance criterion; [MIL-009] in the CrossReference and the Traces row | Pass | One given/when/then. No new story: the behavior belongs to the local-project story, so the count of seven stories is unchanged. |
| [UC-001] | Postcondition, step 9, extension 9f, and a rule for step 9 | Pass | The rule fixes the mechanism (`.git/info/exclude`, never `.gitignore`), the whole folders, the paths that stay visible, and a tracked path. |
| [OC-001] | P15 and two exceptions | Pass | P15 is appended, so P1 to P14 and the references to them in [SD-001], [DCD-001] and [DCD-002] still hold. |
| [SD-001] | Self-message `excludeFromGit(localProject)` in `install`, return `installResult (trackedPaths)`, coverage row P15 | Pass | The pattern is the one already used for `requestSync`. Diagram not rendered (see action items). |
| [DCD-001], [DCD-002] | `FrameworkInstaller.excludeFromGit`, `InstallResult.trackedPaths`, the class table, the method traceability and the DTO sentence | Pass | Names and signature match [SD-001]. Diagram not rendered (see action items). |
| [DM-001], [DM-002], [DICT-001] | Definitions of Framework Setup and Template | Pass | No new concept or attribute, as for Credentials File ("ignored by git"). The use-case model, the project model and the dictionary say the same. |
| [PP-001] | Phase [MIL-009], its window, the Gantt, the scope coverage, the dependency chain, "nine phases" and the end date | Pass | Proposed dates 2026-12-21 to 2026-12-23. |
| [TM-001] | Row for [MIL-009] and this record; Last Reviewed updated for each changed artifact | Pass | See the matrix. |

Mechanical checks run for this review: every link definition of the changed files points at an existing file and none is unused; the Gantt dates fall on the weekdays named above; [MIL-009] has 11 criteria and 5 tasks; `sync-project.sh --milestone MIL-009` parses it (milestone 87, issues #65 to #69 created on Gitea); the new names (`excludeFromGit`, `trackedPaths`, P15) are the same in every document that uses them.

Not covered by this review: the code, the README and the tests (tasks 2 to 5 of [MIL-009]) do not exist yet. Criteria 1 to 8, 10 and 11 of [MIL-009] are checked at its gate, not here; criterion 9 is checked then too.

## Consequences S02 accepts with a Go

- The whole folders `.claude` and `.agents` are excluded, as requested, not only their `skills` folders. Anything else a project keeps there (settings, agents) is not tracked either.
- The entries live in `.git/info/exclude`, which belongs to the clone. A fresh clone has neither the entries nor the files. The skills can be made again with `install-skills.sh`; `AGENTS.md` cannot, because it is a copy of a template that the project edits.

## Overall Verdict

Go — every criterion of the checklist passes and the changed documents agree with each other. One check was not done: the PlantUML diagrams of [SD-001], [DCD-001] and [DCD-002] were not rendered, because no PlantUML server is configured and the framework does not choose one. Drafted by Claude Code for S02; the author and reviewer are the same person for now, as in [RC-031]. S02 gave the Go in chat on 2026-10-08, accepted the consequences listed above, and waived the diagram check; the Version History rows of [MIL-009] and the changed documents were set to `Accepted` and the rows before them to `Deprecated`.

## Action Items

| Action | Owner | Due |
| --- | --- | --- |
| None. The diagram check was waived by S02 in chat on 2026-10-08; the three diagrams stay unrendered, and a syntax error found later is fixed in the document concerned | - | - |

---

[MIL-009]: ../../milestones/mil-009-exclude-framework-files.md
[QC-MIL-001]: ../../../framework/qc/qc-milestones-gateways.md
[MIL-003]: ../../milestones/mil-003-scaffold-and-release.md
[MIL-005]: ../../milestones/mil-005-credentials.md
[MIL-007]: ../../milestones/mil-007-framework-checklists.md
[MIL-008]: ../../milestones/mil-008-gitea-only-remote.md
[BC-001]: ../../business-case.md
[US-001]: ../../user-stories.md
[UC-001]: ../../uc-001/uc.md
[OC-001]: ../../uc-001/oc.md
[SD-001]: ../../uc-001/sd.md
[DCD-001]: ../../uc-001/dcd.md
[DCD-002]: ../../dcd.md
[DM-001]: ../../uc-001/dm.md
[DM-002]: ../../domain-model.md
[DICT-001]: ../../dictionary.md
[PP-001]: ../../project-plan.md
[TM-001]: ../traceability-matrix.md
[RC-031]: ./rc-031-gitea-only-remote.md
