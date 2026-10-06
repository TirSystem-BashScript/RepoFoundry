# SQA Review Record: Design Class Diagrams DCD-001 and DCD-002

## Metadata
| Key | Value |
| --- | --- |
| ID | RC-021 |
| CrossReference | [DCD-001], [DCD-002], [QC-DCD-001], [SD-001], [OC-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-06 | Proposed | Jens Tirsvad Nielsen | S02 | Initial version | [ded26a6] |

---

## Artifact Under Review

- Instances reviewed: [DCD-001] (use case UC-001) and [DCD-002] (the consolidated project model). [DCD-002] was created from [DCD-001] and the two have the same classes, relationships and tables.
- Checklist used: [QC-DCD-001]
- Review date: 2026-10-06
- PlantUML: the diagrams were not rendered. `render-diagrams.sh` needs a PlantUML server and sends the diagram text to it; none is configured. The syntax was read by hand (see finding F3).

## Checklist Results

| # | Criterion | Level | Status | Evidence/Notes |
| --- | --- | --- | --- | --- |
| 1 | SOLID principles applied; no god classes | Mandatory | Pass | Each class has one reason to change: one host API each (`GiteaClient`, `GitHubClient`), local work (`LocalProjectBuilder`), the framework (`FrameworkInstaller`), prompts for credentials (`CredentialCollector`), the project `.env` (`EnvFileWriter`), the report (`SummaryReport`). `ProjectCreator` has two operations and no data. The clients share `GitHost` instead of repeating its three operations. |
| 2 | Visibility markers correct and consistent | Mandatory | Pass | Every attribute and operation has `+` or `-`; the only private operation is `GiteaClient.requestSync`, which no other class calls. Enumeration literals carry no marker, as is usual. |
| 3 | Association, aggregation, composition and dependency correctly distinguished | Mandatory | Pass | Composition where the part cannot outlive the whole (`Run`, `Configuration`, `LocalProject` and their parts); plain association for the links between independent objects; dependency for "creates" and "asks"; generalization for `Repository` and `GitHost`. No aggregation is used. |
| 4 | Multiplicities and navigability specified on all associations | Mandatory | Pass after fix | Found during this review: most associations gave only the target multiplicity. Fixed: both ends now carry a multiplicity and every association has one arrow. Dependencies carry none, as UML does not give them one. |
| 5 | Applied design patterns annotated | Optional | Pass | The Pattern Annotations table names Controller, Facade, Pure Fabrication, Creator, Protection from variations and a data transfer object. |
| 6 | Method signatures traceable to Operation Contracts and Sequence Diagrams | Mandatory | Pass | The Method Traceability table has a row for each of the 20 operations, each naming the [SD-001] message and the contract postcondition. [SD-001] was aligned in the same change (`createRepository(request, license)`, `compose(request)` and others). |
| 7 | Class names consistent with the Domain Model concepts they refine | Mandatory | Pass | The IT terms of [DICT-001] are used (`ProjectRequest` for Project, `Credential` for Access Token, `EnvFile` for Credentials File, and so on). `GitHost` is a class of its own, as the dictionary has one IT term for the PO term. The system concepts without a PO term (`Run`, `ToolCheck`, `PreflightResult`, `PromptSet`, `InstallResult`) are marked as such in the class table. |
| 8 | No circular dependencies | Optional | Pass | Stated and argued in the Dependency Check; `Summary` points at `ProjectRequest` and nothing points back; the helper classes depend on the data classes and the controller, never the other way round. |

## Findings

| # | Finding | Severity | Status |
| --- | --- | --- | --- |
| F1 | Associations gave only the target multiplicity (criterion 4). | Defect | Fixed in both files. |
| F2 | The planned classes `CredentialCollector`, `EnvFileWriter` and `EnvFile` (milestone [MIL-005]) are already in the diagram while the code does not exist yet. | Info | Accepted: the Implementation Mapping marks them "planned for MIL-005", so the diagram is a design for code still to come. |
| F3 | The PlantUML text was not rendered by a tool. | Low | Open: render with `render-diagrams.sh` once a server is chosen. Constructs used are standard (`abstract class`, `enum`, stereotypes, multiplicities, `skinparam`, `hide empty members`). |
| F4 | `Credential` is also the kind of `GITHUB_USER`, which is an account name, not a secret. The dictionary maps Access Token to `Credential`. | Info | Accepted: `kind` tells them apart; `Configuration` holds one to three of them. |

## Overall Verdict

Go — all mandatory criteria pass after the fix for criterion 4, and the optional ones pass. F3 is open and not blocking. Author and reviewer are the same person for now (S01 and S02 are both held by the Maintainer), so the framework independence rule is not met; re-review when a second person takes S02.

## Action Items

| Action | Owner | Due |
| --- | --- | --- |
| Render the diagrams of [DCD-001], [DCD-002], [SD-001] and the other PlantUML blocks with `render-diagrams.sh` once the Maintainer chooses a server | S01 | 2026-10-16 |

---

[DCD-001]: ../../uc-001/dcd.md
[DCD-002]: ../../dcd.md
[SD-001]: ../../uc-001/sd.md
[OC-001]: ../../uc-001/oc.md
[DICT-001]: ../../dictionary.md
[MIL-005]: ../../milestones/mil-005-credentials.md
[QC-DCD-001]: ../../../framework/qc/qc-dcd.md
[ded26a6]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/ded26a658c666bf29d84093cb352e3635e07719b
