# Start the script as a global command

## Metadata
| Key | Value |
| --- | --- |
| ID | UC-002 |
| CrossReference | [UCD-001], [US-001], [SA-001], [BC-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-07 | Proposed | Jens Tirsvad Nielsen | S02 | Initial version | [1cd27f7] |

---

**Format:** Fully Dressed

## Fully Dressed

- **Scope:** RepoFoundry (`create-project.sh`)
- **Level:** user-goal
- **Primary Actor:** Maintainer (S01 or S02; one person holds both roles for now)
- **Stakeholders and Interests:**
  - S01 — the script is started by name from any folder, and the new project lands where S01 stands
  - S02 — starting through a link never reads or writes outside the checkout and the current folder
  - S03 — the README says exactly how to make the command global
- **Preconditions:**
  - The checkout of RepoFoundry exists and holds `config.env` and `.env` as described in the README, or the Maintainer points to them with `--config` and `--env`.
  - A folder that is on the shell's `PATH` exists and the Maintainer may write to it.
- **Postconditions (success guarantee):**
  - A command link exists in a `PATH` folder and leads to the script in the checkout.
  - The Maintainer started the script by that name from a working folder, and use case [UC-001] ran with that working folder as its base: the default directory of the new project is `./<name>` under it.
  - Nothing was written outside the working folder and the new project.

### Main Success Scenario

1. The Maintainer makes the script reachable by name: creates a command link in a `PATH` folder that leads to `src/create-project.sh` in the checkout (the README gives the command).
2. The Maintainer opens a shell in the folder in which the new project is to be created (the working folder).
3. The Maintainer starts the script by the name of the command link.
4. The system follows the command link to the checkout, loads its own files from there, and reads `config.env` and `.env` from the checkout, or from the files named by `--config` and `--env`.
5. The system runs [UC-001] (`<<include>>`) with the working folder as the base of the default directory of the new project.
6. The system reports a summary that names the full path of the new project.

### Extensions (Alternative / Exception Flows)

- 1a. The `PATH` folder is not writable, or not on `PATH`:
  1. The README names the other choices (a folder the Maintainer owns and adds to `PATH`, or an alias); the system is not involved.
- 3a. The command link is broken (the checkout was moved or removed):
  1. The shell reports that the command cannot run; the README says how to recreate the link.
- 4a. The checkout's own files cannot be found from the link target:
  1. The system stops before any change and names the folder it looked in.
- 4b. `config.env` or `.env` is not found:
  1. The system stops before any change, names the path it looked in and says that `--config` and `--env` can point elsewhere.

### Special Requirements / Business Rules

| Step | Rule |
| --- | --- |
| 1 | The command link is made by the Maintainer with the shell, not by the script; the script never edits `PATH`, a shell profile or a system folder |
| 4 | The system finds its own files by following the command link, however many links lie on the way, on every supported platform |
| 4 | `config.env` and `.env` are read from the checkout, never from the working folder, unless `--config` and `--env` name them |
| 5 | The base of the default directory is the working folder, never the checkout |
| 3 to 6 | Behaviour, prompts and summary are the same as when the script is started by its path from the checkout |

### Open Issues

- The README example is tested on Linux, macOS and Git Bash on Windows (MIL-007 criterion 6).

---

[UCD-001]: ../use-case-diagram.md
[US-001]: ../user-stories.md
[SA-001]: ../stakeholder-analysis.md
[BC-001]: ../business-case.md
[1cd27f7]: https://git.tirsystem.com/TirSystem-BashScript/repo_foundry/commit/1cd27f77ed844773a969210a11de0d8bb98ac98f
