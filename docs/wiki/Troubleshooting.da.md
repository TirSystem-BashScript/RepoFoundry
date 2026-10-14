<!-- translation of Troubleshooting.md, source sha256 da17de6a5d61 -->

> Dette er en oversættelse af [`Troubleshooting`](Troubleshooting). Den engelske side er autoritativ, og ændringer her bliver overskrevet, næste gang wikien publiceres.

[English](Troubleshooting) | Dansk | [Bahasa Melayu](Troubleshooting.ms)

# Fejlfinding

| Symptom | Hvad du skal kontrollere |
| --- | --- |
| Planen siger, at SSH-testen mislykkedes | Din nøgle er i din Gitea-konto, hostnøglen er kendt (`ssh -p 10022 -T git@git.tirsystem.com`), og en nøgle med adgangskode er indlæst med `ssh-add` |
| Scriptet stopper ved værktøjskontrollen | bash er 4.4 eller nyere, og `git` og `curl` er installeret |
| En vært afviser tokenet | Tokenet er gyldigt og har de scopes, der står under [SSH og tokens](SshAndTokens.da) |
| En kørsel stoppede undervejs | Ret årsagen og kør den samme kommando igen med `--apply`: det, der allerede er oprettet, tilbydes genbrugt |

Mere: [Error handling and recovery](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/src/branch/main/README.md#error-handling-and-recovery) og [Known limitations](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/src/branch/main/README.md#known-limitations) i README.
