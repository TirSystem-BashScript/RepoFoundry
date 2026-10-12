English | [Dansk](SshAndTokens.da) | [Bahasa Melayu](SshAndTokens.ms)

# SSH and tokens

## SSH access to Gitea

The framework submodule is fetched over SSH on port **10022**. Before you run the script:

1. Add your SSH public key to your Gitea account.
2. Connect once by hand so the server's host key is known (the script refuses unknown host keys):

   ```bash
   ssh -p 10022 -T git@git.tirsystem.com
   ```

   A message that you have successfully authenticated, without shell access, means it works.

> **Passphrase keys.** The script never prompts for a passphrase. A key with a passphrase must already be loaded in `ssh-agent` (`ssh-add`). This is tracked in [issue 77](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/issues/77).

## Tokens

| Token | Key in `.env` | Needed | Type |
| --- | --- | --- | --- |
| Gitea access token | `GITEA_TOKEN` | always | access token with scopes |
| GitHub personal access token | `GITHUB_PAT` | only when you choose GitHub | **classic** personal access token |

Step by step with pictures: [how to create the access tokens](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/src/branch/main/howto/create-access-tokens.md). The exact permissions are under [Token permissions](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/src/branch/main/README.md#token-permissions) in the README.
