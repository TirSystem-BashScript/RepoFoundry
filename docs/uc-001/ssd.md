# System Sequence Diagram

## Metadata
| Key | Value |
| --- | --- |
| ID | SSD-001 |
| CrossReference | [UC-001], [DM-001], [OC-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-05 | Accepted | Jens Tirsvad Nielsen | S02 | Optional GitHub; choosing GitHub applies the AGPL license to the Gitea repository<br>Cited OC-001 and DM-001 | [02875ae] |
| 2026-10-05 | Accepted | Jens Tirsvad Nielsen | S02 | Parameters may come from config.env; the message is unchanged | pending |

---

## Source Use Case

Create a new project ([UC-001]) — scenario: main success scenario

## Diagram

```plantuml
@startuml
actor Maintainer as A
participant ":System" as S
A -> S : startProjectCreation()
S --> A : prompts for project details
A -> S : provideProjectDetails(name, description, visibility, giteaOwner, githubOwner, directory, enablePlanGate)
S --> A : checks passed
S --> A : creation summary
@enduml
```

## System Operations

| Step | Message | Parameters | Return | Use case step |
| --- | --- | --- | --- | --- |
| 1 | startProjectCreation | none | prompts for project details (after configuration and tool checks) | 1, 2 |
| 2 | provideProjectDetails | name, description, visibility, giteaOwner, githubOwner (optional; given means GitHub is chosen and the Gitea repository gets the AGPL license; omitted means no GitHub and no license), directory, enablePlanGate (each of these may come from `config.env` instead of the Maintainer; the message is unchanged) | checks passed, then a creation summary | 3 to 10 |

Steps 4 to 9 are internal to the system, so one operation covers them. A consent question (step 8a, 9a, 9b) is a prompt from the system and is out of scope for this diagram; failure flows are out of scope here.

## Lifecycle Notes

The system is one script run. It starts with the first operation and ends after the summary; nothing persists between runs.

---

[UC-001]: ./uc.md
[DM-001]: ./dm.md
[OC-001]: ./oc.md
[02875ae]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/02875aee5f2953473924074eea0056eb31af6b7a
