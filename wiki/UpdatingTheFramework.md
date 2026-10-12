English | [Dansk](UpdatingTheFramework.da) | [Bahasa Melayu](UpdatingTheFramework.ms)

# Updating the framework

A project created by Repo Foundry holds the SQA-QC-Framework as the git submodule `framework`. A clone or a `git pull` does not move it: the project stays on the framework commit it recorded. To keep the framework up to date, run this in the project, from its root:

```bash
git submodule update --init --remote --recursive framework
```

| Part | Why |
| --- | --- |
| `--init` | fetches the submodule if it is not there yet |
| `--remote` | moves `framework` to the latest commit of the framework repository, instead of the commit the project recorded |
| `--recursive` | also updates the submodule the framework holds itself (`framework/qc`, the checklists) |

## After the update

1. Re-install the skills, so the copies in `.claude/skills/` and `.agents/skills/` match the new framework:

   ```bash
   bash framework/scripts/install-skills.sh
   ```

2. Review what changed, then commit the new framework commit on a branch (the framework's hooks refuse commits on `main`):

   ```bash
   git status
   git switch -c update-framework
   git add framework
   git commit -m "Update the framework"
   ```

3. Bring `AGENTS.md` up to date (next section).

## Update AGENTS.md to the newest template

`AGENTS.md` in your project was copied from `framework/templates/AGENTS-template.md` when the project was created. It is a copy, so it does not change when the framework does. The template holds the rules the framework's skills and hooks expect (for example the supervised and autonomous modes), so bring it up to date after each framework update.

1. See what differs:

   ```bash
   diff -u AGENTS.md framework/templates/AGENTS-template.md
   ```

2. If you never edited `AGENTS.md`, replace it:

   ```bash
   cp framework/templates/AGENTS-template.md AGENTS.md
   ```

3. If you added your own rules, copy the new or changed template sections into `AGENTS.md` by hand and keep yours. Replacing the file would lose them.

Repo Foundry adds `/AGENTS.md` to `.git/info/exclude` in the new project, so git does not list the file and the change is not a commit: it only affects your working copy. Do not replace `docs/artifact-registry.md` the same way: it holds your project's own rows, so only compare it with `framework/templates/artifact-registry-template.md` and copy what you need.

## Notes

- `--remote` follows the default branch of the framework repository, not a release tag. To stay on a release, check the tag out inside the submodule instead: `git -C framework checkout <tag>`, then commit `framework` as above.
- Another person who clones the project, or pulls your commit, gets the recorded framework commit with `git submodule update --init --recursive`.
- The submodule is fetched over SSH on port 10022, so the [SSH setup](SshAndTokens) applies to updates too.
