# SQA Review Record: Wiki token accepted and access-token guide in the wiki

## Metadata
| Key | Value |
| --- | --- |
| ID | RC-033 |
| CrossReference | [MIL-010], [QC-MIL-001], [MIL-005], [BC-001], [US-001], [PP-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-13 | Deprecated | Jens Tirsvad Nielsen | S02 | Initial version: draft for S02's decision | [9cca295] |
| 2026-10-13 | Accepted | Jens Tirsvad Nielsen | S02 | Action item closed: the published wiki did not show the pictures, so the guide references them by their address on `main` | [bfe402d] |

---

## Artifact Under Review

- Instance reviewed: [MIL-010], and the changes it causes in [US-001], [PP-001] and [TM-001].
- Why: the wiki is published with its own Gitea token, `TOKEN_FOR_GITEA_WIKI`, which has only the repository write scope. A `.env` that holds it is refused today, because the parser rejects every key it does not know. The guide for creating the access tokens is also moved from `howto/` into the wiki, which is published in English, Danish and Bahasa Malaysia. The phase adds the key as an optional, never-asked credential, and states which credentials are required when.
- Checklist used: [QC-MIL-001] for [MIL-010]. The other artifacts were changed, not created; their change is checked below.
- Review date: 2026-10-13

## Checklist Results (QC-MIL-001)

| # | Criterion | Status | Evidence/Notes |
| --- | --- | --- | --- |
| 1 | A concrete deliverable is defined for every gate | Pass | `create-project.sh` accepting `TOKEN_FOR_GITEA_WIKI` as an optional key that is checked, masked and never used or asked for; the access-token guide as the wiki page `AccessTokens` in three languages with its pictures in `wiki/img/`; the links in the README, Home pages, sidebar and SSH and tokens pages; the tests. The credentials the script asks for and every host request are stated as unchanged. |
| 2 | Explicit Go/No-Go criteria are stated for each gate | Pass | Nine criteria, each with an objective Go and No-Go: key accepted, invalid value refused without being shown, value registered as a secret and never written, never asked, GitHub keys asked only when GitHub is chosen, `.env.example` read, the page in three languages with matching hashes, no reference to `howto/`, and the documents in agreement. Criteria 7 to 9 are "Reviewed by S02", as in [MIL-009]. |
| 3 | Dependencies on other milestones are explicitly mapped | Pass | [MIL-005], whose `.env` parser, credential checks and prompts are extended, with its reason. |
| 4 | Each milestone is traceable to a Business Case objective or KPI | Pass | Objective 9 of [BC-001] (a credential not provided in `.env` is asked, never exposed), and US-001.05 of [US-001]. |
| 5 | Milestone owner and approving reviewer are identified | Pass | Owner S01, approving reviewer S02. |
| 6 | Milestone has a defined target date consistent with project constraints | Pass | 2026-12-30, proposed in [PP-001]; the window 2026-12-28 (Monday) to 2026-12-30 (Wednesday) follows [MIL-009], which ends Wednesday 2026-12-23. The Business Case sets no deadline. |

## Change checks on the other artifacts

| Artifact | Change | Status | Evidence/Notes |
| --- | --- | --- | --- |
| [US-001] | [MIL-010] in the CrossReference; one acceptance criterion and the Traces row of US-001.05 | Pass | One given/when/then: a `.env` that also holds `TOKEN_FOR_GITEA_WIKI` is read, the key is never asked for and never shown. No new story: the behavior belongs to the credentials story. |
| [PP-001] | Phase [MIL-010], its window, the Gantt, the scope coverage, the dependency chain, "ten phases" and the end date | Pass | Proposed dates 2026-12-28 to 2026-12-30. |
| [TM-001] | Row for [MIL-010] and this record; Last Reviewed updated for each changed artifact | Pass | See the matrix. |

The Business Case, the use cases, the operation contracts and the models are not changed: no concept, operation or class is added, and the credentials the script asks for are the same.

Mechanical checks run for this review: every link definition of the changed files points at an existing file and none is unused; the Gantt dates fall on the weekdays named above; [MIL-010] has 9 criteria and 3 tasks; `sync-project.sh --milestone MIL-010` parses it (milestone 103, issues #83 to #85 created on Gitea); the English page `AccessTokens` and its two translations carry the same hash, and the Home and SSH and tokens translations carry the hash of their changed English pages; the credential tests (`tests/run-tests.sh credentials`) pass, including the new test for the wiki token.

Not covered by this review: the code, the wiki pages and the README are the tasks of [MIL-010] and are checked at its gate. Two tests of the full suite (`test_the_framework_checklists_are_fetched` and `test_an_empty_qc_is_filled_by_a_second_run_and_a_complete_one_is_not_changed`) fail on an untouched `HEAD` as well; they fetch the framework checklists and are not caused by this phase.

## Consequences S02 accepts with a Go

- The shared `publish-wiki` workflow publishes the Markdown pages but not `wiki/img/`: the pictures returned 404 on the published wiki. The three pages therefore reference them by their address on `main` (`raw/branch/main/wiki/img/`), which resolves once the pull request is merged.
- The pictures keep their English labels in the Danish and Bahasa Malaysia pages.

## Overall Verdict

Go — every criterion of the checklist passes and the changed documents agree with each other. Drafted by Claude Code for S02; the author and reviewer are the same person for now, as in [RC-032]. S02 accepted [MIL-010] in chat on 2026-10-13 and asked for this record; the Version History rows of [MIL-010] and the changed documents were set to `Accepted` and the rows before them to `Deprecated`.

## Action Items

| Action | Owner | Due |
| --- | --- | --- |
| Closed 2026-10-13: the check found the pictures missing and the pages now use addresses on `main`. Open: confirm after the merge that the nine pictures show on the published wiki | S01 | After the merge |

---

[MIL-010]: ../../milestones/mil-010-wiki-token-and-access-token-guide.md
[QC-MIL-001]: ../../../framework/qc/artifacts/qc-milestones-gateways.md
[MIL-005]: ../../milestones/mil-005-credentials.md
[MIL-009]: ../../milestones/mil-009-exclude-framework-files.md
[BC-001]: ../../business-case.md
[US-001]: ../../user-stories.md
[PP-001]: ../../project-plan.md
[TM-001]: ../traceability-matrix.md
[RC-032]: ./rc-032-exclude-framework-files.md
[9cca295]: https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/commit/9cca29579f032538902e9cfe929bb3c7768281ab
[bfe402d]: https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/commit/bfe402d217df6559ce9c018011393ba33e199592
