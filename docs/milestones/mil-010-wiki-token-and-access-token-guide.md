# MIL-010 Wiki Token Accepted and Access-Token Guide in the Wiki

## Metadata
| Key | Value |
| --- | --- |
| ID | MIL-010 |
| CrossReference | [BC-001], [US-001], [MIL-005] |

## Version History
| Date | Status | Author | Reviewer | Change | Commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-13 | Accepted | Jens Tirsvad Nielsen | S02 | Initial version | [9cca295] |

---

## Purpose

Decide whether one `.env` can serve both RepoFoundry and the publishing of its wiki, and whether the guide for creating the access tokens belongs to the wiki. The wiki is published with its own Gitea token, `TOKEN_FOR_GITEA_WIKI`, which has only the repository write scope. Today `create-project.sh` refuses a `.env` that holds it, because it rejects every key it does not know. The guide for creating the tokens lives in `howto/`, outside the wiki that is published in English, Danish and Bahasa Malaysia.

## Deliverable

`create-project.sh` that accepts `TOKEN_FOR_GITEA_WIKI` in `.env`: the key is optional, checked like the other tokens, kept out of every message and never used or asked for. The credential rules read the same everywhere: `GITEA_TOKEN` is always needed, `GITHUB_PAT` and `GITHUB_USER` only when GitHub is chosen, `TOKEN_FOR_GITEA_WIKI` never. The guide for creating the access tokens moves from `howto/create-access-tokens.md` to the wiki page `AccessTokens`, with a Danish and a Bahasa Malaysia translation and its pictures in `wiki/img/`; `README.md`, the wiki Home pages, the sidebar and the SSH and tokens pages link to it. The tests cover the cases below.

The credentials the script asks for do not change, and no host request changes. The use cases and models are not changed: no concept, operation or class is added. [US-001] gets this phase in its CrossReference and one acceptance criterion on US-001.05.

## Go / No-Go Criteria

| # | Criterion (objectively checkable) | Go | No-Go |
| --- | --- | --- | --- |
| 1 | A `.env` that holds `TOKEN_FOR_GITEA_WIKI` is read without an error, and a `.env` without it behaves as before | Tests pass | An error for the key, or a changed result without it |
| 2 | A value of `TOKEN_FOR_GITEA_WIKI` that is not a valid token is refused with a message that names the key and never shows the value | Tests pass | The value shown, or an invalid value accepted |
| 3 | The value is registered as a secret: it appears in no message, summary or trace, and is never written to the project's own `.env` | Tests pass | The value shown or written |
| 4 | The key is never asked for, with or without GitHub chosen | Tests pass | A prompt for the key |
| 5 | `GITHUB_PAT` and `GITHUB_USER` are asked only when GitHub is chosen, as before | Tests pass | A prompt without GitHub, or none with it |
| 6 | `.env.example` is read without an error and documents the key as optional | Tests pass | An error, or the key undocumented |
| 7 | The page `AccessTokens` exists in English, Danish and Bahasa Malaysia; each translation names the hash of the English page it follows, and the hash matches | Reviewed by S02 | A missing language or a stale hash |
| 8 | The nine pictures are in `wiki/img/`, `howto/` is gone, and no file refers to `howto/` | Reviewed by S02 | A broken or leftover reference |
| 9 | `README.md`, the wiki Home pages, the sidebar and the SSH and tokens pages state the same required and optional keys and link to `AccessTokens` | Reviewed by S02 | A page that contradicts the code |

## Dependencies

| Depends on | Reason |
| --- | --- |
| [MIL-005] | The `.env` parser, the credential checks and the credential prompts are the ones this phase extends |

## Traceability

| Business Case objective / KPI / user story | Reference |
| --- | --- |
| Objective 9 (a credential not provided in `.env` is asked, never exposed) | [BC-001] |
| User story US-001.05 | [US-001] |

## Ownership

| Role | Stakeholder ID (SA) |
| --- | --- |
| Owner | S01 |
| Approving reviewer | S02 |

## Target Date

2026-12-30 — proposed; the Business Case sets no deadline.

## Tasks

| # | Task | Summary | Needs its own Use Case/User Story? | Reference |
| --- | --- | --- | --- | --- |
| 1 | Accept TOKEN_FOR_GITEA_WIKI in .env | Add the key to `CREDENTIAL_KEYS` (`src/lib/constants.sh`) so the parser no longer rejects a `.env` that is shared with the wiki publishing. In `validate_credentials` (`src/lib/config.sh`) register its value as a secret and check it like the other tokens; it is never asked for and never written to the project's own `.env`. Add it, as optional, to `.env.example` and the header of `src/create-project.sh`. Test the key accepted, an invalid value refused without showing it, and `.env.example` read. | No | |
| 2 | Move the access-token guide to the wiki | `git mv` `howto/create-access-tokens.md` to `wiki/AccessTokens.md` and its nine pictures to `wiki/img/`. Add the Danish and Bahasa Malaysia translations with the source-hash header the other pages use, and refresh the hashes of the pages whose English text changed. Link the page from `README.md` (it replaces the `howto/` links), the Home pages, the sidebar and the SSH and tokens pages. | No | |
| 3 | Document which credentials are required | Say in `README.md`, the SSH and tokens pages, the guide and `.env.example` that `GITEA_TOKEN` is always needed, `GITHUB_PAT` and `GITHUB_USER` only when GitHub is chosen (the mirror), and `TOKEN_FOR_GITEA_WIKI` is optional and used only to publish the wiki. | No | |

---

[BC-001]: ../business-case.md
[US-001]: ../user-stories.md
[MIL-005]: ./mil-005-credentials.md
[9cca295]: https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/commit/9cca29579f032538902e9cfe929bb3c7768281ab
