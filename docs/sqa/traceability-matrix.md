# Traceability Matrix

## Metadata
| Key | Value |
| --- | --- |
| ID | TM-001 |
| CrossReference | [BC-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-07 | Deprecated | Jens Tirsvad Nielsen | S02 | Added review RC-030 (.env optional) | [24f1507] |
| 2026-10-08 | Accepted | Jens Tirsvad Nielsen | S02 | Added MIL-008 with its review RC-031 (Gitea is the only remote) | [039a28c] |

---

## Purpose

Tracks backward/forward links between artifact instances so that the Business Case's
cross-artifact traceability success criterion is measurable. A row is added or
updated whenever an artifact instance is created or reviewed.

## Traceability Table

| Artifact Instance | Type | Upstream (Backward Link) | Downstream (Forward Link) | Last Reviewed (RC-ID) |
| --- | --- | --- | --- | --- |
| [BC-001] | BC | - | [SA-001], [PP-001], [MIL-001], [MIL-002], [MIL-003], [MIL-004], [MIL-005], [MIL-006], [MIL-007], [MIL-008], [US-001], [UCD-001] | [RC-010], [RC-018], [RC-020], [RC-022], [RC-029], [RC-031] |
| [SA-001] | SA | [BC-001] | [UCD-001], [UC-001], [DICT-001] | [RC-013] |
| [PP-001] | PP | [BC-001], [SA-001] | [MIL-001], [MIL-002], [MIL-003], [MIL-004], [MIL-005], [MIL-006], [MIL-007], [MIL-008] | [RC-012], [RC-018], [RC-020], [RC-022], [RC-031] |
| [MIL-001] | MIL | [BC-001], [PP-001] | [US-001] | [RC-011], [RC-016] |
| [MIL-002] | MIL | [BC-001], [PP-001] | [US-001] | [RC-014], [RC-017] |
| [MIL-003] | MIL | [BC-001], [PP-001] | [US-001] | [RC-015], [RC-017], [RC-031] |
| [MIL-004] | MIL | [BC-001], [PP-001] | [US-001] | [RC-018], [RC-019] |
| [MIL-005] | MIL | [BC-001], [PP-001] | [US-001] | [RC-020] |
| [MIL-006] | MIL | [BC-001], [PP-001] | [US-001] | [RC-022] |
| [MIL-007] | MIL | [BC-001], [PP-001] | [US-001], [UC-002] | [RC-022], [RC-029], [RC-030] |
| [MIL-008] | MIL | [BC-001], [PP-001] | [US-001] | [RC-031] |
| [UCD-001] | UCD | [BC-001], [SA-001] | [US-001], [UC-001], [UC-002] | [RC-009], [RC-023] |
| [US-001] | US | [BC-001], [UCD-001], [MIL-001], [MIL-002], [MIL-003], [MIL-004], [MIL-005], [MIL-006], [MIL-007], [MIL-008] | [UC-001] | [RC-001], [RC-020], [RC-022], [RC-029], [RC-030], [RC-031] |
| [UC-001] | UC | [UCD-001], [US-001], [SA-001] | [SSD-001], [DM-001] | [RC-002], [RC-020], [RC-023], [RC-031] |
| [UC-002] | UC | [UCD-001], [US-001], [SA-001], [BC-001] | [SSD-002], [DM-003] | [RC-023], [RC-029], [RC-030] |
| [SSD-002] | SSD | [UC-002], [DM-003] | [OC-002] | [RC-024], [RC-029] |
| [DM-003] | DM | [UC-002], [UCD-001], [SSD-002], [DICT-001], [DM-001] | [OC-002], [DCD-003] | [RC-025], [RC-029] |
| [OC-002] | OC | [SSD-002], [DM-003] | [SD-002] | [RC-026], [RC-029], [RC-030] |
| [SD-002] | SD | [OC-002], [DCD-003] | [DCD-003] | [RC-027], [RC-029] |
| [DCD-003] | DCD | [DM-003], [SD-002], [DICT-001], [UC-002], [DCD-001] | [DCD-002] | [RC-028], [RC-029], [RC-030] |
| [SSD-001] | SSD | [UC-001] | [OC-001] | [RC-003], [RC-020] |
| [DM-001] | DM | [UC-001], [SSD-001] | [DM-002], [DICT-001], [OC-001], [DCD-001] | [RC-004], [RC-020], [RC-031] |
| [DM-002] | DM | [DM-001] | [DICT-001], [DCD-001], [DCD-002] | [RC-005], [RC-020], [RC-025], [RC-029], [RC-031] |
| [DICT-001] | DICT | [BC-001], [SA-001], [DM-001], [DM-002] | [OC-001], [SD-001] | [RC-008], [RC-020], [RC-025], [RC-029] |
| [OC-001] | OC | [SSD-001], [DM-001] | [SD-001] | [RC-006], [RC-020], [RC-026], [RC-031] |
| [SD-001] | SD | [OC-001] | [DCD-001] | [RC-007], [RC-020], [RC-021], [RC-031] |
| [DCD-001] | DCD | [UC-001], [DM-001], [DM-002], [OC-001], [SD-001], [DICT-001] | [DCD-002] | [RC-021], [RC-031] |
| [DCD-002] | DCD | [DCD-001], [DCD-003], [DM-002], [DICT-001] | - | [RC-021], [RC-028], [RC-029], [RC-030], [RC-031] |

## Coverage Notes

- Reviewed so far: every artifact in the project (see the Last Reviewed column).
- No ERD, KPI, BMC or BPMN exists yet. `-` in Downstream means nothing is built on the artifact yet.

---

[BC-001]: ../business-case.md
[SA-001]: ../stakeholder-analysis.md
[PP-001]: ../project-plan.md
[MIL-001]: ../milestones/mil-001-foundation.md
[MIL-002]: ../milestones/mil-002-repositories-and-mirror.md
[MIL-003]: ../milestones/mil-003-scaffold-and-release.md
[MIL-004]: ../milestones/mil-004-configurable-details.md
[MIL-005]: ../milestones/mil-005-credentials.md
[MIL-006]: ../milestones/mil-006-project-license.md
[MIL-007]: ../milestones/mil-007-framework-checklists.md
[MIL-008]: ../milestones/mil-008-gitea-only-remote.md
[RC-018]: ./reviews/rc-018-mil-004.md
[RC-019]: ./reviews/rc-019-mil-004-code.md
[RC-020]: ./reviews/rc-020-mil-005.md
[RC-021]: ./reviews/rc-021-dcd.md
[RC-022]: ./reviews/rc-022-mil-007.md
[RC-023]: ./reviews/rc-023-uc-002.md
[RC-024]: ./reviews/rc-024-ssd-002.md
[RC-025]: ./reviews/rc-025-dm-003.md
[RC-026]: ./reviews/rc-026-oc-002.md
[RC-027]: ./reviews/rc-027-sd-002.md
[RC-028]: ./reviews/rc-028-dcd-003.md
[RC-029]: ./reviews/rc-029-default-config-files.md
[RC-030]: ./reviews/rc-030-env-optional.md
[RC-031]: ./reviews/rc-031-gitea-only-remote.md
[DCD-001]: ../uc-001/dcd.md
[DCD-002]: ../dcd.md
[UCD-001]: ../use-case-diagram.md
[US-001]: ../user-stories.md
[UC-001]: ../uc-001/uc.md
[UC-002]: ../uc-002/uc.md
[SSD-002]: ../uc-002/ssd.md
[DM-003]: ../uc-002/dm.md
[OC-002]: ../uc-002/oc.md
[SD-002]: ../uc-002/sd.md
[DCD-003]: ../uc-002/dcd.md
[SSD-001]: ../uc-001/ssd.md
[DM-001]: ../uc-001/dm.md
[DM-002]: ../domain-model.md
[DICT-001]: ../dictionary.md
[OC-001]: ../uc-001/oc.md
[SD-001]: ../uc-001/sd.md
[RC-001]: ./reviews/rc-001-user-story.md
[RC-002]: ./reviews/rc-002-uc-001.md
[RC-003]: ./reviews/rc-003-ssd-001.md
[RC-004]: ./reviews/rc-004-dm-001.md
[RC-005]: ./reviews/rc-005-dm-002.md
[RC-006]: ./reviews/rc-006-oc-001.md
[RC-007]: ./reviews/rc-007-sd-001.md
[RC-008]: ./reviews/rc-008-dictionary.md
[RC-009]: ./reviews/rc-009-ucd-001.md
[RC-010]: ./reviews/rc-010-bc-001.md
[RC-011]: ./reviews/rc-011-mil-001.md
[RC-012]: ./reviews/rc-012-pp-001.md
[RC-013]: ./reviews/rc-013-sa-001.md
[RC-014]: ./reviews/rc-014-mil-002.md
[RC-015]: ./reviews/rc-015-mil-003.md
[RC-016]: ./reviews/rc-016-create-project-sh.md
[RC-017]: ./reviews/rc-017-e2e-security-review.md
[24f1507]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/24f15070fc73fb06e61865141fe0b825ea9e821e
[039a28c]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/039a28c01b56f8cf0af73f55d1a604b43d67ba03
