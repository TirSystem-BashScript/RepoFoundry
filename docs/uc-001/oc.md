# Operation Contract

## Metadata
| Key | Value |
| --- | --- |
| ID | OC-001 |
| CrossReference | [SSD-001], [DM-001], [SD-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-08 | Deprecated | Jens Tirsvad Nielsen | S02 | P9: no other remote is associated with the local project (MIL-008) | [039a28c] |
| 2026-10-08 | Accepted | Jens Tirsvad Nielsen | S02 | P15 and two exceptions: `.claude`, `.agents` and `AGENTS.md` are excluded from git; a tracked path is reported (MIL-009) | [08cb484] |

---

Note: since [UC-002] the operation `startProjectCreation` takes the working folder and the chosen configuration files; [OC-002] and [DCD-002] give the current signature and supersede the one shown here. This document stays the scoped view of [UC-001].

Concepts below use the IT terms of [DICT-001] for the PO concepts of [DM-001]. `Run`, `ToolCheck`, `PreflightResult` and `PromptSet` are system concepts with no PO term and are not in the Domain Model.

## Contract: startProjectCreation

| Item | Value |
| --- | --- |
| Operation | `startProjectCreation(): PromptSet` |
| Traces to | `startProjectCreation` in [SSD-001] |
| Concepts | Run, Configuration, ToolCheck |

**Preconditions**

- None; this is the first operation of a Run.

**Postconditions**

- P1. A `Run` instance was created.
- P2. A `Configuration` instance was created from `config.env` and `.env`, with every value validated (including the project details preset in `config.env`). A `Credential` that `.env` did not provide was entered by the Maintainer without echo and validated; every `Credential` is held only in memory.
- P3. A `ToolCheck` instance was created and associated with the `Run`, recording that `git` and `curl` are present and whether `jq` is present.
- P4. The `Run` was associated with a `PromptSet` that is returned.

**Exceptions**

| Condition (failing precondition) | Outcome |
| --- | --- |
| `config.env` is missing, or a value in `config.env` or `.env` is malformed (a preset project detail included) | The `Run` ends with an error naming the key, never its value; nothing was changed |
| A `Credential` is missing and input ends before a valid one is entered | The `Run` ends with an error naming the key; nothing was changed |
| `git` or `curl` is missing | The `Run` ends with an error naming the tool; nothing was changed |

## Contract: provideProjectDetails

| Item | Value |
| --- | --- |
| Operation | `provideProjectDetails(name: String, description: String, visibility: Visibility, giteaOwner: Owner, githubOwner: Owner [0..1], directory: Path, enablePlanGate: Boolean, writeEnvFile: Boolean): Summary` |
| Traces to | `provideProjectDetails` in [SSD-001] |
| Concepts | ProjectRequest, PreflightResult, GiteaRepository, GitHubRepository, LicenseFile, PushMirror, LocalProject, Remote, Submodule, HookSetup, EnvFile, Summary |

**Preconditions**

- A `Run` exists and its `Configuration` is valid (from `startProjectCreation`).
- `githubOwner` is present exactly when the Maintainer chose GitHub.
- The license that applies is not asked: it comes from the `Configuration` (`PROJECT_LICENSE`) or follows the GitHub choice.
- When `githubOwner` is present, the GitHub `Credential`s are known: from `.env`, or entered by the Maintainer without echo and validated before the first request.
- A detail that the `Configuration` defines is not asked: it is taken from the `Configuration`.

**Postconditions**

- P1. A `ProjectRequest` instance was created with the attributes given by the Maintainer or defined by the `Configuration`, and associated with the `Run`.
- P2. A `PreflightResult` instance was created and associated with the `ProjectRequest`, recording that each token needed for the chosen hosts works, that each owner accepts new repositories, that the name is free on the chosen hosts, that the license that applies is offered by Gitea (when a license applies), and the outcome of the SSH test to Gitea on port 10022.
- P3. A `GiteaRepository` instance was created under `giteaOwner` with the given name, description and visibility, and associated with the `ProjectRequest`.
- P4. If a license applies, a `LicenseFile` instance for it was created and associated with the `GiteaRepository`, so that repository is not empty. The license that applies is the one the `Configuration` defines (`PROJECT_LICENSE`; `none` means none), otherwise `AGPL-3.0` if `githubOwner` is present and `visibility` is `public`, otherwise none. If no license applies the `GiteaRepository` has no `LicenseFile` and is empty.
- P5. If `githubOwner` is present, an empty `GitHubRepository` instance was created under `githubOwner` and associated with the `ProjectRequest`.
- P6. If `githubOwner` is present, a `PushMirror` instance was created, associated with the `GiteaRepository` as source and the `GitHubRepository` as target, with its effective sync setting recorded, and a first sync was requested.
- P7. A `LocalProject` instance was created at `directory`, associated with the `ProjectRequest`. If the `GiteaRepository` is not empty, the `LocalProject` holds its history, including the `LicenseFile` commit.
- P8. A `Remote` named `origin` was associated with the `LocalProject`, pointing at the `GiteaRepository` over SSH if the SSH test passed, otherwise over HTTPS, with no credential in its URL.
- P9. No other `Remote` was associated with the `LocalProject`, whether or not `githubOwner` is present: the `GitHubRepository`, when there is one, is reached through the `PushMirror` of P6, not through a remote.
- P10. A `Submodule` named `framework` was associated with the `LocalProject`, and the submodules the framework itself holds (`qc`) were initialised.
- P11. A `HookSetup` instance was associated with the `LocalProject`, recording that skills and git hooks were installed once and, if `enablePlanGate`, that the plan gate was enabled.
- P12. `AGENTS.md` and `docs/artifact-registry.md` exist in the `LocalProject`, each either newly copied from the framework templates or left as it was because the Maintainer declined to replace it.
- P13. A `Summary` instance was created listing every created item, every skipped item and the next step for anything that failed, and is returned. It contains no credential.
- P14. If `writeEnvFile`, an `EnvFile` named `.env` was associated with the `LocalProject`, holding only the `Credential`s the project needs (the Gitea token, and the GitHub token and account name when `githubOwner` is present). It is readable by its owner only and excluded from git without a change to any tracked file, and no `Credential` is shown in any output. If `writeEnvFile` is false, no `EnvFile` was created. An existing `.env` is left as it was unless the Maintainer agreed to replace it.
- P15. If the `Submodule` and the `HookSetup` were created (P10, P11), the paths `.claude`, `.agents` and `AGENTS.md` of the `LocalProject` are excluded from git: each has an entry in the `.git/info/exclude` of the `LocalProject`, whether or not the path exists yet and whether or not the Maintainer declined replacing `AGENTS.md` (P12). No tracked file was changed and no commit was made. A path that git already tracks stays tracked, and the `Summary` lists it as not excluded. `framework`, `.gitmodules` and `docs/artifact-registry.md` are not excluded.

**Exceptions**

| Condition (failing precondition) | Outcome |
| --- | --- |
| A token is invalid, an owner refuses new repositories, or the name is taken on a chosen host (P2) | The `Run` ends before P3; nothing was created; the error names the failed check |
| A license applies and Gitea does not offer it (P2) | The `Run` ends before P3; nothing was created; the error names the license |
| `GiteaRepository` creation fails after a `GitHubRepository` was created (P5, P3 ordering) | The `Summary` lists the `GitHubRepository` as created, the `GiteaRepository` as failed and how to continue |
| `PushMirror` creation fails (P6) | The `Summary` lists both repositories as created, the mirror as failed and how to continue; the local steps are not run |
| `directory` exists, or a target file exists, and the Maintainer declines replacing it (P7, P12) | That item is skipped and listed in the `Summary` |
| A `.env` already exists in the `LocalProject` and the Maintainer declines replacing it (P14) | That item is skipped and listed in the `Summary` |
| A different `core.hooksPath` exists and the Maintainer declines replacing it (P11) | Hooks are not installed and this is listed in the `Summary` |
| The framework's own submodules cannot be fetched (P10) | The `Summary` lists the `framework` `Submodule` as added, its own submodules as failed, and the command `git submodule update --init --recursive` to run by hand |
| SSH to port 10022 fails and the `Submodule` cannot be added (P10) | The `Summary` lists the repositories as created, the submodule as failed, and the SSH prerequisite |
| SSH to port 10022 fails and the Maintainer goes on without the framework (P10, P11, P12, P15) | No `Submodule`, `HookSetup` or template is created and no path is excluded; the `Summary` lists each of these steps as skipped |
| `.claude`, `.agents` or `AGENTS.md` is already tracked by git (P15) | The path stays tracked and is listed in the `Summary` as not excluded; the other paths are excluded |

---

[SSD-001]: ./ssd.md
[DM-001]: ./dm.md
[DICT-001]: ../dictionary.md
[SD-001]: ./sd.md
[OC-002]: ../uc-002/oc.md
[DCD-002]: ../dcd.md
[UC-002]: ../uc-002/uc.md
[039a28c]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/039a28c01b56f8cf0af73f55d1a604b43d67ba03
[08cb484]: https://git.tirsystem.com/TirSystem-BashScript/RepoFoundry/commit/08cb484498bab3d9480decda9df89e9564438185
