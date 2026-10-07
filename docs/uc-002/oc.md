# Operation Contract

## Metadata
| Key | Value |
| --- | --- |
| ID | OC-002 |
| CrossReference | [SSD-002], [DM-003], [DICT-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-07 | Proposed | Jens Tirsvad Nielsen | S02 | Default configuration files: --config and --env, else ./config.env and ./.env in the working folder, else the checkout's | [0ab5006] |
| 2026-10-07 | Proposed | Jens Tirsvad Nielsen | S02 | .env is optional (as in UC-001 extension 2b): only config.env is required; a .env found nowhere means the token is asked | [24f1507] |

---

Concepts below use the IT terms of [DICT-001] for the PO concepts of [DM-003]. `Run` and `PromptSet` are the system concepts of [OC-001]; `ConfigFiles` is a system concept of this contract: the two files chosen for the `Configuration`. The operation `provideProjectDetails` is the one of [OC-001]; the only change is the base of its default `directory`, stated in P4.

## Contract: startFromWorkingFolder

| Item | Value |
| --- | --- |
| Operation | `startFromWorkingFolder(configPath: Path [0..1], envPath: Path [0..1]): PromptSet` |
| Traces to | `startFromWorkingFolder` in [SSD-002] |
| Concepts | Run, CommandLink, Checkout, WorkingFolder, ConfigFiles, Configuration |

**Preconditions**

- A `CommandLink` exists that leads to the script in a `Checkout`, or the Maintainer started the script by its path.
- The Maintainer is in a `WorkingFolder`.

**Postconditions**

- P1. A `Run` instance was created.
- P2. A `Checkout` instance was created and associated with the `Run`, with `path` set to the folder that holds the script's own files, reached through the `CommandLink`, however many links lie between them.
- P3. A `WorkingFolder` instance was created and associated with the `Run`, with `path` set to the folder in which the Maintainer started the script. It was not changed by following the `CommandLink`.
- P4. The default of `directory` in the `PromptSet` is `./<name>` under the `WorkingFolder`, never under the `Checkout`.
- P5. A `ConfigFiles` instance was created and associated with the `Run`. Its `configFile` is `configPath` when given, otherwise `config.env` in the `WorkingFolder` when it exists, otherwise `config.env` in the `Checkout`; its `envFile` is chosen in the same way from `envPath` and `.env`, and is absent when none is found. Each file is chosen on its own. The paths are named in the output before any request to a host.
- P6. A `Configuration` instance was created and associated with the `Run` from the `ConfigFiles`; the validation of [OC-001] `startProjectCreation` P2 and P3 applies.
- P7. The `Run` was associated with a `PromptSet` that is returned.

**Exceptions**

| Condition (failing precondition) | Outcome |
| --- | --- |
| The `Checkout`'s own files are not found from the link target | The `Run` ends with an error naming the folder it looked in; nothing was changed |
| `config.env` is not named and is in neither the `WorkingFolder` nor the `Checkout` (P5) | The `Run` ends with an error naming both places it looked in and the option `--config`; nothing was changed |
| `.env` is not named and is in neither the `WorkingFolder` nor the `Checkout` (P5) | No error: `envFile` is absent, the paths named in the output say so, and a missing `Credential` is entered by the Maintainer as in [OC-001] `startProjectCreation` P2 |
| A chosen file is in the `WorkingFolder` and the Maintainer does not confirm it (P5) | The `Run` ends before any request to a host; nothing was changed |
| A value in `config.env` or `.env` is malformed (P6) | As in [OC-001] `startProjectCreation`: the error names the key, never its value; nothing was changed |

---

[SSD-002]: ./ssd.md
[DM-003]: ./dm.md
[DICT-001]: ../dictionary.md
[OC-001]: ../uc-001/oc.md
[0ab5006]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/0ab50068bf9e5be82a801af9dbe5b763eeaf7f31
[24f1507]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/24f15070fc73fb06e61865141fe0b825ea9e821e
