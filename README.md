# Repo Foundry

RepoFoundry (`src/create-project.sh`) sets up a new project in one run:

- a **Gitea** repository (the source of truth),
- optionally an empty **GitHub** repository that receives everything through a
  **push mirror from Gitea to GitHub**,
- and a **local project** with credential-free remotes and the
  [SQA-QC-Framework](https://git.tirsystem.com/TirSystem/SQA-QC-Framework)
  added as a git submodule, with its skills, git hooks (and optionally the plan
  gate) and templates installed.

It is a Bash script. It asks for the repository name, description, visibility
and owner (a user or an organization, separately on each host), shows a plan,
and only creates anything after you pass `--apply` and answer yes.

> **Status.** The script is tested with stubbed host APIs and real git against
> local repositories (see [Development](#development)). A first end-to-end run
> on real GitHub and Gitea repositories, with organization owners on both, has
> passed (2026-10-05, review record RC-017). Creating a repository under your
> own Gitea account needs the `write:user` token scope (see
> [Token permissions](#token-permissions)); that path has not been completed
> yet.

## Contents

1. [Installation](#installation)
2. [Configuration](#configuration)
3. [Usage](#usage)
4. [SSH access to Gitea](#ssh-access-to-gitea)
5. [Token permissions](#token-permissions)
6. [Security decisions](#security-decisions)
7. [Error handling and recovery](#error-handling-and-recovery)
8. [Known limitations](#known-limitations)
9. [Code layout](#code-layout)
10. [Development](#development)
11. [Stakeholders](#stakeholders)
12. [License](#license)

## Installation

Requirements:

| Tool | Needed for |
| --- | --- |
| bash 4.4 or later | the script (macOS ships 3.2: install a newer bash first) |
| `git` | the local project and the framework submodule |
| `curl` | the GitHub and Gitea APIs |
| `mktemp` and the usual base tools | temporary files and small helpers |
| `ssh` (optional) | the SSH check; without it the framework steps are skipped |
| `jq` (optional) | JSON parsing; without it a small built-in reader is used |

```bash
git clone https://git.tirsystem.com/TirSystem-BashScript/RepoFoundry.git
cd RepoFoundry
src/create-project.sh --help
```

Nothing has to be installed system-wide: the script runs from the checkout and
loads its own files from `src/lib/`.

## Configuration

The script reads two plain files from the project root. They are **parsed,
never executed** (`source` is not used): only `KEY=VALUE` lines with known keys
are accepted, and anything else stops the run with a message that names the key
and the line, never the value.

```bash
cp config.env.example config.env     # service addresses, not secret: set GITEA_URL (and GITEA_API_URL)
cp .env.example .env                 # credentials: keep private
chmod 600 .env                       # Linux and macOS
```

### `config.env` (service addresses)

| Key | Meaning | Default |
| --- | --- | --- |
| `GITHUB_API_URL` | GitHub REST API base URL | `https://api.github.com` |
| `GITHUB_WEB_URL` | GitHub web base URL (links and the mirror address) | `https://github.com` |
| `GITEA_URL` | Gitea base URL (required) | |
| `GITEA_API_URL` | Gitea REST API base URL | `GITEA_URL` + `/api/v1` |
| `GITEA_SSH_PORT` | SSH port of the Gitea server | `10022` |
| `MIRROR_INTERVAL` | how often Gitea pushes to GitHub, e.g. `10m0s` | `10m0s` |
| `FRAMEWORK_REPO` | `OWNER/NAME` of the framework on Gitea | `TirSystem/SQA-QC-Framework` |

Every URL must start with `https://` and must not contain a user name,
password, query string or fragment. A credential key in this file is rejected.

### `config.env` (project details, optional)

Any of the details the script asks for can be set in `config.env` instead.
A detail that is set is used and not asked; the summary marks it with
`(from config.env)`.

| Key | Detail | Accepted value |
| --- | --- | --- |
| `PROJECT_NAME` | repository name | letters, digits, `.`, `_`, `-`; at most 100; not ending in `.git` |
| `PROJECT_DESCRIPTION` | description | at most 350 characters; may be empty |
| `PROJECT_VISIBILITY` | visibility | `private` or `public` |
| `GITEA_OWNER` | Gitea user or organization | letters, digits, `.`, `_`, `-`; at most 39 |
| `USE_GITHUB` | also create a GitHub repository | `yes` or `no` |
| `GITHUB_OWNER` | GitHub user or organization | letters, digits, `-`; used only when GitHub is used |
| `PROJECT_DIRECTORY` | local directory | not empty, not starting with `-` |
| `ENABLE_PLAN_GATE` | enable the plan gate | `yes` or `no` |

- A key that is present counts as set, even when its value is empty. Only
  `PROJECT_DESCRIPTION` may be empty (no description); an empty value for any
  other key stops the run. Remove the line to be asked instead.
- An invalid value stops the run before any request to a host and names the
  key. The script never falls back to asking for it.
- `USE_GITHUB=no` skips the GitHub owner and every GitHub step; a
  `GITHUB_OWNER` set at the same time is ignored, with a warning.
- Only these eight details can be set. The confirmations stay questions that
  default to no: create now, reusing an existing repository, an existing
  directory, `core.hooksPath` and replacing a template file.
- These keys are accepted in `config.env` only, never in `.env`.
- A value is read as plain text: an unquoted ` #` starts a comment and cuts the
  value there. Put a description that contains ` #` in double quotes, for
  example `PROJECT_DESCRIPTION="Tool for #mirrors"`.

With all eight set, a run asks only the confirmations:

```bash
src/create-project.sh --apply        # asks only "Create these now (y/n) [n]"
```

### `.env` (credentials)

| Key | Meaning |
| --- | --- |
| `GITEA_TOKEN` | Gitea access token |
| `GITHUB_PAT` | GitHub personal access token (only when you choose GitHub) |
| `GITHUB_USER` | the GitHub account the token belongs to (only when you choose GitHub) |

`.env` is ignored by git. The script warns if it is readable by other users or
not ignored by git. See [Token permissions](#token-permissions) for what each
token needs.

`.env` is optional, and so is each key in it. A credential that is not
provided (the file is missing, the key is absent or its value is empty) is
asked for: the Gitea token at the start, the GitHub token and account name once
you choose GitHub. A token is read without echo and checked like one read from
`.env`; a refused value is asked again and never shown. If input ends before a
valid value is entered, the run stops before any request to a host.

### The project's own `.env`

When the project exists, the script asks whether to create a `.env` in it
(default no). On a yes the file holds only the credentials the project needs:
`GITEA_TOKEN`, and `GITHUB_PAT` and `GITHUB_USER` when you chose GitHub, as read
from your `.env` or typed.

- The file is created readable by you only (mode 600), never readable by
  others even for a moment, and is never written by anything else.
- Git ignores it: the script adds `.env` to `.git/info/exclude` of the new
  project. No tracked file changes and nothing is committed.
- An existing `.env` in the project is never replaced without a second yes, and
  a `.env` that git already tracks is never written.
- The summary names the keys, never the values.

This is the one place the script writes a token to disk. It is plain text: keep
the project directory private, do not copy the file around, and say no if you
do not need it. Tokens are written nowhere else.

## Usage

```bash
src/create-project.sh                # dry run: reads from the hosts, creates nothing
src/create-project.sh --apply        # creates everything after a final yes
src/create-project.sh --config /path/to/config.env --env /path/to/.env
```

The script asks for, in this order: repository name, description, visibility,
Gitea owner, whether to also create a GitHub repository (and its owner), the
local directory and whether to enable the plan gate (a detail set in
[`config.env`](#configenv-project-details-optional) is not asked). It then checks both hosts
with read-only requests and prints a plan:

```text
Plan:
  Gitea repository  : create (private) with the AGPL-3.0 license https://git.example.org/Team/my-app
  GitHub repository : create (private), empty https://github.com/acme/my-app
  Push mirror       : Gitea -> GitHub every 10m0s
  Local project     : create ./my-app (new directory), git on main, no commit
  Local origin      : will use SSH (the SSH test passed)
  Framework         : add ssh://git@git.example.org:10022/Team/SQA-QC-Framework.git as a submodule
  Skills and hooks  : install once; plan gate no
  Templates         : AGENTS.md and docs/artifact-registry.md (you are asked before a file is replaced)
```

Without `--apply` that is all that happens. With `--apply` the script asks
"Create these now" (default no) and then creates, in this order:

1. the GitHub repository (empty), if chosen;
2. the Gitea repository (with the AGPL-3.0 license if GitHub was chosen);
3. the push mirror Gitea -> GitHub, and a request for its first sync;
4. the local directory, `git init` on `main`, the `origin` remote (and `github`
   if chosen), and, if the Gitea repository holds the license commit, that
   history;
5. the framework as the submodule `framework`;
6. the framework's skills and git hooks, and the plan gate if chosen;
7. `AGENTS.md` and `docs/artifact-registry.md` from the framework's templates.

No commit is made in the new project. Work on a branch there: the framework's
hooks refuse commits on `main`.

### Choices

- **GitHub or not.** Choosing GitHub also applies the AGPL-3.0 license to the
  Gitea repository (so it is not empty) and sets up the mirror. Without GitHub
  the Gitea repository is empty and has no license, and `GITHUB_PAT` is not
  needed.
- **Owners.** The Gitea owner and the GitHub owner are chosen separately and
  may be a user or an organization. `GITHUB_USER` is only the suggested default
  for the GitHub owner prompt; it identifies who authenticates.
- **Plan gate.** If enabled, a commit that changes `src/` or `tests/` in the
  new project needs a `Task: MIL-NNN#N` trailer.

### Nothing is overwritten without a yes

The script asks first (default no) before it uses an existing directory, before
it replaces an existing `core.hooksPath`, and before it replaces an existing
`AGENTS.md` or `docs/artifact-registry.md`. It never deletes anything, never
replaces a remote that points somewhere else, and git itself refuses to
overwrite a file when the license history is checked out.

## SSH access to Gitea

The framework submodule is fetched over SSH on port **10022**
(`ssh://git@<gitea host>:10022/TirSystem/SQA-QC-Framework.git`). Before you run
the script:

1. Add your SSH public key to your Gitea account.
2. Connect once by hand so that the server's host key is known (the script
   refuses unknown host keys and never answers questions for you):

   ```bash
   ssh -p 10022 -T git@git.tirsystem.com
   ```

   A message that you have successfully authenticated, without shell access,
   means it works.

The script runs the same check in its dry run. If it fails, the plan says so
and, with `--apply`, you are asked whether to create the repositories and the
local project **without** the framework steps (they are then reported as
skipped). The default answer is no.

## Token permissions

Both tokens go in `.env` (never in `config.env`, never in a remote URL). The
script sends them only in a request header, through a private temporary file,
and never prints them.

### GitHub token (`GITHUB_PAT`, only when you choose GitHub)

The same token has two jobs: it creates the repository, and it is the
password Gitea uses to push the mirror. It therefore needs to create
repositories for the chosen owner and to push to the new one.

| Need | Token | Source |
| --- | --- | --- |
| Create a private repository | classic token with the `repo` scope | GitHub REST documentation, "Create a repository" |
| Create a public repository only | classic token with `public_repo` is enough | same |
| Push from the Gitea mirror | covered by `repo` | |
| Check that you belong to the organization owner | worked with a classic token that has `repo` and `admin:org` | `read:org` alone was **not tested**: the GitHub documentation names no scope for this call. If the script says you do not belong to an organization that you do belong to, add `read:org`. |

- **Organization owners:** you must be an active member who is allowed to
  create repositories in the organization. Organizations that require SSO or
  approval of tokens need the token authorised first.
- **Fine-grained tokens:** the GitHub documentation lists no fine-grained
  permission for creating a repository, and this has not been tested.
  Use a classic token until it has been.
- **`GITHUB_USER`:** if it differs from the account the token belongs to, the
  script warns and uses the account the token belongs to.

### Gitea token (`GITEA_TOKEN`)

| Need | Scope | Source |
| --- | --- | --- |
| Read the account the token belongs to | `read:user` | Gitea documentation |
| Create a repository **under your own account** | `write:user` | **Confirmed by a real server**: without it Gitea answers `required=[write:user]` |
| Create a repository in an organization, manage its push mirror | `write:organization` and `write:repository` | worked with a token that has both, plus `read:user`; the minimum was not narrowed down |
| Look up an organization and your permissions in it | covered by the scopes above | worked in the end-to-end run |

A missing scope shows up as an HTTP 403 with the server's own message. The
script stops before it creates anything when a preflight check is refused.

## Security decisions

- **Tokens never appear** in output, logs, remote URLs, `.git/config`,
  `.gitmodules`, command lines or leftover files, and are written to disk only
  in the new project's own `.env`, after a yes (see
  [The project's own `.env`](#the-projects-own-env)). They go to `curl` through a
  private configuration file that is removed right after the request, and to
  `git` (HTTPS fetch only) through a `GIT_ASKPASS` helper and the environment
  of that one command. Output is filtered, so even a server message that echoes
  a token is shown as `[redacted]`. Tests plant fake tokens and search all
  output and every file of the new project for them.
- **No `set -x`.** Tracing would print every secret, so the script switches it
  off and says so.
- **Config files are parsed, not sourced,** with a whitelist of keys; values
  are validated (URLs must be `https` without credentials, tokens must have a
  safe character set) and never executed.
- **Dry run by default.** Creating anything needs `--apply` and a final yes.
- **No destructive commands.** The script never deletes a repository or a
  file and never uses a recursive delete; temporary files are removed one by
  one.
- **Credential-free remotes.** `origin` is `ssh://git@host:port/owner/name.git`
  (or plain HTTPS when SSH is not used) and `github` is a plain HTTPS address.
- **Redirects are not followed,** so a token is only ever sent to the host in
  the URL it was meant for. Unknown SSH host keys are refused.
- **Framework scripts run on the new project only.** They are run with
  `PROJECT_ROOT` set explicitly, so a `PROJECT_ROOT` in your environment cannot
  point them elsewhere. They come from the framework repository you configured:
  review what you trust there.

## Error handling and recovery

Every message starts with `error:`, names what failed and what to do, and never
contains a secret. Exit codes: `0` success (or a dry run), `1` a failed check or
step, `2` a usage error.

| What happens | What the script does | What you do |
| --- | --- | --- |
| A tool, a config key or a token is missing or invalid | stops before any request | fix it and run again |
| A token is refused, an owner is unknown, a name is taken, the license is missing | stops in the preflight; nothing was created | fix the cause |
| The host cannot be reached | stops with the host name | try again |
| A repository already exists and is empty (Gitea: or holds only the license and the README Gitea adds) | offers to reuse it (default no) | answer, or choose another name |
| A repository already has content | stops | choose another name or remove it |
| A step fails after another succeeded | stops and prints what exists, what failed and how to continue | fix the cause and run the **same command again with `--apply`**: what was created is offered for reuse |
| The mirror is refused (disabled, interval too short) | keeps the repositories and reports it | change `MIRROR_INTERVAL` or ask the Gitea administrator, then run again |
| The framework submodule cannot be fetched | reports the address and how to test SSH | fix your SSH access, run again |
| `sync_on_commit` was ignored by Gitea | warns; the mirror syncs on its interval | enable it in the repository settings if needed |

A partial run is reported like this:

```text
The run stopped before it finished. This is what exists now:
  GitHub repository : created https://github.com/acme/my-app
  Gitea repository  : FAILED
  Push mirror       : not attempted
  ...
To continue: fix the problem named above and run the same command again with --apply.
```

Nothing is deleted automatically. To start over, delete the repositories in the
web interface and the project directory by hand.

## Known limitations

- **The mirror password is stored on the Gitea server.** Gitea needs the
  GitHub token to push, so it keeps it. How it is protected depends on the
  Gitea version and its administrators. Use a token that is only meant for
  this, and revoke it if the Gitea server is ever in doubt.
- **`sync_on_commit` may be ignored.** When a push mirror is created through
  the API, some Gitea versions ignore `sync_on_commit` (upstream issue
  go-gitea/gitea#22990). On Gitea 1.27.3 it was applied: a branch pushed to
  Gitea reached GitHub within seconds. The script reads the mirror back and
  warns if the setting was not applied; the mirror then syncs on its interval
  (`MIRROR_INTERVAL`, default 10 minutes). The first sync is requested right
  after the mirror is created.
- **The server decides the shortest interval** and whether push mirrors are
  allowed at all. A refused mirror stops the run with the server's message;
  the repositories created so far are kept.
- **The license commit.** Gitea adds the license file when the repository is
  created with `auto_init`, and on the real server it also adds a generated
  `README.md`. Both are mirrored to GitHub and become the first commit of the
  local project. A Gitea repository that holds only these files counts as
  content this script created and is offered for reuse; a repository with
  anything else counts as having content and is refused.
- **No rollback.** See [Error handling and recovery](#error-handling-and-recovery).
- **Mirror direction is Gitea to GitHub only.** Push to Gitea; GitHub is a
  copy.
- **The framework needs SSH.** Without SSH access to Gitea the framework steps
  can only be skipped.
- **Tested on Windows (Git Bash) only so far.** Running the tests on Linux and
  macOS is an open follow-up.

## Code layout

`src/create-project.sh` is the entry point: the header, strict mode, loading
and `main`. The work is split by responsibility into `src/lib/`, one job per
file. The files are loaded from that directory only, by a fixed path.

| File | Responsibility |
| --- | --- |
| `constants.sh` | constants and the shared state of a run |
| `output.sh` | messages for the user and redaction of secrets |
| `temp.sh` | private temporary files and their cleanup |
| `util.sh` | small string and list helpers |
| `validate.sh` | validators for names, URLs, tokens, ports, intervals |
| `config.sh` | reading and checking `config.env` and `.env` (never sourced) |
| `tools.sh` | checking the required tools |
| `json.sh` | the little JSON the script reads and writes |
| `http.sh` | the one place that runs `curl`; tokens stay off the command line |
| `api.sh` | GitHub and Gitea API calls and reporting a refused call |
| `prompts.sh` | interactive questions with validation (secrets are read without echo) |
| `credentials.sh` | asking for a credential that `.env` does not provide |
| `project.sh` | the project details: asking for them and showing them |
| `hosts.sh` | names, links and remote addresses of the repositories |
| `preflight.sh` | read-only checks of both hosts |
| `steps.sh` | the outcome of each step and the final report |
| `envfile.sh` | the new project's own `.env`: created private, ignored by git, never replaced without a yes |
| `plan.sh` | printing what the script is about to do |
| `repositories.sh` | creating the GitHub and Gitea repositories |
| `mirror.sh` | the Gitea to GitHub push mirror |
| `git.sh` | running git for the new project without prompts or tokens on a command line |
| `localproject.sh` | the local directory, git repository and remotes |
| `framework.sh` | the framework submodule, skills, hooks and templates |
| `apply.sh` | confirmations and the apply flow; the only code that changes anything |
| `cli.sh` | usage text and option parsing |

Each file names its responsibility and lists the functions it provides in its
first lines. `tests/test-structure.sh` keeps it that way: every file in
`src/lib/` is loaded, no function is defined twice, and a file does nothing
when it is loaded.

## Development

```bash
bash tests/run-tests.sh             # shellcheck, shfmt and all tests, no network
bash tests/run-tests.sh PATTERN     # only tests whose name contains PATTERN
```

The tests stub the two host APIs (a fake `curl` answers from a routes file) and
`ssh`, and run real git against local bare repositories that stand in for
Gitea and the framework (git's `insteadOf` rewrites the remote addresses), with
a private git configuration. Nothing reaches the network and nothing outside
the test directories is changed. Mutation checks show that the tests fail when
a guarantee is removed.

Planning documents, reviews and the traceability matrix are in `docs/`; the
project follows the SQA and QC framework (see `AGENTS.md`).

## Stakeholders

| Who | Role |
| --- | --- |
| [Tirsvad](https://www.linkedin.com/in/tirsvad74) | Product Owner and maintainer |
| [Michael Kragh](https://www.linkedin.com/in/codemikemike/) | DevOps, cybersecurity and maintainer |
| GitHub readers | people who read and may reuse this project |

## License

GNU Affero General Public License v3.0; see [LICENSE](LICENSE).
