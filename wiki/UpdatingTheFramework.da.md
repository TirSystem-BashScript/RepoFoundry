<!-- translation of UpdatingTheFramework.md, source sha256 3e450f6c8f34 -->

> Dette er en oversættelse af [`UpdatingTheFramework`](UpdatingTheFramework). Den engelske side er autoritativ, og ændringer her bliver overskrevet, næste gang wikien publiceres.

[English](UpdatingTheFramework) | Dansk | [Bahasa Melayu](UpdatingTheFramework.ms)

# Opdatering af frameworket

Et projekt oprettet af Repo Foundry har SQA-QC-Framework som git-submodulet `framework`. En clone eller en `git pull` flytter det ikke: projektet bliver på den framework-commit, det har registreret. For at holde frameworket opdateret kører du dette i projektet, fra dets rod:

```bash
git submodule update --init --remote --recursive framework
```

| Del | Hvorfor |
| --- | --- |
| `--init` | henter submodulet, hvis det ikke findes endnu |
| `--remote` | flytter `framework` til den nyeste commit i framework-repositoryet i stedet for den commit, projektet har registreret |
| `--recursive` | opdaterer også det submodul, frameworket selv har (`framework/qc`, checklisterne) |

## Efter opdateringen

1. Installér skills igen, så kopierne i `.claude/skills/` og `.agents/skills/` svarer til det nye framework:

   ```bash
   bash framework/scripts/install-skills.sh
   ```

2. Gennemgå, hvad der er ændret, og commit derefter den nye framework-commit på en branch (frameworkets hooks afviser commits på `main`):

   ```bash
   git status
   git switch -c update-framework
   git add framework
   git commit -m "Update the framework"
   ```

3. Opdatér `AGENTS.md` (næste afsnit).

## Opdatér AGENTS.md til den nyeste skabelon

`AGENTS.md` i dit projekt blev kopieret fra `framework/templates/AGENTS-template.md`, da projektet blev oprettet. Det er en kopi, så den ændres ikke, når frameworket ændres. Skabelonen indeholder de regler, frameworkets skills og hooks forventer (for eksempel superviseret og autonom tilstand), så opdatér den efter hver framework-opdatering.

1. Se, hvad der er forskelligt:

   ```bash
   diff -u AGENTS.md framework/templates/AGENTS-template.md
   ```

2. Hvis du aldrig har redigeret `AGENTS.md`, erstat den:

   ```bash
   cp framework/templates/AGENTS-template.md AGENTS.md
   ```

3. Hvis du har tilføjet egne regler, kopiér de nye eller ændrede skabelonafsnit ind i `AGENTS.md` i hånden og behold dine egne. Hvis du erstatter filen, mister du dem.

Repo Foundry lægger `/AGENTS.md` i `.git/info/exclude` i det nye projekt, så git ikke viser filen, og ændringen er ikke en commit: den påvirker kun din arbejdskopi. Erstat ikke `docs/artifact-registry.md` på samme måde: den indeholder dit projekts egne rækker, så sammenlign den kun med `framework/templates/artifact-registry-template.md` og kopiér det, du har brug for.

## Noter

- `--remote` følger framework-repositoryets standardbranch, ikke et release-tag. For at blive på et release skal du i stedet checke tagget ud i submodulet: `git -C framework checkout <tag>`, og derefter committe `framework` som ovenfor.
- En anden person, der clone'r projektet eller henter din commit, får den registrerede framework-commit med `git submodule update --init --recursive`.
- Submodulet hentes over SSH på port 10022, så [SSH-opsætningen](SshAndTokens.da) gælder også for opdateringer.
