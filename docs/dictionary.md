# Domain Dictionary (PO and IT terms)

## Metadata
| Key | Value |
| --- | --- |
| ID | DICT-001 |
| CrossReference | [BC-001], [SA-001], [DM-001], [DM-002] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-05 | Accepted | Jens Tirsvad Nielsen | S02 | Initial version, terms of UC-001 | [02875ae] |
| 2026-10-06 | Proposed | Jens Tirsvad Nielsen | S02 | The IT terms are also used in DCD-001 and DCD-002<br>InstallResult and Visibility named as design-only types | pending |

---

## Purpose and Scope

Maps each Product Owner (PO) term to its professional IT term. PO language: English (`en`), from the registry's `Languages` section. It covers the concepts of [DM-001] and [DM-002].

## Dictionary

| PO term | Language | IT term | Definition | Used as PO term in | Used as IT term in |
| --- | --- | --- | --- | --- | --- |
| Maintainer | en | Maintainer | The person who creates a new project. | DM, UC, US | OC, SD, DCD |
| Project | en | ProjectRequest | The new software project being set up, with its name, description and visibility. | DM, UC, US | OC, SD, DCD |
| Configuration | en | Configuration | The service addresses and access tokens set up before starting. | DM, UC | OC, SD, DCD |
| Git Host | en | GitHost | A service that holds repositories: Gitea or GitHub. | DM, UC | OC, SD, DCD |
| Access Token | en | Credential | A secret that lets the Maintainer act on a Git Host; never part of an address. | DM, UC | OC, SD, DCD |
| Owner | en | Owner | The user or organization on a Git Host that owns repositories. | DM, UC | OC, SD, DCD |
| Repository | en | Repository | A place on a Git Host that holds a project's history. | DM, UC | OC, SD, DCD |
| Gitea Repository | en | GiteaRepository | The repository on Gitea; the source of truth. | DM, UC | OC, SD, DCD |
| GitHub Repository | en | GitHubRepository | The repository on GitHub; it receives its content from the mirror. | DM, UC | OC, SD, DCD |
| License | en | LicenseFile | The legal terms file (AGPL-3.0) added to the Gitea repository when GitHub is chosen. | DM, UC | OC, SD, DCD |
| Mirror | en | PushMirror | The push mirror that copies a Gitea repository to a GitHub repository. | DM, UC | OC, SD, DCD |
| Local Project | en | LocalProject | The project directory on the Maintainer's machine. | DM, UC | OC, SD, DCD |
| Remote | en | Remote | A named link from a local project to a repository. | DM, UC | OC, SD, DCD |
| Framework | en | Submodule | The SQA-QC-Framework added to a local project; the IT term names how it is attached. | DM, UC | OC, SD, DCD |
| Framework Setup | en | HookSetup | The skills and git hooks installed from the framework, with the plan gate on or off. | DM, UC | OC, SD, DCD |
| Template | en | Template | A framework file copied into a project. | DM, UC | OC, SD, DCD |
| Summary | en | Summary | The report of what was created, skipped or failed and how to continue. | DM, UC | OC, SD, DCD |

## Rules

- The Domain Model, use cases and user stories use the PO term; the Operation
  Contract, Sequence Diagram, Design Class Diagram and ERD use the IT term.
- One IT term per PO term and one PO term per IT term; no synonyms.
- `Run`, `ToolCheck`, `PreflightResult` and `PromptSet` appear in [OC-001] but
  have no PO term: they are system concepts, not domain concepts, and are not
  in the Domain Model.
- `InstallResult` and the enumeration `Visibility` appear only in [DCD-001]:
  `InstallResult` carries the three results of one operation, and `Visibility`
  is the type of the Project and Repository attribute of the same name. Neither
  is a domain concept.
- A new concept in a Domain Model gets a row here in the same change.

---

[BC-001]: ./business-case.md
[SA-001]: ./stakeholder-analysis.md
[DM-001]: ./uc-001/dm.md
[DM-002]: ./domain-model.md
[OC-001]: ./uc-001/oc.md
[DCD-001]: ./uc-001/dcd.md
[02875ae]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/02875aee5f2953473924074eea0056eb31af6b7a
