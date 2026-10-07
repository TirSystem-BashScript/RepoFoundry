# SQA Review Record: Default configuration files from the working folder

## Metadata
| Key | Value |
| --- | --- |
| ID | RC-029 |
| CrossReference | [MIL-007], [QC-MIL-001], [UC-002], [BC-001], [US-001], [DM-003], [DM-002], [OC-002], [SD-002], [DCD-003], [DCD-002], [DICT-001], [SSD-002] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-07 | Accepted | Jens Tirsvad Nielsen | S02 | Initial version | [0ab5006] |

---

## Artifact Under Review

- Instance reviewed: the change that makes `./config.env` and `./.env` in the working folder the default configuration files (after `--config` and `--env`, before the checkout's). It touches [MIL-007] and, through it, [BC-001], [US-001], [UC-002], [SSD-002], [DM-003], [DM-002], [OC-002], [SD-002], [DCD-003], [DCD-002] and [DICT-001]. It follows [RC-022] to [RC-028], which reviewed the first version of these documents; where this record disagrees with them, this record applies.
- Checklist used: [QC-MIL-001] for [MIL-007]; the checklists of the other types are applied to the changed parts below.
- Review date: 2026-10-07

## Checklist Results ([MIL-007], QC-MIL-001)

| # | Criterion | Status | Evidence/Notes |
| --- | --- | --- | --- |
| 1 | A concrete deliverable is defined for every gate | Pass | Deliverable 3 now names the folder-first lookup; the code and tests are named in tasks 2 and 4. |
| 2 | Explicit Go/No-Go criteria are stated for each gate | Pass | Criteria 9 and 10 are new and objective: which file is used, that nothing is requested before the yes, and that every file used is named. |
| 3 | Dependencies on other milestones are explicitly mapped | Pass | Unchanged: [MIL-003]. |
| 4 | Each milestone is traceable to a Business Case objective or KPI | Pass | Objective 11 and success criterion 11 of [BC-001] now carry the lookup rule. |
| 5 | Milestone owner and approving reviewer are identified | Pass | Unchanged: S01 and S02. |
| 6 | Milestone has a defined target date consistent with project constraints | Pass | Unchanged: 2026-12-11. |

## Change checks on the other artifacts

| Artifact | Change | Status | Evidence/Notes |
| --- | --- | --- | --- |
| [UC-002] | Precondition, step 4, extensions 4b and 4c, and two rules | Pass | Each file is chosen on its own: named, else `./`, else the checkout's. Extension 4c asks for a yes (default no) before the first request. The use case stays free of implementation detail. |
| [SSD-002] | One sentence: the confirmation is out of scope | Pass | Same convention as the consent questions of [SSD-001]. |
| [DM-003], [DM-002] | Association Working Folder "may hold" Configuration, 1 to 0..1; Working Folder definition | Pass | Both models changed in the same way; multiplicity on both ends. |
| [OC-002] | `ConfigFiles` and a new P5; former P5 and P6 become P6 and P7; two exceptions | Pass | Declarative: the chosen paths are stated as values, not as a search procedure. Each exception names its failing precondition. |
| [SD-002] | `locateConfigFiles`, creation of `ConfigFiles`, a confirmation `alt`, a new signature of `startProjectCreation` | Pass | Every postcondition has a message in the coverage table; `create` is shown for `ConfigFiles`. |
| [DCD-003], [DCD-002] | `ConfigFiles`; `Launcher.locateConfigFiles`; `WorkingFolder.configFile` and `envFile`; the signature of `startProjectCreation` | Pass with a note | Method Traceability covers each new method. The signature of `startProjectCreation` now differs more from [DCD-001], [OC-001] and [SD-001]; this widens the action item of [RC-028]. |
| [DICT-001] | `ConfigFiles` named as a system concept without a PO term | Pass | Treated like `Run` and `PromptSet`, as the dictionary rules allow. |
| [BC-001], [US-001] | Objective 11, scope item and criterion 11; the acceptance criteria of US-002 | Pass | Given/when/then; the confirmation and the naming of files are testable. |

## Risk found in the change

A `config.env` in the working folder can set `GITEA_URL` to another host, and the token from `.env` would then be sent there on the first request. That is why [UC-002] extension 4c and [MIL-007] criterion 10 require the files and the Gitea address to be named and a yes before any request. The yes does not protect a Maintainer who confirms without reading, and it adds one prompt to every run that uses a folder file; if S01 finds the prompt too heavy, the alternative is to confirm only when the address in the folder's `config.env` differs from the checkout's.

## Overall Verdict

Go — the change is consistent across the documents, and the security risk above is answered by a criterion that can be tested. Both conditions were closed on 2026-10-07 as decided by S01: the confirmation is asked every time a file comes from the working folder, and the scoped UC-001 views stay with a note that the newer documents supersede the signature of `startProjectCreation`. Drafted by Claude Code for S02; the author and reviewer are the same person for now. S02 confirmed the verdict on 2026-10-07.

## Action Items

| Action | Owner | Due |
| --- | --- | --- |
| Decide whether the confirmation is asked on every run that uses a folder file, or only when the Gitea address differs from the checkout's | S01 | Closed 2026-10-07: asked every time |
| Settle the `startProjectCreation` signature in [OC-001], [SD-001] and [DCD-001], as in the action item of [RC-028] | S01 | Closed 2026-10-07: note added, see [RC-028] |

---

[MIL-007]: ../../milestones/mil-007-framework-checklists.md
[QC-MIL-001]: ../../../framework/qc/qc-milestones-gateways.md
[UC-002]: ../../uc-002/uc.md
[BC-001]: ../../business-case.md
[US-001]: ../../user-stories.md
[DM-003]: ../../uc-002/dm.md
[DM-002]: ../../domain-model.md
[OC-002]: ../../uc-002/oc.md
[SD-002]: ../../uc-002/sd.md
[DCD-003]: ../../uc-002/dcd.md
[DCD-002]: ../../dcd.md
[DICT-001]: ../../dictionary.md
[SSD-002]: ../../uc-002/ssd.md
[SSD-001]: ../../uc-001/ssd.md
[OC-001]: ../../uc-001/oc.md
[SD-001]: ../../uc-001/sd.md
[DCD-001]: ../../uc-001/dcd.md
[RC-022]: ./rc-022-mil-007.md
[RC-028]: ./rc-028-dcd-003.md
[MIL-003]: ../../milestones/mil-003-scaffold-and-release.md
[0ab5006]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/0ab50068bf9e5be82a801af9dbe5b763eeaf7f31
