<!-- translation of GettingStarted.md, source sha256 b030cafee29e -->

> Dette er en oversættelse af [`GettingStarted`](GettingStarted). Den engelske side er autoritativ, og ændringer her bliver overskrevet, næste gang wikien publiceres.

[English](GettingStarted) | Dansk | [Bahasa Melayu](GettingStarted.ms)

# Kom godt i gang

## Krav

| Værktøj | Bruges til |
| --- | --- |
| bash 4.4 eller nyere | scriptet (macOS leveres med 3.2: installér først en nyere bash) |
| `git` | det lokale projekt og framework-submodulet |
| `curl` | GitHub- og Gitea-API'erne |
| `ssh` (valgfri) | SSH-kontrollen; uden den springes framework-trinnene over |
| `jq` (valgfri) | JSON-læsning; uden den bruges en lille indbygget læser |

## Installation

```bash
git clone https://git.tirsystem.com/TirSystem-BashScript/repo-foundry.git
cd repo-foundry
src/create-project.sh --help
```

Intet installeres på hele systemet: scriptet kører fra checkout'et.

## Konfiguration

Kopiér `config.env.example` til `config.env` og `.env.example` til `.env`, og angiv derefter tjenesternes adresser og tokens (se [SSH og tokens](SshAndTokens.da)). `.env` indeholder credentials og committes aldrig.

## Kørsel

Start scriptet fra den mappe, der skal indeholde det nye projekt:

```bash
src/create-project.sh            # tør kørsel: læser fra værterne, opretter intet
src/create-project.sh --apply    # opretter alt efter et sidste ja
```

Der laves ingen commit i det nye projekt. Arbejd på en branch der: frameworkets hooks afviser commits på `main`.
