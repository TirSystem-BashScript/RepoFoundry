<!-- translation of Home.md, source sha256 3ab3ef0f5a55 -->

> Dette er en oversættelse af [`Home`](Home). Den engelske side er autoritativ, og ændringer her bliver overskrevet, næste gang wikien publiceres.

[English](Home) | Dansk | [Bahasa Melayu](Home.ms)

# Repo Foundry

Repo Foundry (`src/create-project.sh`) opretter et nyt projekt i én kørsel:

- et **Gitea**-repository, som er den autoritative kilde;
- eventuelt et tomt **GitHub**-repository, der får alt via et push-spejl fra Gitea;
- et **lokalt projekt** med én remote uden credentials, `origin`, og SQA-QC-Framework som git-submodul, med dets skills, git-hooks og skabeloner installeret.

Det er et Bash-script. Det viser først en plan og opretter intet, før du angiver `--apply` og svarer ja.

## Sider

| Side | Hvad den dækker |
| --- | --- |
| [Kom godt i gang](GettingStarted.da) | Krav, installation og første kørsel |
| [SSH og tokens](SshAndTokens.da) | SSH-adgang til Gitea og de to adgangstokens |
| [Opdatering af frameworket](UpdatingTheFramework.da) | Hold et projekts framework-submodul opdateret |
| [Fejlfinding](Troubleshooting.da) | Almindelige fejl og hvad du skal gøre |

Den fulde reference (konfigurationsfiler, sikkerhedsbeslutninger, fejlhåndtering, kendte begrænsninger) er [README](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/src/branch/main/README.md).
Meld et problem som en [issue](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/issues).
