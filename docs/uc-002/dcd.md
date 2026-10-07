# Design Class Diagram

## Metadata
| Key | Value |
| --- | --- |
| ID | DCD-003 |
| CrossReference | [DM-003], [SD-002], [DICT-001], [UC-002], [DCD-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-07 | Proposed | Jens Tirsvad Nielsen | S02 | Initial version | [1cd27f7] |
| 2026-10-07 | Proposed | Jens Tirsvad Nielsen | S02 | Default configuration files: --config and --env, else ./config.env and ./.env in the working folder, else the checkout's | pending |

---

## Purpose and Scope

Covers [UC-002]. Adds the classes that start the script through a command link. `ProjectCreator`, `Configuration` and `Run` are the classes of [DCD-001] and change only as stated under Method Traceability. The consolidated diagram is [DCD-002].

## Diagram

```plantuml
@startuml
class Launcher {
  +resolveCheckout(invocation : Path) : Checkout
  +currentFolder() : WorkingFolder
  +locateConfigFiles(configPath : Path [0..1], envPath : Path [0..1], checkout : Checkout, workingFolder : WorkingFolder) : ConfigFiles
  +startFromWorkingFolder(configPath : Path [0..1], envPath : Path [0..1]) : PromptSet
}
class Checkout {
  -path : Path
  +configFile() : Path
  +envFile() : Path
}
class WorkingFolder {
  -path : Path
  +configFile() : Path [0..1]
  +envFile() : Path [0..1]
}
class ConfigFiles {
  -configFile : Path
  -envFile : Path
}
class ProjectCreator {
  +startProjectCreation(workingFolder : WorkingFolder, configFiles : ConfigFiles) : PromptSet
}
class Run
Launcher "1" --> "1" ProjectCreator : starts
Launcher ..> Checkout : creates
Launcher ..> WorkingFolder : creates
Launcher ..> ConfigFiles : creates
Run "1" *-- "1" ConfigFiles
Run "1" *-- "1" Checkout
Run "1" *-- "1" WorkingFolder
@enduml
```

## Class Table

| Class | Refines (Domain Model concept) | Responsibility | Attributes | Operations |
| --- | --- | --- | --- | --- |
| `Launcher` | Command Link (the object that follows it) | Follows the command link to the checkout, takes the folder the Maintainer stands in, chooses the two configuration files, and starts the run. | none | `resolveCheckout`, `currentFolder`, `locateConfigFiles`, `startFromWorkingFolder` |
| `Checkout` | Checkout | Names the folder that holds the script's own files and the default `config.env` and `.env`. | `path` | `configFile`, `envFile` |
| `WorkingFolder` | Working Folder | Names the base of the default directory of the new project and the files it may hold. | `path` | `configFile`, `envFile` |
| `ConfigFiles` | none (system concept of [OC-002]) | Carries the two files chosen for the `Configuration`. | `configFile`, `envFile` | none |

The concept Command Link has no class: it is a link the Maintainer makes with the shell, and the system only follows it.

## Method Traceability

| Method signature | Operation Contract / SD message |
| --- | --- |
| `Launcher.startFromWorkingFolder(configPath, envPath) : PromptSet` | [SD-002] `startFromWorkingFolder`; P1, P6 |
| `Launcher.resolveCheckout(invocation) : Checkout` | [SD-002] `resolveCheckout(invocation)`; P2 |
| `Launcher.currentFolder() : WorkingFolder` | [SD-002] `currentFolder()`; P3 |
| `Launcher.locateConfigFiles(configPath, envPath, checkout, workingFolder) : ConfigFiles` | [SD-002] `locateConfigFiles(...)`; P5 |
| `WorkingFolder.configFile() : Path [0..1]`, `WorkingFolder.envFile() : Path [0..1]` | [SD-002] `locateConfigFiles`; P5 |
| `Checkout.configFile() : Path`, `Checkout.envFile() : Path` | [SD-002] `locateConfigFiles`; P5 |
| `ProjectCreator.startProjectCreation(workingFolder, configFiles) : PromptSet` | [SD-002] `startProjectCreation`; P4, P6, P7. Replaces the signature of [DCD-001] by adding `workingFolder` and `configFiles` |

## Pattern Annotations

| Pattern | Classes | Rationale |
| --- | --- | --- |
| Controller | `Launcher` | One class takes the system operation of [UC-002] |
| Information Expert | `Launcher`, `Checkout` | The launcher knows the invocation; the checkout knows where its files are |

## Dependency Check

`Launcher` depends on `ProjectCreator`, `Checkout`, `WorkingFolder` and `ConfigFiles`; none of them depends on `Launcher`, so no cycle is added.

---

[DM-003]: ./dm.md
[SD-002]: ./sd.md
[DICT-001]: ../dictionary.md
[UC-002]: ./uc.md
[DCD-001]: ../uc-001/dcd.md
[DCD-002]: ../dcd.md
[1cd27f7]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/1cd27f77ed844773a969210a11de0d8bb98ac98f
