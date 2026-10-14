<!-- translation of Home.md, source sha256 054f37c6e99b -->

> Dette er en oversættelse af [`Home`](Home). Den engelske side er autoritativ, og ændringer her bliver overskrevet, næste gang wikien publiceres.

[English](Home) | Dansk | [Bahasa Melayu](Home.ms)

# Repo Foundry

Repo Foundry (`src/create-project.sh`) opretter et nyt projekt i én kørsel:

- et **Gitea**-repository, som er den autoritative kilde;
- eventuelt et tomt **GitHub**-repository, der får alt via et push-spejl fra Gitea;
- et **lokalt projekt** med én remote uden credentials, `origin`, og SQA-QC-Framework som git-submodul, med dets skills, git-hooks og skabeloner installeret.

> **Adgang til frameworket.** SQA-QC-Framework er ophavsretligt beskyttet, og du har ikke adgang til det som standard. Kontakt [Jens Tirsvad](https://www.linkedin.com/in/tirsvad74/) for at få adgang. En hjemmeside med vores kontaktoplysninger kommer på <https://www.tirsystem.com>.

Det er et Bash-script. Det viser først en plan og opretter intet, før du angiver `--apply` og svarer ja.

## Sider

| Side | Hvad den dækker |
| --- | --- |
| [Kom godt i gang](GettingStarted.da) | Krav, installation og første kørsel |
| [SSH og tokens](SshAndTokens.da) | SSH-adgang til Gitea og de to adgangstokens |
| [Adgangstokens](AccessTokens.da) | Opret adgangstokens trin for trin med billeder |
| [Opdatering af frameworket](UpdatingTheFramework.da) | Hold et projekts framework-submodul opdateret |
| [Fejlfinding](Troubleshooting.da) | Almindelige fejl og hvad du skal gøre |

Den fulde reference (konfigurationsfiler, sikkerhedsbeslutninger, fejlhåndtering, kendte begrænsninger) er [README](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/src/branch/main/README.md).
Meld et problem som en [issue](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/issues).
