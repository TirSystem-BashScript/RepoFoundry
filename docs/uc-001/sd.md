# Sequence Diagram

## Metadata
| Key | Value |
| --- | --- |
| ID | SD-001 |
| CrossReference | [OC-001], [DCD-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-06 | Proposed | Jens Tirsvad Nielsen | S02 | The license that applies is passed to hasLicense and createRepository; no alt on the GitHub choice | [d773fa9] |
| 2026-10-07 | Proposed | Jens Tirsvad Nielsen | S02 | P4: the license passed is AGPL-3.0 only for GitHub with a public project | pending |

---

Design objects are conceptual; in `create-project.sh` each becomes a small function group. [DCD-001] gives each object its class and turns each message below into a method signature.

## Sequence: startProjectCreation

**Realizes:** `startProjectCreation` in [OC-001]

### Diagram

```plantuml
@startuml
actor Maintainer
participant ":ProjectCreator" as PC
participant ":ConfigLoader" as CL
participant ":ToolChecker" as TC
participant ":CredentialCollector" as CC

Maintainer -> PC : startProjectCreation()
activate PC
create CL
PC -> CL : load(config.env, .env)
activate CL
CL --> PC : configuration
deactivate CL
create CC
PC -> CC : collect(configuration, GITEA_TOKEN)
activate CC
CC --> PC : configuration
deactivate CC
create TC
PC -> TC : check(git, curl, jq)
activate TC
TC --> PC : toolCheck
deactivate TC
PC --> Maintainer : promptSet
deactivate PC
destroy CL
destroy CC
destroy TC
@enduml
```

### Pattern Annotations

| Pattern (GRASP / GoF) | Applied to | Rationale |
| --- | --- | --- |
| Controller (GRASP) | `ProjectCreator` | Receives the system operations and coordinates, without doing the work itself |
| Pure Fabrication (GRASP) | `ConfigLoader`, `ToolChecker`, `CredentialCollector` | No domain concept owns parsing, tool checks or asking for a credential; separate small units keep cohesion high |
| Creator (GRASP) | `ConfigLoader` creates `Configuration` | It holds the data needed to build and validate it |

### Postcondition Coverage

| Postcondition (from contract) | Satisfied by message |
| --- | --- |
| P1 Run created | `startProjectCreation` received by `ProjectCreator` |
| P2 Configuration created and validated; a missing credential entered, validated and held in memory | `load(config.env, .env)` and `collect(configuration, GITEA_TOKEN)` |
| P3 ToolCheck created | `check(git, curl, jq)` |
| P4 PromptSet returned | `promptSet` return to the Maintainer |

### Responsibility Check

`ProjectCreator` only sequences three calls; parsing and validation sit in `ConfigLoader`, asking for a missing credential in `CredentialCollector`, tool detection in `ToolChecker`. No object receives every message. Project details preset in `config.env` are read and validated by `ConfigLoader` as part of `configuration`; the second sequence is unchanged, because `provideProjectDetails` receives the same arguments whether they were asked or preset.

## Sequence: provideProjectDetails

**Realizes:** `provideProjectDetails` in [OC-001]

### Diagram

```plantuml
@startuml
actor Maintainer
participant ":ProjectCreator" as PC
participant ":Preflight" as PF
participant ":GiteaClient" as GT
participant ":GitHubClient" as GH
participant ":LocalProjectBuilder" as LB
participant ":FrameworkInstaller" as FI
participant ":SummaryReport" as SR
participant ":CredentialCollector" as CC
participant ":EnvFileWriter" as EW

Maintainer -> PC : provideProjectDetails(name, description, visibility, giteaOwner, githubOwner, directory, enablePlanGate, writeEnvFile)
activate PC
create GT
PC -> GT : new(configuration)
opt githubOwner present
  create GH
  PC -> GH : new(configuration)
end
opt githubOwner present
  create CC
  PC -> CC : collect(configuration, GITHUB_PAT, GITHUB_USER)
  activate CC
  CC --> PC : configuration
  deactivate CC
end
create PF
PC -> PF : check(request)
activate PF
PF -> GT : verifyToken(), ownerAccepts(giteaOwner), nameFree(name)
opt a license applies
  PF -> GT : hasLicense(license)
end
opt githubOwner present
  PF -> GH : verifyToken(), ownerAccepts(githubOwner), nameFree(name)
end
PF --> PC : preflightResult
deactivate PF

opt githubOwner present
  PC -> GH : createEmptyRepository(request)
  activate GH
  GH --> PC : gitHubRepository
  deactivate GH
end

PC -> GT : createRepository(request, license)
activate GT
GT --> PC : giteaRepository
deactivate GT

opt githubOwner present
  PC -> GT : addPushMirror(giteaRepository, gitHubRepository)
  activate GT
  GT -> GT : requestSync(pushMirror)
  GT --> PC : pushMirror
  deactivate GT
end

create LB
PC -> LB : build(directory, giteaRepository, gitHubRepository, sshPassed)
activate LB
LB --> PC : localProject (remotes origin, github)
deactivate LB

create FI
PC -> FI : install(localProject, enablePlanGate)
activate FI
FI --> PC : installResult
deactivate FI

opt writeEnvFile
  create EW
  PC -> EW : write(localProject, configuration, githubOwner present)
  activate EW
  EW --> PC : envFile
  deactivate EW
end

create SR
PC -> SR : compose(request)
SR --> PC : summary
PC --> Maintainer : summary
deactivate PC
destroy PF
destroy GT
destroy GH
destroy LB
destroy FI
destroy CC
destroy EW
destroy SR
@enduml
```

### Pattern Annotations

| Pattern (GRASP / GoF) | Applied to | Rationale |
| --- | --- | --- |
| Controller (GRASP) | `ProjectCreator` | Single entry for the system operation; sequences the steps and stops on the first failure |
| Pure Fabrication (GRASP) | `Preflight`, `LocalProjectBuilder`, `FrameworkInstaller`, `SummaryReport`, `CredentialCollector`, `EnvFileWriter` | Each groups one responsibility that no domain concept owns |
| Facade (GoF) | `GiteaClient`, `GitHubClient` | Hide each host's HTTP API and credential handling behind a small interface; tokens never leave them |
| Protection from variations (GRASP) | Client classes | The `github`-optional and license variations are decided by the controller's `alt` and `opt`, not inside the clients |

### Postcondition Coverage

| Postcondition (from contract) | Satisfied by message |
| --- | --- |
| P1 ProjectRequest created | `provideProjectDetails` received by `ProjectCreator` |
| P2 PreflightResult created, including that the license is offered | `check(request)` and `hasLicense(license)` |
| P3 GiteaRepository created | `createRepository(request, license)` |
| P4 LicenseFile when a license applies, otherwise empty | `createRepository(request, license)`; `license` is the one the `ProjectRequest` carries (`PROJECT_LICENSE`, or AGPL-3.0 when GitHub was chosen and the project is public), and is absent for `none` |
| P2 GitHub credentials known before the first request | `collect(configuration, GITHUB_PAT, GITHUB_USER)` inside `opt githubOwner present` |
| P5 empty GitHubRepository when chosen | `createEmptyRepository(request)` |
| P6 PushMirror and first sync | `addPushMirror(...)` and `requestSync(pushMirror)` |
| P7 LocalProject created, history from Gitea when not empty | `build(directory, ...)` |
| P8 origin remote (SSH if the test passed, else HTTPS) | `build(..., sshPassed)` |
| P9 github remote when chosen | `build(...)` |
| P10 framework Submodule | `install(localProject, ...)` |
| P11 HookSetup, plan gate if chosen | `install(localProject, enablePlanGate)` |
| P12 AGENTS.md and registry copied or kept | `install(...)` returning `templates` |
| P13 Summary created and returned | `compose(request)` and the final return |
| P14 EnvFile created with the needed credentials, owner-only, ignored by git, or none when declined | `write(localProject, configuration, githubOwner present)` inside `opt writeEnvFile` |

### Responsibility Check

`ProjectCreator` sequences and decides on the optional paths but performs no HTTP, git or file work. Host calls are in the two clients, local work in `LocalProjectBuilder` and `FrameworkInstaller`, the credential prompts in `CredentialCollector`, the `.env` in `EnvFileWriter`, reporting in `SummaryReport`, so cohesion stays high and no object receives all messages. Failure handling (exceptions in [OC-001]) is the controller's single stop-and-report rule and is not drawn.

---

[OC-001]: ./oc.md
[DCD-001]: ./dcd.md
[d773fa9]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/d773fa91df5a54090254e12e074880fb6526a9ff
