# Troubleshooting

| Symptom | What to check |
| --- | --- |
| The plan says the SSH test failed | Your key is in your Gitea account, the host key is known (`ssh -p 10022 -T git@git.tirsystem.com`), and a passphrase key is loaded with `ssh-add` |
| The script stops at the tool check | bash is 4.4 or later, and `git` and `curl` are installed |
| A host rejects the token | The token is current and has the scopes in [SSH and tokens](SSH-and-tokens) |
| A run stopped half way | Fix the cause and run the same command again with `--apply`: what was already created is offered for reuse |

More: [Error handling and recovery](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/src/branch/main/README.md#error-handling-and-recovery) and [Known limitations](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/src/branch/main/README.md#known-limitations) in the README.
