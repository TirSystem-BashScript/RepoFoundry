<!-- translation of Troubleshooting.md, source sha256 da17de6a5d61 -->

> Ini ialah terjemahan [`Troubleshooting`](Troubleshooting). Halaman bahasa Inggeris ialah teks yang sah, dan perubahan di sini akan ditimpa pada penerbitan wiki yang seterusnya.

[English](Troubleshooting) | [Dansk](Troubleshooting.da) | Bahasa Melayu

# Diagnosis

| Gejala | Perkara yang perlu disemak |
| --- | --- |
| Pelan menyatakan ujian SSH gagal | Kunci anda ada dalam akaun Gitea anda, kunci hos dikenali (`ssh -p 10022 -T git@git.tirsystem.com`), dan kunci dengan frasa laluan dimuatkan dengan `ssh-add` |
| Skrip berhenti pada semakan alat | bash ialah 4.4 atau lebih baharu, dan `git` serta `curl` dipasang |
| Hos menolak token | Token masih sah dan mempunyai skop yang disenaraikan dalam [SSH dan token](SshAndTokens.ms) |
| Larian berhenti separuh jalan | Betulkan puncanya dan jalankan arahan yang sama sekali lagi dengan `--apply`: apa yang telah dicipta ditawarkan untuk digunakan semula |

Lagi: [Error handling and recovery](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/src/branch/main/README.md#error-handling-and-recovery) dan [Known limitations](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/src/branch/main/README.md#known-limitations) dalam README.
