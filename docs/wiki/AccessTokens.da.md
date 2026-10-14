<!-- translation of AccessTokens.md, source sha256 5b50dc96a057 -->

> Dette er en oversættelse af [`AccessTokens`](AccessTokens). Den engelske side er autoritativ, og ændringer her bliver overskrevet, næste gang wikien publiceres.

[English](AccessTokens) | Dansk | [Bahasa Melayu](AccessTokens.ms)

# Sådan opretter du de adgangstokens, RepoFoundry har brug for

RepoFoundry taler med to værter og har brug for ét token til hver:

| Token | Nøgle | Nødvendig | Type |
| --- | --- | --- | --- |
| Gitea-adgangstoken | `GITEA_TOKEN` | altid | et adgangstoken med scopes |
| GitHub personal access token | `GITHUB_PAT` | påkrævet, når du vælger GitHub (spejlet) | et **klassisk** personal access token (PAT) |
| Gitea-adgangstoken til wikien | `TOKEN_FOR_GITEA_WIKI` | valgfri (kun for at udgive wikien) | et adgangstoken kun med repository-skriveadgang (`write:repository`) |

`TOKEN_FOR_GITEA_WIKI` bruges ikke af RepoFoundry. Det er nævnt her, fordi den samme `.env` kan indeholde det, og RepoFoundry accepterer det dér. Opret det på samme måde som Gitea-tokenet i del 1, og sæt kun flueben ved repository-skriveadgang.

Denne vejledning viser de to første trin for trin. De røde tal i hvert billede svarer til de nummererede trin ved siden af.

> **Om billederne.** De er tegninger af siderne, ikke skærmbilleder, så de ikke viser kontodata. Navne, farver og placeringen af en knap kan afvige lidt i din version af Gitea eller GitHub. Ordene med fed skrift i trinene er de etiketter, du skal lede efter. Et nyt token vises som prikker i billederne; på din skærm ser du den rigtige værdi.

