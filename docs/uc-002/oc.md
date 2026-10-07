# Operation Contract

## Metadata
| Key | Value |
| --- | --- |
| ID | OC-002 |
| CrossReference | [SSD-002], [DM-003], [DICT-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-07 | Proposed | Jens Tirsvad Nielsen | S02 | Initial version | pending |

---

Concepts below use the IT terms of [DICT-001] for the PO concepts of [DM-003]. `Run` and `PromptSet` are the system concepts of [OC-001]. The operation `provideProjectDetails` is the one of [OC-001]; the only change is the base of its default `directory`, stated in P4.

## Contract: startFromWorkingFolder

| Item | Value |
| --- | --- |
| Operation | `startFromWorkingFolder(configPath: Path [0..1], envPath: Path [0..1]): PromptSet` |
| Traces to | `startFromWorkingFolder` in [SSD-002] |
| Concepts | Run, CommandLink, Checkout, WorkingFolder, Configuration |

**Preconditions**

- A `CommandLink` exists that leads to the script in a `Checkout`, or the Maintainer started the script by its path.
- The Maintainer is in a `WorkingFolder`.

**Postconditions**

- P1. A `Run` instance was created.
- P2. A `Checkout` instance was created and associated with the `Run`, with `path` set to the folder that holds the script's own files, reached through the `CommandLink`, however many links lie between them.
- P3. A `WorkingFolder` instance was created and associated with the `Run`, with `path` set to the folder in which the Maintainer started the script. It was not changed by following the `CommandLink`.
- P4. The default of `directory` in the `PromptSet` is `./<name>` under the `WorkingFolder`, never under the `Checkout`.
- P5. A `Configuration` instance was created and associated with the `Run` from `configPath`, or from `config.env` in the `Checkout` when `configPath` is absent, and from `envPath`, or from `.env` in the `Checkout` when `envPath` is absent; the validation of [OC-001] `startProjectCreation` P2 and P3 applies.
- P6. The `Run` was associated with a `PromptSet` that is returned.

**Exceptions**

| Condition (failing precondition) | Outcome |
| --- | --- |
| The `Checkout`'s own files are not found from the link target | The `Run` ends with an error naming the folder it looked in; nothing was changed |
| `config.env` or `.env` is not found in the `Checkout` and no path was given (P5) | The `Run` ends with an error naming the path it looked in and the options `--config` and `--env`; nothing was changed |
| A value in `config.env` or `.env` is malformed (P5) | As in [OC-001] `startProjectCreation`: the error names the key, never its value; nothing was changed |

---

[SSD-002]: ./ssd.md
[DM-003]: ./dm.md
[DICT-001]: ../dictionary.md
[OC-001]: ../uc-001/oc.md
