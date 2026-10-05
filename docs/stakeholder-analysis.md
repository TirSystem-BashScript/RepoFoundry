# Stakeholder Analysis

## Metadata
| Key | Value |
| --- | --- |
| ID | SA-001 |
| CrossReference | [BC-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-05 | Deprecated | Jens Tirsvad Nielsen | S02 | Initial version | [424f14f] |
| 2026-10-05 | Accepted | Jens Tirsvad Nielsen | S02 | Mitigation points to the UC-001 business rules<br>S03 traced to BC objective 7<br>Sign-off recorded | [02875ae] |

---

## Purpose

Identify who is affected by RepoFoundry and what each needs from it, so owners and reviewers in later artifacts can cite stable IDs. Method: power/interest grid.

## Stakeholder Summary Table

| ID | Name | Role/Title | Organization | Power Level | Interest Level | Quadrant | Primary Concern (Business Language) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S01 | Tirsvad | Product Owner and maintainer | Not stated | HIGH | HIGH | Manage Closely | New projects start from one repeatable, correct setup |
| S02 | Michael Kragh | DevOps, cybersecurity and maintainer | Not stated | HIGH | HIGH | Manage Closely | Credentials are never exposed and the git host integration is safe |
| S03 | GitHub readers | Readers of the published project | Not stated | LOW | MEDIUM | Keep Informed | Clear documentation they can follow and reuse |

## Power/Interest Classification Rationale

- **Manage Closely (S01, S02):** the two maintainers decide scope, accept the result and own the code. For now one person holds both roles, so one person both authors and reviews; this should be revisited when a second person takes S02.
- **Keep Informed (S03):** readers cannot change the project but depend on its README being accurate.

## Primary Concerns and FURPS+ Mapping

| ID | Concern | FURPS+ attribute |
| --- | --- | --- |
| S01 | One command creates both repositories, the mirror and the project | Functionality |
| S02 | No token in output, URLs or files; no silent overwrite | Functionality (security) |
| S02 | A failed step leaves a clear record of what exists | Reliability |
| S03 | Installation, configuration and usage are documented in clear English | Usability |

## Communication Requirements

| ID | Channel | Frequency | Deliverable | Phase / Milestone |
| --- | --- | --- | --- | --- |
| S01 | Pull request review | Per phase | Accepted milestone document | MIL-001, MIL-002, MIL-003 |
| S02 | Pull request review | Per phase | Security review of the changes | MIL-002, MIL-003 |
| S03 | README on GitHub | At release | README.md | MIL-003 |

## Conflicting Interests and Mitigations

| Conflict | Stakeholders | Mitigation |
| --- | --- | --- |
| Convenience of one-step setup against strict consent prompts for every overwrite | S01, S02 | Prompt only where something would be replaced, as set out in the business rules of [UC-001]; steps that only create new items run without asking |

## Traceability Analysis

### Business Goal Alignment

| Stakeholder | Concern | Business Case objective |
| --- | --- | --- |
| S01 | One-command setup | [BC-001] objectives 1–5 |
| S02 | Credential safety, no overwrite | [BC-001] objective 6 |
| S03 | Reusable documentation | [BC-001] objective 7 |

## Sign-Off

Reviewed in [RC-013] on 2026-10-05: Go.

---

[BC-001]: ./business-case.md
[UC-001]: ./uc-001/uc.md
[RC-013]: ./sqa/reviews/rc-013-sa-001.md
[424f14f]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/424f14f4f5577bb47fea41c8f3a655dca953e6d8
[02875ae]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/02875aee5f2953473924074eea0056eb31af6b7a
