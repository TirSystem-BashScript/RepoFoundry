# Repo Foundry

Repo Foundry (`src/create-project.sh`) sets up a new project in one run:

- a **Gitea** repository, the source of truth;
- optionally an empty **GitHub** repository that receives everything through a push mirror from Gitea;
- a **local project** with one credential-free remote, `origin`, and the SQA-QC-Framework as a git submodule, with its skills, git hooks and templates installed.

It is a Bash script. It shows a plan first and creates nothing until you pass `--apply` and answer yes.

## Pages

| Page | What it covers |
| --- | --- |
| [Getting started](GettingStarted) | Requirements, install and the first run |
| [SSH and tokens](SshAndTokens) | SSH access to Gitea and the two access tokens |
| [Troubleshooting](Troubleshooting) | Common failures and what to do |

The full reference (configuration files, security decisions, error handling, known limitations) is the [README](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/src/branch/main/README.md).
Report a problem as an [issue](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/issues).
