<!-- translation of SshAndTokens.md, source sha256 ec9001c0248b -->

> Dette er en oversættelse af [`SshAndTokens`](SshAndTokens). Den engelske side er autoritativ, og ændringer her bliver overskrevet, næste gang wikien publiceres.

[English](SshAndTokens) | Dansk | [Bahasa Melayu](SshAndTokens.ms)

# SSH og tokens

## SSH-adgang til Gitea

Framework-submodulet hentes over SSH på port **10022**. Før du kører scriptet:

1. Tilføj din offentlige SSH-nøgle til din Gitea-konto.
2. Opret forbindelse én gang manuelt, så serverens hostnøgle er kendt (scriptet afviser ukendte hostnøgler):

   ```bash
   ssh -p 10022 -T git@git.tirsystem.com
   ```

   En besked om, at du er godkendt, uden shell-adgang, betyder, at det virker.

> **Nøgler med adgangskode.** Scriptet beder aldrig om en adgangskode. En nøgle med adgangskode skal allerede være indlæst i `ssh-agent` (`ssh-add`). Det følges i [issue 77](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/issues/77).

## Tokens

| Token | Nøgle i `.env` | Nødvendig | Type |
| --- | --- | --- | --- |
| Gitea-adgangstoken | `GITEA_TOKEN` | altid | adgangstoken med scopes |
| GitHub personal access token | `GITHUB_PAT` | påkrævet, når du vælger GitHub (spejlet) | **klassisk** personal access token |
| Gitea-adgangstoken til wikien | `TOKEN_FOR_GITEA_WIKI` | valgfri (kun for at udgive wikien) | adgangstoken kun med repository-skriveadgang (`write:repository`); scriptet accepterer den, men bruger den aldrig |

Trin for trin med billeder: [sådan opretter du adgangstokens](AccessTokens.da). De præcise tilladelser står under [Token permissions](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/src/branch/main/README.md#token-permissions) i README.
