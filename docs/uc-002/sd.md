# Sequence Diagram

## Metadata
| Key | Value |
| --- | --- |
| ID | SD-002 |
| CrossReference | [OC-002], [DCD-003], [DICT-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-07 | Proposed | Jens Tirsvad Nielsen | S02 | Initial version | [1cd27f7] |

---

Design objects are conceptual; in `create-project.sh` each becomes a small function group. [DCD-003] gives each object its class and turns each message below into a method signature. `ProjectCreator` and `ConfigLoader` are the design objects of [SD-001].

## Sequence: startFromWorkingFolder

**Realizes:** `startFromWorkingFolder` in [OC-002]

### Diagram

```plantuml
@startuml
actor Maintainer
participant ":Launcher" as L
participant ":ProjectCreator" as PC
participant ":Checkout" as CK
participant ":WorkingFolder" as WF

Maintainer -> L : startFromWorkingFolder(configPath, envPath)
activate L
L -> L : resolveCheckout(invocation)
create CK
L -> CK : Checkout(path)
L -> L : currentFolder()
create WF
L -> WF : WorkingFolder(path)
alt the Checkout's own files are not found
  L --> Maintainer : error naming the folder looked in
end
L -> PC : startProjectCreation(checkout, workingFolder, configPath, envPath)
activate PC
alt config.env or .env not found, or a value malformed
  PC --> L : error naming the path or the key
end
PC --> L : promptSet
deactivate PC
L --> Maintainer : promptSet
deactivate L
@enduml
```

### Pattern Annotations

| Pattern (GRASP / GoF) | Applied to | Rationale |
| --- | --- | --- |
| Information Expert | `Launcher.resolveCheckout` | The launcher knows how the script was invoked, so it is the one that can follow the command link |
| Controller | `Launcher` | One object takes the system operation and hands the work to `ProjectCreator`; `ProjectCreator` stays unaware of links |
| Low Coupling | `ProjectCreator` receives `checkout` and `workingFolder` as values | The use case [UC-001] runs unchanged whatever way the script was started |

### Postcondition Coverage

| Postcondition (from contract) | Satisfied by message |
| --- | --- |
| P1 Run | `startFromWorkingFolder` (the run starts with it) |
| P2 Checkout | `resolveCheckout(invocation)` and the creation of `Checkout` |
| P3 WorkingFolder | `currentFolder()` and the creation of `WorkingFolder` |
| P4 default directory under the WorkingFolder | `startProjectCreation(checkout, workingFolder, ...)`; the prompt default is built from `workingFolder` |
| P5 Configuration | `startProjectCreation` loads `config.env` and `.env` from `checkout` or from the given paths (`load` of [SD-001]) |
| P6 PromptSet | the returned `promptSet` |
| Exceptions: files not found; configuration not found or malformed | the two `alt` fragments |

### Responsibility Check

`Launcher` only finds the checkout and the working folder; it reads no configuration and makes no repository. `ProjectCreator` keeps every other responsibility of [SD-001].

---

[OC-002]: ./oc.md
[DCD-003]: ./dcd.md
[DICT-001]: ../dictionary.md
[SD-001]: ../uc-001/sd.md
[1cd27f7]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/1cd27f77ed844773a969210a11de0d8bb98ac98f
