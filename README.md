# RepoFoundry

RepoFoundry (`src/create-project.sh`) sets up a new project: a Gitea
repository, optionally an empty GitHub repository with a push mirror from
Gitea to GitHub, and (in a later phase) a local project with the
SQA-QC-Framework.

> **Status: work in progress.** The script can validate its configuration,
> check both hosts and create the repositories and the mirror. Creating the
> local project, and the full installation guide, come in a later phase
> (MIL-003). This file so far documents what is needed to run the host steps
> safely.

## Quick start

```bash
cp config.env.example config.env     # service addresses, not secret
cp .env.example .env                 # credentials: keep private
chmod 600 .env                       # Linux and macOS

src/create-project.sh                # dry run: reads from the hosts, creates nothing
src/create-project.sh --apply        # creates the repositories and the mirror
```

Without `--apply` the script only reads from GitHub and Gitea (it checks the
tokens, the owners, the name, the license and SSH) and prints a plan. With
`--apply` it prints the plan again and asks a final question before it creates
anything. Nothing is ever deleted by the script.

Choosing GitHub also applies the AGPL-3.0 license to the Gitea repository, so
that repository is not empty. Without GitHub the Gitea repository is created
empty and has no license.

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
| Check that you belong to the organization owner | probably `read:org` | **Not confirmed**: the GitHub documentation names no scope for this call. If the script says you do not belong to an organization that you do belong to, add `read:org`. |

- **Organization owners:** you must be an active member who is allowed to
  create repositories in the organization. Organizations that require SSO or
  approval of tokens need the token authorised first.
- **Fine-grained tokens:** the GitHub documentation lists no fine-grained
  permission for creating a repository, and this has not been tested.
  Use a classic token until it has been.
- **`GITHUB_USER`:** names the account the token belongs to. It is only a
  default for the owner prompt; the repository may belong to an organization.
  If it differs from the account the token belongs to, the script warns and
  uses the account the token belongs to.

### Gitea token (`GITEA_TOKEN`)

| Need | Scope | Source |
| --- | --- | --- |
| Read the account the token belongs to | `read:user` | Gitea documentation |
| Create repositories, manage the push mirror | `write:repository` | Gitea documentation |
| Look up an organization and your permissions in it | `read:organization` | Gitea documentation |
| Create a repository in an organization | probably `write:organization` as well | **Not confirmed**: expected from how the Gitea API groups organization calls; the end-to-end test in MIL-003 will confirm it. |

A missing scope shows up as an HTTP 403 with the server's own message. The
script stops before it creates anything when a preflight check is refused.

## Known limitations

- **The mirror password is stored on the Gitea server.** Gitea needs the
  GitHub token to push, so it keeps it. How it is protected depends on the
  Gitea version and its administrators. Use a token that is only meant for
  this, and revoke it if the Gitea server is ever in doubt.
- **`sync_on_commit` may be ignored.** When a push mirror is created through
  the API, some Gitea versions ignore `sync_on_commit` (upstream issue
  go-gitea/gitea#22990). The script reads the mirror back and warns if the
  setting was not applied; the mirror then syncs on its interval
  (`MIRROR_INTERVAL`, default 10 minutes). The first sync is requested right
  after the mirror is created.
- **The server decides the shortest interval** and whether push mirrors are
  allowed at all. A refused mirror stops the run with the server's message;
  the repositories created so far are kept.
- **The license commit.** Gitea adds the license file when the repository is
  created with `auto_init`. The script sends no README, so the repository
  should hold only `LICENSE`; this is checked in the MIL-003 end-to-end test.
- **No rollback.** If a step fails, the script reports what exists and how to
  continue. A repeated run offers to reuse a repository it created earlier
  (empty, or in Gitea's case holding only the license). Delete what you do not
  want in the web interface.
- **Mirror direction is Gitea to GitHub only.** Push to Gitea; GitHub is a
  copy.
- **Requirements:** bash 4.4 or later, `git`, `curl` and `mktemp`; `jq` and
  `ssh` are optional. Without `jq` the script reads the few JSON fields it
  needs with a simple built-in reader.

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
| `prompts.sh` | interactive questions with validation |
| `project.sh` | the project details: asking for them and showing them |
| `hosts.sh` | names and links of the repositories on each host |
| `preflight.sh` | read-only checks of both hosts |
| `steps.sh` | the outcome of each step and the final report |
| `plan.sh` | printing what the script is about to do |
| `repositories.sh` | creating the GitHub and Gitea repositories |
| `mirror.sh` | the Gitea to GitHub push mirror |
| `apply.sh` | confirmations and the apply flow; the only code that changes anything |
| `cli.sh` | usage text and option parsing |

Each file names its responsibility and lists the functions it provides in its
first lines. `tests/test-structure.sh` keeps it that way: every file in
`src/lib/` is loaded, no function is defined twice, and a file does nothing
when it is loaded.

## Development

```bash
bash tests/run-tests.sh           # shellcheck, shfmt and all tests, no network
```
