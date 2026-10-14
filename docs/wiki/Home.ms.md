<!-- translation of Home.md, source sha256 054f37c6e99b -->

> Ini ialah terjemahan [`Home`](Home). Halaman bahasa Inggeris ialah teks yang sah, dan perubahan di sini akan ditimpa pada penerbitan wiki yang seterusnya.

[English](Home) | [Dansk](Home.da) | Bahasa Melayu

# Repo Foundry

Repo Foundry (`src/create-project.sh`) menyediakan projek baharu dalam satu larian:

- repositori **Gitea**, iaitu sumber yang sah;
- secara pilihan repositori **GitHub** kosong yang menerima semuanya melalui push mirror dari Gitea;
- **projek tempatan** dengan satu remote tanpa kelayakan (credentials), `origin`, dan SQA-QC-Framework sebagai submodul git, dengan skill, git hook dan templatnya terpasang.

> **Akses kepada framework.** SQA-QC-Framework dilindungi hak cipta dan anda tidak mempunyai akses kepadanya secara lalai. Hubungi [Jens Tirsvad](https://www.linkedin.com/in/tirsvad74/) untuk mendapatkan akses. Laman web dengan maklumat hubungan kami akan tersedia di <https://www.tirsystem.com>.

Ia ialah skrip Bash. Ia memaparkan pelan dahulu dan tidak mencipta apa-apa sehingga anda memberikan `--apply` dan menjawab ya.

## Halaman

| Halaman | Kandungan |
| --- | --- |
| [Bermula](GettingStarted.ms) | Keperluan, pemasangan dan larian pertama |
| [SSH dan token](SshAndTokens.ms) | Akses SSH ke Gitea dan dua token akses |
| [Token akses](AccessTokens.ms) | Cipta token akses langkah demi langkah dengan gambar |
| [Mengemas kini framework](UpdatingTheFramework.ms) | Pastikan submodul framework projek sentiasa terkini |
| [Diagnosis](Troubleshooting.ms) | Kegagalan lazim dan tindakan yang perlu diambil |

Rujukan penuh (fail konfigurasi, keputusan keselamatan, pengendalian ralat, had yang diketahui) ialah [README](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/src/branch/main/README.md).
Laporkan masalah sebagai [issue](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/issues).