Den fulde liste over, hvad hvert token må, står under [Token permissions](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/src/branch/main/README.md#token-permissions) i README. Denne vejledning er klik-for-klik-udgaven af den.

Indhold:

1. [Opret et Gitea-adgangstoken](#1-opret-et-gitea-adgangstoken)
2. [Opret et GitHub personal access token (klassisk)](#2-opret-et-github-personal-access-token-klassisk)
3. [Giv tokens til RepoFoundry](#3-giv-tokens-til-repofoundry)
4. [Opbevar tokens sikkert](#4-opbevar-tokens-sikkert)
5. [Hvis noget går galt](#5-hvis-noget-går-galt)

---

## 1. Opret et Gitea-adgangstoken

Eksemplerne bruger `https://git.tirsystem.com`. Hvis din Gitea kører et andet sted, så brug den adresse, du har sat som `GITEA_URL` i `config.env`.

### Trin 1. Åbn dine indstillinger

Log ind på Gitea. Klik på din **avatar** øverst til højre (1), og vælg **Settings** (2).

![Trin 1: avatarmenuen øverst til højre med Settings fremhævet](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/raw/branch/main/docs/wiki/img/gitea-1-open-settings.png)

### Trin 2. Åbn "Applications"

Klik på **Applications** (1) i menuen til venstre.

Du kan også gå direkte dertil: `<din Gitea-adresse>/user/settings/applications`.

![Trin 2: Applications i venstre menu i indstillingerne](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/raw/branch/main/docs/wiki/img/gitea-2-applications.png)

### Trin 3. Udfyld token-formularen

Rul til **Generate New Token** og udfyld den:

1. **Token Name:** et navn, du kan genkende senere, for eksempel `RepoFoundry`.
2. **Repository and Organization Access:** vælg **All (public, private, and limited)**. Et token, der er begrænset til **Public only**, kan ikke se private repositories eller organisationer, så oprettelse af et privat projekt ville fejle.
3. **Select permissions:** sæt disse tre til **Read and Write**, og lad alle andre linjer stå på **No Access**:

   | Permission | Niveau | Hvorfor RepoFoundry har brug for den |
   | --- | --- | --- |
   | `organization` | Read and Write | slå ejeren og dine rettigheder op, oprette repositories i en organisation |
   | `repository` | Read and Write | oprette repositoriet og styre dets push-spejl |
   | `user` | Read and Write | læse hvilken konto tokenet tilhører, og oprette et repository under din **egen** konto |

4. Klik på **Generate Token**.

![Trin 3: token-formularen med navn, adgangsvalg og tre permissions sat til Read and Write](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/raw/branch/main/docs/wiki/img/gitea-3-token-form.png)

> **Opretter du kun projekter i organisationer?** Så kan `user` blive på **Read**. `Read and Write` på `user` er kun nødvendigt for at oprette et repository under din egen konto; uden det svarer Gitea `required=[write:user]`.

### Trin 4. Kopiér tokenet nu

Gitea viser det nye token **én gang**, i en grøn besked øverst på siden (1). Kopiér det (brug kopiknappen, hvis din version har en, eller markér teksten og tryk Ctrl+C, Cmd+C på en Mac), og gem det til [del 3 i denne vejledning](#3-giv-tokens-til-repofoundry). Det nye token står nu på listen under (2) med sine permissions, men listen viser aldrig værdien igen.

Hvis du mister værdien, så slet tokenet og opret et nyt.

![Trin 4: den grønne besked med det nye token og en Copy-knap, og tokenet på listen nedenunder](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/raw/branch/main/docs/wiki/img/gitea-4-copy-token.png)

---

## 2. Opret et GitHub personal access token (klassisk)

Spring denne del over, hvis du ikke vil oprette et GitHub-repository (`USE_GITHUB=no`, eller du svarer nej, når du bliver spurgt). `GITHUB_PAT` er så ikke nødvendig.

Brug et **klassisk** token. RepoFoundry er ikke testet med fine-grained tokens, fordi GitHub ikke dokumenterer nogen fine-grained permission til at oprette et repository.

### Trin 1. Åbn dine indstillinger

Log ind på GitHub. Klik på dit **profilbillede** øverst til højre (1), og vælg **Settings** (2).

![Trin 1: profilmenuen øverst til højre med Settings fremhævet](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/raw/branch/main/docs/wiki/img/github-1-open-settings.svg)

### Trin 2. Åbn "Developer settings"

Rul ned i bunden af sidebjælken til venstre, og klik på **Developer settings** (1). Det er det sidste punkt.

![Trin 2: Developer settings nederst i sidebjælken til venstre](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/raw/branch/main/docs/wiki/img/github-2-developer-settings.svg)

### Trin 3. Vælg "Tokens (classic)"

1. Åbn **Personal access tokens** i sidebjælken til venstre, og klik på **Tokens (classic)** (1).
2. Klik på **Generate new token** (2).
3. I menuen, der åbner, vælg **Generate new token (classic)** (3). Ikke det første punkt, som er den fine-grained slags.

GitHub kan bede dig bekræfte din adgangskode eller en tofaktorkode. Gør det selv; ingen andre bør skrive den.

![Trin 3: Tokens (classic) i sidebjælken og Generate new token (classic) i knapmenuen](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/raw/branch/main/docs/wiki/img/github-3-tokens-classic.svg)

> Direkte adresse: `https://github.com/settings/tokens/new`

### Trin 4. Udfyld formularen

1. **Note:** et navn, du kan genkende senere, for eksempel `RepoFoundry`.
2. **Expiration:** vælg en dato. En kortere levetid begrænser skaden, hvis tokenet lækker; du opretter så et nyt token, når det udløber.
3. **Select scopes:** sæt flueben ved scopes nedenfor og intet andet.

   | Scope | Sæt flueben, når | Hvorfor |
   | --- | --- | --- |
   | `repo` | altid (private eller offentlige projekter) | opretter repositoriet og er den adgangskode, Gitea bruger til at pushe spejlet |
   | `public_repo` i stedet for `repo` | **kun** offentlige projekter | nok til at oprette og pushe et offentligt repository; `repo` omfatter det allerede |
   | `read:org` | kun hvis scriptet siger, at du ikke tilhører din organisation | lader scriptet kontrollere dit medlemskab af en organisation som ejer |

   Når du sætter flueben ved `repo`, får de fem underscopes (`repo:status`, `repo_deployment`, `public_repo`, `repo:invite`, `security_events`) også flueben; det er forventet. Lad `workflow`, `write:packages` og resten stå uden flueben.

4. Rul ned, og klik på **Generate token** (4).

![Trin 4: formularen til et nyt token med note, udløb, scopet repo afkrydset og knappen Generate token](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/raw/branch/main/docs/wiki/img/github-4-token-form.svg)

> **`read:org` og `admin:org`.** README fastslår, at kontrollen virkede med et token, der havde `repo` og `admin:org`, og at `read:org` alene er utestet. Prøv `read:org` først. `admin:org` giver langt mere magt, end RepoFoundry har brug for, så brug det kun, hvis `read:org` ikke er nok.

### Trin 5. Kopiér tokenet nu

GitHub viser tokenet **én gang**, i en grøn boks øverst (1). Klik på kopiikonet ved siden af. Det begynder med `ghp_`. Gem det til [del 3 i denne vejledning](#3-giv-tokens-til-repofoundry).

Hvis ejeren af det nye repository er en organisation, der bruger SAML single sign-on, skal tokenet også godkendes til den organisation: klik på listen over tokens på **Configure SSO** (2) ved tokenet og derefter **Authorize** for organisationen.

![Trin 5: den grønne boks med det nye token og et kopiikon, og Configure SSO på listen over tokens](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/raw/branch/main/docs/wiki/img/github-5-copy-token.svg)

---

## 3. Giv tokens til RepoFoundry

Vælg én måde. Begge holder tokenet ude af `config.env` (et token dér bliver afvist).

**Mulighed A: skriv det, når du bliver spurgt (intet gemmes).** Gør ingenting på forhånd. RepoFoundry spørger efter `Gitea access token` fra start og efter `GitHub personal access token` og `GitHub account name`, når du vælger GitHub. Det, du skriver, vises ikke på skærmen. Indsæt kun tokenet, uden mellemrum, linjeskift eller anførselstegn.

**Mulighed B: gem dem i `.env` (bekvemt, almindelig tekst på disken).** I RepoFoundry-mappen:

```bash
cp .env.example .env
chmod 600 .env          # Linux og macOS: kun du kan læse den
```

Åbn `.env` og udfyld værdierne; erstat teksten i vinkelparenteser, og fjern parenteserne:

```text
GITEA_TOKEN=<Gitea-tokenet>
GITHUB_PAT=<GitHub-tokenet>
GITHUB_USER=<dit GitHub-kontonavn>
TOKEN_FOR_GITEA_WIKI=<Gitea-tokenet til wikien, kun repository-skriveadgang>
```

`GITHUB_PAT` og `GITHUB_USER` er kun påkrævede, når du vælger GitHub (spejlet); udelad dem ellers. `TOKEN_FOR_GITEA_WIKI` er valgfri og kun nødvendig for at udgive wikien. Git ignorerer `.env`. Du må aldrig committe den, sende den eller indsætte den i en chat eller en issue.

Kontrollér derefter opsætningen med en prøvekørsel, som kun læser fra værterne og ikke opretter noget:

```bash
src/create-project.sh
```

---

## 4. Opbevar tokens sikkert

- Et token er en adgangskode. Enhver, der har det, kan gøre det, det tillader.
- Giv hvert token kun den adgang, der står i denne vejledning, og en udløbsdato.
- Indsæt aldrig et token i en kommandolinje, en URL, en commit, en issue eller en chat.
- Hvis et token kan være lækket, så slet det med det samme og opret et nyt:
  - Gitea: **Settings**, **Applications**, derefter **Delete** ved det token.
  - GitHub: **Settings**, **Developer settings**, **Personal access tokens**, **Tokens (classic)**, derefter **Delete** ved det token.
- Når et token udløber, så opret et nyt på samme måde og erstat det i `.env`.

---

## 5. Hvis noget går galt

| Det, du ser | Sandsynlig årsag | Hvad du skal gøre |
| --- | --- | --- |
| `authentication failed: the token is missing, expired or invalid` | tokenet er skrevet forkert, er udløbet eller er slettet | opret et nyt token og brug det |
| `the token is valid but not allowed to do this (check its scopes)` | en permission mangler | Gitea: sæt `organization`, `repository` og `user` til **Read and Write**. GitHub: sæt flueben ved `repo` |
| Gitea svarer `required=[write:user]` | projektet oprettes under din egen konto | sæt `user` til **Read and Write** |
| `Gitea owner '...' is neither your account (...) nor an organization the token can see` | tokenet er begrænset til **Public only**, eller ejernavnet er forkert | gør tokenet **All (public, private, and limited)**, eller ret ejeren |
| `GitHub owner '...' is neither your account (...) nor an organization you belong to (or the token lacks the read:org scope)` | tokenet kan ikke se organisationen | sæt flueben ved `read:org`, og godkend tokenet til organisationen, hvis den bruger single sign-on |
| det indsatte token bliver afvist igen og igen | mellemrum, et linjeskift eller anførselstegn fulgte med indsætningen | kopiér det igen og indsæt kun tokenet |
| `GITHUB_USER is '...' but the token belongs to '...'` | en advarsel: navnet i `.env` er ikke tokenets konto | ingen handling nødvendig; RepoFoundry bruger den konto, tokenet tilhører |
