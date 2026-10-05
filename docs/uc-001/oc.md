# Operation Contract

## Metadata
| Key | Value |
| --- | --- |
| ID | OC-001 |
| CrossReference | [SSD-001], [DM-001], [SD-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-05 | Accepted | Jens Tirsvad Nielsen | S02 | Initial version | [02875ae] |
| 2026-10-05 | Accepted | Jens Tirsvad Nielsen | S02 | Project details may be defined by the Configuration | [2a6bb8e] |

---

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
- P2. A `Configuration` instance was created from `config.env` and `.env`, with every value validated (including the project details preset in `config.env`) and the credentials held only in memory.
- P3. A `ToolCheck` instance was created and associated with the `Run`, recording that `git` and `curl` are present and whether `jq` is present.
- P4. The `Run` was associated with a `PromptSet` that is returned.

**Exceptions**

| Condition (failing precondition) | Outcome |
| --- | --- |
| `config.env` or `.env` is missing, or a value is missing or malformed (a preset project detail included) | The `Run` ends with an error naming the key, never its value; nothing was changed |
| `git` or `curl` is missing | The `Run` ends with an error naming the tool; nothing was changed |

## Contract: provideProjectDetails

| Item | Value |
| --- | --- |
| Operation | `provideProjectDetails(name: String, description: String, visibility: Visibility, giteaOwner: Owner, githubOwner: Owner [0..1], directory: Path, enablePlanGate: Boolean): Summary` |
| Traces to | `provideProjectDetails` in [SSD-001] |
| Concepts | ProjectRequest, PreflightResult, GiteaRepository, GitHubRepository, LicenseFile, PushMirror, LocalProject, Remote, Submodule, HookSetup, Summary |

**Preconditions**

- A `Run` exists and its `Configuration` is valid (from `startProjectCreation`).
- `githubOwner` is present exactly when the Maintainer chose GitHub.
- A detail that the `Configuration` defines is not asked: it is taken from the `Configuration`.

**Postconditions**

- P1. A `ProjectRequest` instance was created with the attributes given by the Maintainer or defined by the `Configuration`, and associated with the `Run`.
- P2. A `PreflightResult` instance was created and associated with the `ProjectRequest`, recording that each token needed for the chosen hosts works, that each owner accepts new repositories, that the name is free on the chosen hosts, that `AGPL-3.0` is offered by Gitea when GitHub was chosen, and the outcome of the SSH test to Gitea on port 10022.
- P3. A `GiteaRepository` instance was created under `giteaOwner` with the given name, description and visibility, and associated with the `ProjectRequest`.
- P4. If `githubOwner` is present, a `LicenseFile` instance for `AGPL-3.0` was created and associated with the `GiteaRepository`, so that repository is not empty. Otherwise the `GiteaRepository` has no `LicenseFile` and is empty.
- P5. If `githubOwner` is present, an empty `GitHubRepository` instance was created under `githubOwner` and associated with the `ProjectRequest`.
- P6. If `githubOwner` is present, a `PushMirror` instance was created, associated with the `GiteaRepository` as source and the `GitHubRepository` as target, with its effective sync setting recorded, and a first sync was requested.
- P7. A `LocalProject` instance was created at `directory`, associated with the `ProjectRequest`. If the `GiteaRepository` is not empty, the `LocalProject` holds its history, including the `LicenseFile` commit.
- P8. A `Remote` named `origin` was associated with the `LocalProject`, pointing at the `GiteaRepository` over SSH if the SSH test passed, otherwise over HTTPS, with no credential in its URL.
- P9. If `githubOwner` is present, a `Remote` named `github` was associated with the `LocalProject`, pointing at the `GitHubRepository`, with no credential in its URL.
- P10. A `Submodule` named `framework` was associated with the `LocalProject`.
- P11. A `HookSetup` instance was associated with the `LocalProject`, recording that skills and git hooks were installed once and, if `enablePlanGate`, that the plan gate was enabled.
- P12. `AGENTS.md` and `docs/artifact-registry.md` exist in the `LocalProject`, each either newly copied from the framework templates or left as it was because the Maintainer declined to replace it.
- P13. A `Summary` instance was created listing every created item, every skipped item and the next step for anything that failed, and is returned. It contains no credential.

**Exceptions**

| Condition (failing precondition) | Outcome |
| --- | --- |
| A token is invalid, an owner refuses new repositories, or the name is taken on a chosen host (P2) | The `Run` ends before P3; nothing was created; the error names the failed check |
| GitHub was chosen and Gitea does not offer `AGPL-3.0` (P2) | The `Run` ends before P3; nothing was created |
| `GiteaRepository` creation fails after a `GitHubRepository` was created (P5, P3 ordering) | The `Summary` lists the `GitHubRepository` as created, the `GiteaRepository` as failed and how to continue |
| `PushMirror` creation fails (P6) | The `Summary` lists both repositories as created, the mirror as failed and how to continue; the local steps are not run |
| `directory` exists, or a target file exists, and the Maintainer declines replacing it (P7, P12) | That item is skipped and listed in the `Summary` |
| A different `core.hooksPath` exists and the Maintainer declines replacing it (P11) | Hooks are not installed and this is listed in the `Summary` |
| SSH to port 10022 fails and the `Submodule` cannot be added (P10) | The `Summary` lists the repositories as created, the submodule as failed, and the SSH prerequisite |

---

[SSD-001]: ./ssd.md
[DM-001]: ./dm.md
[DICT-001]: ../dictionary.md
[SD-001]: ./sd.md
[02875ae]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/02875aee5f2953473924074eea0056eb31af6b7a
[2a6bb8e]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/2a6bb8e8afadfe6ca4a621da30e44a372898ca62
