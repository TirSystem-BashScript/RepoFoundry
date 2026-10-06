# MIL-005 Credentials

## Metadata
| Key | Value |
| --- | --- |
| ID | MIL-005 |
| CrossReference | [BC-001], [US-001], [UC-001], [DCD-001] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-06 | Accepted | Jens Tirsvad Nielsen | S02 | Initial version | pending |

---

## Purpose

Decide whether the script can ask for a credential that `.env` does not provide and create the new project's own `.env`, without exposing a token: asked without echo, written only after a yes, owner-only, ignored by git, never replacing an existing file, and never shown in any output.

## Deliverable

`create-project.sh` that (1) no longer stops when `.env` is missing or lacks a credential but asks for it without echo (`GITEA_TOKEN` always; `GITHUB_PAT` and `GITHUB_USER` once GitHub is chosen), validating each value like one read from `.env`; and (2) after the local project exists, asks whether to create a `.env` in it and, on a yes, writes only the keys the project needs: `GITEA_TOKEN`, and `GITHUB_PAT` and `GITHUB_USER` when GitHub was chosen. The file is readable by its owner only, excluded from git through `.git/info/exclude` (no tracked file changes, nothing is committed) and never replaced without a yes. The README and `.env.example` document it. The tests cover every case.

This changes a security guarantee of the earlier milestones ("a token is never persisted"): a token may now be written to one file, and only after a yes. [BC-001] objective 6, success criterion 1 and the risk table are amended in the same change.

## Go / No-Go Criteria

| # | Criterion (objectively checkable) | Go | No-Go |
| --- | --- | --- | --- |
| 1 | `GITEA_TOKEN` missing from `.env`, or `.env` absent: it is asked, not echoed, validated like a token read from `.env`, and the run continues; the same for `GITHUB_PAT` and `GITHUB_USER` once GitHub is chosen, and never for them when GitHub is not chosen | Tests pass | The run stops with an error, a value is echoed or GitHub credentials are asked without GitHub |
| 2 | An invalid asked value is refused and asked again without showing it; when input ends the run stops before any request to a host and names the key | Tests pass | A request made or a value shown |
| 3 | A credential provided in `.env` is not asked | Tests pass | Any prompt shown |
| 4 | The "create `.env`" question is asked after the local project exists and defaults to no; on no, no file is created and the summary says so | Tests pass | A file written without a yes |
| 5 | On yes the new project's `.env` exists, holds exactly the needed keys (`GITEA_TOKEN`; plus `GITHUB_PAT` and `GITHUB_USER` when GitHub was chosen), has an owner-only mode (600) from the moment it is created, and `git status` in the project does not list it | Tests pass | Another key, another mode or the file listed |
| 6 | An existing `.env` in the project is never replaced without a yes; on no it is kept unchanged and reported | Tests pass | Any replaced without a yes |
| 7 | No token appears in any output, summary, log, remote URL, tracked file or file other than the project's `.env`; searched in every file of the new project and in all output of the tests, including under `bash -x` | Tests pass | Any hit |
| 8 | Only the project's `.env` changed on disk by this feature: no tracked file, no `.gitignore`, no global git configuration is written | Tests pass | Any other change |
| 9 | All acceptance criteria of US-001.05 in [US-001] are met | Verified | Any unmet |

## Dependencies

| Depends on | Reason |
| --- | --- |
| [MIL-004] | Needs the prompt flow and the configuration presets it changed |

## Traceability

| Business Case objective / KPI / user story | Reference |
| --- | --- |
| User story US-001.05 | [US-001] |
| Objective 9 (credentials asked, project `.env`) and the amended objective 6 | [BC-001] |
| Success criteria 1 and 9 | [BC-001] |

## Ownership

| Role | Stakeholder ID (SA) |
| --- | --- |
| Owner | S01 |
| Approving reviewer | S02 |

## Target Date

2026-11-27 — proposed; the Business Case sets no deadline.

## Tasks

| # | Task | Summary | Needs its own Use Case/User Story? | Reference |
| --- | --- | --- | --- | --- |
| 1 | Ask for a credential that `.env` does not provide | `.env` becomes optional. `GITEA_TOKEN` is asked after the configuration is read; `GITHUB_PAT` and `GITHUB_USER` once GitHub is chosen. Read without echo (`read -s`), validated by the existing token and account validators, registered for redaction before any later message, asked again when invalid, a stop naming the key when input ends. A new `lib/credentials.sh` (class `CredentialCollector` of [DCD-001]). Extension 2b of [UC-001]. | Yes | [UC-001] |
| 2 | Create the new project's `.env` | After the local project exists and only after a yes (default no): write the needed keys to `.env` created with `umask 077` and mode 600, never replacing an existing file without a yes, and add `.env` to `.git/info/exclude`. Report it in the summary without showing a value. A new `lib/envfile.sh` (class `EnvFileWriter`). Step 9 and extensions 9c and 9d of [UC-001]. | Yes | [UC-001] |
| 3 | Keep every token out of everything else | The `bash -x` guard, the redaction and the temporary files keep working with credentials that are asked; the asked value never reaches a command line, output, summary or a file other than the project's `.env`. Add the new function groups to the library layout. | No | |
| 4 | Document the feature and its risk | README: credentials may be asked, the project `.env`, what it holds, why it is owner-only and ignored, the risk of a plain-text token on disk, how to say no. `.env.example` and the security decisions section updated. | No | |
| 5 | Test every case | Each credential present, missing and invalid; `.env` absent; no GitHub credentials without GitHub; end of input; the question defaults to no; file contents, mode and git exclusion; an existing `.env`; every token searched for in the output and the project; the existing tests unchanged. | No | |

---

[BC-001]: ../business-case.md
[US-001]: ../user-stories.md
[UC-001]: ../uc-001/uc.md
[DCD-001]: ../uc-001/dcd.md
[MIL-004]: ./mil-004-configurable-details.md
