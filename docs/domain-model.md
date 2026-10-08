# Domain Model

## Metadata
| Key | Value |
| --- | --- |
| ID | DM-002 |
| CrossReference | [UC-001], [SSD-001], [DICT-001], [DM-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-08 | Accepted | Jens Tirsvad Nielsen | S02 | A Local Project has one Remote, origin, no longer one or two (MIL-008) | [039a28c] |
| 2026-10-08 | Proposed | Jens Tirsvad Nielsen | S02 | Framework Setup and Template: the folders that hold the skills and the copy of AGENTS.md are ignored by git (UC-001, MIL-009) | pending |

---

## Purpose and Scope

The consolidated model of the project. Use-case models are scoped views; when one changes, this model is checked and updated in the same change. It currently covers [UC-001] "Create a new project" ([DM-001]), which it was created from, and [UC-002] "Start the script as a global command" ([DM-003]). Concept names are the PO terms recorded in [DICT-001].

## Diagram

Concepts, attributes and associations only — no operations.

```plantuml
@startuml
class Maintainer {
  name
}
class Project {
  name
  description
  visibility
}
class Configuration {
  preset project details
}
class "Git Host" as GitHost {
  name
  web address
  API address
}
class "Access Token" as AccessToken {
  kind
}
class Owner {
  name
  kind
}
class Repository {
  name
  description
  visibility
  address
}
class "Gitea Repository" as GiteaRepository
class "GitHub Repository" as GitHubRepository
class License {
  name
}
class Mirror {
  interval
  sync on commit
}
class "Local Project" as LocalProject {
  directory
}
class Remote {
  name
  address
}
class Framework {
  name
  address
}
class "Framework Setup" as FrameworkSetup {
  plan gate enabled
}
class Template {
  name
}
class "Credentials File" as CredentialsFile {
  address
}
class "Command Link" as CommandLink {
  name
  folder
}
class Checkout {
  path
}
class "Working Folder" as WorkingFolder {
  path
}
class Summary {
  created items
  skipped items
  next steps
}

Repository <|-- GiteaRepository
Repository <|-- GitHubRepository

Maintainer "1" --> "0..*" Project : creates
Configuration "1" --> "1..2" GitHost : defines
Configuration "1" --> "1..2" AccessToken : holds
AccessToken "1" --> "1" GitHost : gives access to
GitHost "1" --> "0..*" Owner : has
Owner "1" --> "0..*" Repository : owns
Project "1" --> "1" GiteaRepository : is stored in
Project "1" --> "0..1" GitHubRepository : is also stored in
GiteaRepository "1" --> "0..1" License : has
Mirror "1" --> "1" GiteaRepository : copies from
Mirror "1" --> "1" GitHubRepository : copies to
Mirror "0..*" --> "1" AccessToken : is authorised by
LocalProject "1" --> "1" Project : is the working copy of
LocalProject "1" --> "1" Remote : has
Remote "0..*" --> "1" Repository : points to
LocalProject "1" --> "1" Framework : includes
LocalProject "1" --> "1" FrameworkSetup : has
FrameworkSetup "0..*" --> "1" Framework : is installed from
Framework "1" --> "1..*" Template : provides
LocalProject "1" --> "0..*" Template : contains a copy of
LocalProject "1" --> "0..1" CredentialsFile : has
CredentialsFile "1" --> "1..2" AccessToken : holds a copy of
Summary "1" --> "1" Project : reports on
Maintainer "1" --> "0..*" CommandLink : makes
CommandLink "0..*" --> "1" Checkout : leads to
Maintainer "1" --> "1" WorkingFolder : starts the script in
Checkout "1" --> "1" Configuration : holds by default
WorkingFolder "1" --> "0..1" Configuration : may hold
WorkingFolder "1" --> "0..*" LocalProject : is the base of
@enduml
```

## Concept Table

| Concept | Definition | Attributes | Source (use case / glossary) |
| --- | --- | --- | --- |
| Maintainer | The person who creates a new project (S01 or S02) | name | [UC-001] primary actor |
| Project | The new software project being set up | name, description, visibility | [UC-001] "new project", step 3 |
| Configuration | The service addresses and access tokens the Maintainer has set up before starting, and any project details preset in it | preset project details (optional) | [UC-001] precondition, steps 2 and 3 |
| Git Host | A service that holds repositories: Gitea or GitHub | name, web address, API address | [UC-001] steps 5 to 7 "GitHub", "Gitea" |
| Access Token | A secret that lets the Maintainer act on a Git Host; it is never part of an address | kind | [UC-001] precondition "Gitea token", "GitHub PAT" |
| Owner | The user or organization on a Git Host that owns repositories | name, kind (user or organization) | [UC-001] step 3 "owner" |
| Repository | A place on a Git Host that holds a project's history | name, description, visibility, address | [UC-001] steps 5 and 6 "repository" |
| Gitea Repository | The Repository on Gitea; the source of truth | none beyond Repository | [UC-001] step 6 |
| GitHub Repository | The Repository on GitHub; receives its content from the Mirror | none beyond Repository | [UC-001] step 5 |
| License | The legal terms file added to a Gitea Repository when a license applies: the one set in the Configuration, or AGPL-3.0 when GitHub is chosen, the project is public and none is set | name | [UC-001] step 6 "license" |
| Mirror | The push mirror that copies a Gitea Repository to a GitHub Repository | interval, sync on commit | [UC-001] step 7 "push mirror" |
| Local Project | The project directory on the Maintainer's machine | directory | [UC-001] step 8 "local project" |
| Remote | A named link from a Local Project to a Repository (`origin`) | name, address | [UC-001] step 8 "remote" |
| Framework | The SQA-QC-Framework added to a Local Project | name, address | [UC-001] step 9 "framework submodule" |
| Framework Setup | The skills and git hooks installed from the Framework, with the plan gate on or off; the folders that hold the skills (`.claude`, `.agents`) are ignored by git | plan gate enabled | [UC-001] step 9 "skills and hooks", "plan gate", "excludes from git" |
| Template | A file the Framework provides to copy into a project (`AGENTS.md`, artifact registry); the copy of `AGENTS.md` is ignored by git | name | [UC-001] step 9 "templates", "excludes from git" |
| Credentials File | The file in a Local Project that holds a copy of the Access Tokens (and the GitHub account name) the project needs; readable by its owner only and ignored by git | address | [UC-001] step 9 "credentials file" |
| Command Link | A name in a folder on the shell's search path that leads to the script in the Checkout | name, folder | [UC-002] step 1 "command link" |
| Checkout | The folder that holds RepoFoundry: the script, its own files and by default `config.env` and `.env` | path | [UC-002] step 4 "checkout" |
| Working Folder | The folder in which the Maintainer starts the script, under which the new project is created by default, and which may hold its own `config.env` and `.env` | path | [UC-002] step 2 "working folder" |
| Summary | The report of what was created, skipped or failed and how to continue | created items, skipped items, next steps | [UC-001] step 10 "summary" |

## Association Table

| From | Association (reading direction) | To | Multiplicity |
| --- | --- | --- | --- |
| Maintainer | creates | Project | 1 to 0..* |
| Configuration | defines | Git Host | 1 to 1..2 (GitHub is optional) |
| Configuration | holds | Access Token | 1 to 1..2 |
| Access Token | gives access to | Git Host | 1 to 1 |
| Git Host | has | Owner | 1 to 0..* |
| Owner | owns | Repository | 1 to 0..* |
| Project | is stored in | Gitea Repository | 1 to 1 |
| Project | is also stored in | GitHub Repository | 1 to 0..1 |
| Gitea Repository | has | License | 1 to 0..1 (1 when a license applies) |
| Mirror | copies from | Gitea Repository | 1 to 1 |
| Mirror | copies to | GitHub Repository | 1 to 1 |
| Mirror | is authorised by | Access Token | 0..* to 1 |
| Local Project | is the working copy of | Project | 1 to 1 |
| Local Project | has | Remote | 1 to 1 |
| Remote | points to | Repository | 0..* to 1 |
| Local Project | includes | Framework | 1 to 1 |
| Local Project | has | Framework Setup | 1 to 1 |
| Framework Setup | is installed from | Framework | 0..* to 1 |
| Framework | provides | Template | 1 to 1..* |
| Local Project | contains a copy of | Template | 1 to 0..* |
| Local Project | has | Credentials File | 1 to 0..1 |
| Credentials File | holds a copy of | Access Token | 1 to 1..2 |
| Summary | reports on | Project | 1 to 1 |
| Maintainer | makes | Command Link | 1 to 0..* |
| Command Link | leads to | Checkout | 0..* to 1 |
| Maintainer | starts the script in | Working Folder | 1 to 1 |
| Checkout | holds by default | Configuration | 1 to 1 |
| Working Folder | may hold | Configuration | 1 to 0..1 |
| Working Folder | is the base of | Local Project | 1 to 0..* |

## Generalizations

| General | Specializations | Is-a justification |
| --- | --- | --- |
| Repository | Gitea Repository, GitHub Repository | Each is a Repository with the same name, visibility and owner rules; they differ in role (source of truth against mirror target) |

---

[UC-001]: ./uc-001/uc.md
[UC-002]: ./uc-002/uc.md
[DM-003]: ./uc-002/dm.md
[SSD-001]: ./uc-001/ssd.md
[DICT-001]: ./dictionary.md
[DM-001]: ./uc-001/dm.md
[039a28c]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/039a28c01b56f8cf0af73f55d1a604b43d67ba03
