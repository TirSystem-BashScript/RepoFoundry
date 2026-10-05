# Traceability Matrix

## Metadata
| Key | Value |
| --- | --- |
| ID | TM-001 |
| CrossReference | [BC-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-05 | Proposed | Jens Tirsvad Nielsen | S02 | Initial version, UC-001 artifacts and baseline | [02875ae] |
| 2026-10-05 | Proposed | Jens Tirsvad Nielsen | S02 | Added MIL-004 and RC-018 | [2a6bb8e] |

---

## Purpose

Tracks backward/forward links between artifact instances so that the Business Case's
cross-artifact traceability success criterion is measurable. A row is added or
updated whenever an artifact instance is created or reviewed.

## Traceability Table

| Artifact Instance | Type | Upstream (Backward Link) | Downstream (Forward Link) | Last Reviewed (RC-ID) |
| --- | --- | --- | --- | --- |
| [BC-001] | BC | - | [SA-001], [PP-001], [MIL-001], [MIL-002], [MIL-003], [MIL-004], [US-001], [UCD-001] | [RC-010], [RC-018] |
| [SA-001] | SA | [BC-001] | [UCD-001], [UC-001], [DICT-001] | [RC-013] |
| [PP-001] | PP | [BC-001], [SA-001] | [MIL-001], [MIL-002], [MIL-003], [MIL-004] | [RC-012], [RC-018] |
| [MIL-001] | MIL | [BC-001], [PP-001] | [US-001] | [RC-011], [RC-016] |
| [MIL-002] | MIL | [BC-001], [PP-001] | [US-001] | [RC-014], [RC-017] |
| [MIL-003] | MIL | [BC-001], [PP-001] | [US-001] | [RC-015], [RC-017] |
| [MIL-004] | MIL | [BC-001], [PP-001] | [US-001] | [RC-018], [RC-019] |
| [UCD-001] | UCD | [BC-001], [SA-001] | [US-001], [UC-001] | [RC-009] |
| [US-001] | US | [BC-001], [UCD-001], [MIL-001], [MIL-002], [MIL-003], [MIL-004] | [UC-001] | [RC-001] |
| [UC-001] | UC | [UCD-001], [US-001], [SA-001] | [SSD-001], [DM-001] | [RC-002] |
| [SSD-001] | SSD | [UC-001] | [OC-001] | [RC-003] |
| [DM-001] | DM | [UC-001], [SSD-001] | [DM-002], [DICT-001], [OC-001] | [RC-004] |
| [DM-002] | DM | [DM-001] | [DICT-001] | [RC-005] |
| [DICT-001] | DICT | [BC-001], [SA-001], [DM-001], [DM-002] | [OC-001], [SD-001] | [RC-008] |
| [OC-001] | OC | [SSD-001], [DM-001] | [SD-001] | [RC-006] |
| [SD-001] | SD | [OC-001] | - | [RC-007] |

## Coverage Notes

- Reviewed so far: every artifact in the project (see the Last Reviewed column).
- No Design Class Diagram, ERD, KPI, BMC or BPMN exists yet. `-` in Downstream means nothing is built on the artifact yet.

---

[BC-001]: ../business-case.md
[SA-001]: ../stakeholder-analysis.md
[PP-001]: ../project-plan.md
[MIL-001]: ../milestones/mil-001-foundation.md
[MIL-002]: ../milestones/mil-002-repositories-and-mirror.md
[MIL-003]: ../milestones/mil-003-scaffold-and-release.md
[MIL-004]: ../milestones/mil-004-configurable-details.md
[RC-018]: ./reviews/rc-018-mil-004.md
[RC-019]: ./reviews/rc-019-mil-004-code.md
[UCD-001]: ../use-case-diagram.md
[US-001]: ../user-stories.md
[UC-001]: ../uc-001/uc.md
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
[02875ae]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/02875aee5f2953473924074eea0056eb31af6b7a
[2a6bb8e]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/2a6bb8e8afadfe6ca4a621da30e44a372898ca62
