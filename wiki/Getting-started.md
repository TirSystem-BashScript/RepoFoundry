# Getting started

## Requirements

| Tool | Needed for |
| --- | --- |
| bash 4.4 or later | the script (macOS ships 3.2: install a newer bash first) |
| `git` | the local project and the framework submodule |
| `curl` | the GitHub and Gitea APIs |
| `ssh` (optional) | the SSH check; without it the framework steps are skipped |
| `jq` (optional) | JSON parsing; without it a small built-in reader is used |

## Install

```bash
git clone https://git.tirsystem.com/TirSystem-BashScript/repo-foundry.git
cd repo-foundry
src/create-project.sh --help
```

Nothing is installed system-wide: the script runs from the checkout.

## Configure

Copy `config.env.example` to `config.env` and `.env.example` to `.env`, then set the service addresses and the tokens (see [SSH and tokens](SSH-and-tokens)). `.env` holds credentials and is never committed.

## Run

Start the script from the folder that should hold the new project:

```bash
src/create-project.sh            # dry run: reads from the hosts, creates nothing
src/create-project.sh --apply    # creates everything after a final yes
```

No commit is made in the new project. Work on a branch there: the framework's hooks refuse commits on `main`.
