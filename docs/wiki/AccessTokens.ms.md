<!-- translation of AccessTokens.md, source sha256 5b50dc96a057 -->

> Ini ialah terjemahan [`AccessTokens`](AccessTokens). Halaman bahasa Inggeris ialah teks yang sah, dan perubahan di sini akan ditimpa pada penerbitan wiki yang seterusnya.

[English](AccessTokens) | [Dansk](AccessTokens.da) | Bahasa Melayu

# Cara mencipta token akses yang diperlukan RepoFoundry

RepoFoundry berhubung dengan dua hos dan memerlukan satu token untuk setiap satu:

| Token | Kunci | Diperlukan | Jenis |
| --- | --- | --- | --- |
| Token akses Gitea | `GITEA_TOKEN` | sentiasa | token akses dengan skop |
| GitHub personal access token | `GITHUB_PAT` | diperlukan apabila anda memilih GitHub (cermin) | personal access token **klasik** (PAT) |
| Token akses Gitea untuk wiki | `TOKEN_FOR_GITEA_WIKI` | pilihan (hanya untuk menerbitkan wiki) | token akses dengan skop tulis repositori sahaja (`write:repository`) |

`TOKEN_FOR_GITEA_WIKI` tidak digunakan oleh RepoFoundry. Ia disenaraikan kerana `.env` yang sama mungkin mengandunginya, dan RepoFoundry menerimanya di situ. Cipta ia dengan cara yang sama seperti token Gitea dalam bahagian 1, dan tandakan skop tulis repositori sahaja.

Panduan ini menunjukkan dua yang pertama, langkah demi langkah. Nombor merah dalam setiap gambar sepadan dengan langkah bernombor di sebelahnya.

> **Tentang gambar.** Ia ialah lukisan halaman, bukan tangkapan skrin, supaya tiada data akaun dipaparkan. Nama, warna dan kedudukan sesuatu kawalan mungkin sedikit berbeza dalam versi Gitea atau GitHub anda. Perkataan bercetak tebal dalam langkah ialah label yang perlu dicari. Token baharu ditunjukkan sebagai titik dalam gambar; pada skrin anda, anda melihat nilai sebenarnya.

Senarai penuh perkara yang dibenarkan oleh setiap token terdapat di bawah [Token permissions](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/src/branch/main/README.md#token-permissions) dalam README. Panduan ini ialah versi klik demi klik daripadanya.

Kandungan:

1. [Cipta token akses Gitea](#1-cipta-token-akses-gitea)
2. [Cipta GitHub personal access token (klasik)](#2-cipta-github-personal-access-token-klasik)
3. [Berikan token kepada RepoFoundry](#3-berikan-token-kepada-repofoundry)
4. [Simpan token dengan selamat](#4-simpan-token-dengan-selamat)
5. [Jika sesuatu tidak berjalan lancar](#5-jika-sesuatu-tidak-berjalan-lancar)

---

## 1. Cipta token akses Gitea

Contoh menggunakan `https://git.tirsystem.com`. Jika Gitea anda berada di tempat lain, gunakan alamat yang anda tetapkan sebagai `GITEA_URL` dalam `config.env`.

### Langkah 1. Buka tetapan anda

Log masuk ke Gitea. Klik **avatar** anda di penjuru kanan atas (1), kemudian pilih **Settings** (2).

![Langkah 1: menu avatar di penjuru kanan atas dengan Settings ditonjolkan](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/raw/branch/main/docs/wiki/img/gitea-1-open-settings.png)

### Langkah 2. Buka "Applications"

Dalam menu di sebelah kiri, klik **Applications** (1).

Anda juga boleh terus ke sana: `<alamat Gitea anda>/user/settings/applications`.

![Langkah 2: entri Applications dalam menu kiri tetapan](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/raw/branch/main/docs/wiki/img/gitea-2-applications.png)

### Langkah 3. Isi borang token

Tatal ke **Generate New Token** dan isikannya:

1. **Token Name:** nama yang anda akan kenali kemudian, contohnya `RepoFoundry`.
2. **Repository and Organization Access:** pilih **All (public, private, and limited)**. Token yang terhad kepada **Public only** tidak dapat melihat repositori atau organisasi persendirian, jadi mencipta projek persendirian akan gagal.
3. **Select permissions:** tetapkan ketiga-tiga ini kepada **Read and Write** dan biarkan setiap baris lain pada **No Access**:

   | Permission | Tahap | Mengapa RepoFoundry memerlukannya |
   | --- | --- | --- |
   | `organization` | Read and Write | mencari pemilik dan hak anda di dalamnya, mencipta repositori dalam organisasi |
   | `repository` | Read and Write | mencipta repositori dan mengurus cermin push-nya |
   | `user` | Read and Write | membaca akaun yang memiliki token, dan mencipta repositori di bawah akaun **anda sendiri** |

4. Klik **Generate Token**.

![Langkah 3: borang token dengan nama, pilihan akses dan tiga permission ditetapkan kepada Read and Write](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/raw/branch/main/docs/wiki/img/gitea-3-token-form.png)

> **Hanya mencipta projek dalam organisasi?** Maka `user` boleh kekal pada **Read**. `Read and Write` pada `user` hanya diperlukan untuk mencipta repositori di bawah akaun anda sendiri; tanpanya Gitea menjawab `required=[write:user]`.

### Langkah 4. Salin token sekarang

Gitea menunjukkan token baharu **sekali sahaja**, dalam mesej hijau di bahagian atas halaman (1). Salinnya (gunakan butang salin jika versi anda ada, atau pilih teks dan tekan Ctrl+C, Cmd+C pada Mac) dan simpan untuk [bahagian 3 panduan ini](#3-berikan-token-kepada-repofoundry). Token baharu kini berada dalam senarai di bawahnya (2), bersama permission-nya, tetapi senarai itu tidak pernah menunjukkan nilainya lagi.

Jika anda kehilangan nilai itu, padam token tersebut dan jana yang baharu.

![Langkah 4: mesej hijau dengan token baharu dan butang Copy, serta token dalam senarai di bawah](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/raw/branch/main/docs/wiki/img/gitea-4-copy-token.png)

---

## 2. Cipta GitHub personal access token (klasik)

Langkau bahagian ini jika anda tidak akan mencipta repositori GitHub (`USE_GITHUB=no` atau menjawab tidak apabila ditanya). `GITHUB_PAT` tidak diperlukan.

Gunakan token **klasik**. RepoFoundry belum diuji dengan token fine-grained, kerana GitHub tidak mendokumenkan permission fine-grained untuk mencipta repositori.

### Langkah 1. Buka tetapan anda

Log masuk ke GitHub. Klik **gambar profil** anda di penjuru kanan atas (1), kemudian **Settings** (2).

![Langkah 1: menu profil di penjuru kanan atas dengan Settings ditonjolkan](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/raw/branch/main/docs/wiki/img/github-1-open-settings.svg)

### Langkah 2. Buka "Developer settings"

Dalam bar sisi kiri, tatal ke bahagian bawah dan klik **Developer settings** (1). Ia ialah entri terakhir.

![Langkah 2: Developer settings di bahagian bawah bar sisi kiri](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/raw/branch/main/docs/wiki/img/github-2-developer-settings.svg)

### Langkah 3. Pilih "Tokens (classic)"

1. Dalam bar sisi kiri, buka **Personal access tokens** dan klik **Tokens (classic)** (1).
2. Klik **Generate new token** (2).
3. Dalam menu yang terbuka, pilih **Generate new token (classic)** (3). Bukan entri pertama, iaitu jenis fine-grained.

GitHub mungkin meminta anda mengesahkan kata laluan atau kod dua faktor. Lakukannya sendiri; tiada orang lain patut menaipnya.

![Langkah 3: Tokens (classic) dalam bar sisi, dan Generate new token (classic) dalam menu butang](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/raw/branch/main/docs/wiki/img/github-3-tokens-classic.svg)

> Alamat terus: `https://github.com/settings/tokens/new`

### Langkah 4. Isi borang

1. **Note:** nama yang anda akan kenali kemudian, contohnya `RepoFoundry`.
2. **Expiration:** pilih tarikh. Hayat yang lebih pendek mengehadkan kerosakan jika token bocor; anda kemudian mencipta token baharu apabila ia tamat.
3. **Select scopes:** tandakan skop di bawah dan tiada yang lain.

   | Skop | Tandakan apabila | Sebab |
   | --- | --- | --- |
   | `repo` | sentiasa (projek persendirian atau awam) | mencipta repositori, dan ialah kata laluan yang digunakan Gitea untuk mem-push cermin |
   | `public_repo` sebagai ganti `repo` | **hanya** projek awam | cukup untuk mencipta dan mem-push repositori awam; menandakan `repo` sudah merangkumnya |
   | `read:org` | hanya jika skrip berkata anda bukan ahli organisasi anda | membolehkan skrip menyemak keahlian anda dalam organisasi pemilik |

   Menandakan `repo` turut menandakan lima sub-skopnya (`repo:status`, `repo_deployment`, `public_repo`, `repo:invite`, `security_events`); itu dijangka. Biarkan `workflow`, `write:packages` dan yang lain tidak bertanda.

4. Tatal ke bawah dan klik **Generate token** (4).

![Langkah 4: borang token baharu dengan nota, tarikh luput, skop repo ditandakan dan butang Generate token](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/raw/branch/main/docs/wiki/img/github-4-token-form.svg)

> **`read:org` dan `admin:org`.** README mencatatkan bahawa semakan itu berjaya dengan token yang mempunyai `repo` dan `admin:org`, dan bahawa `read:org` sahaja belum diuji. Cuba `read:org` dahulu. `admin:org` memberi kuasa jauh lebih banyak daripada yang diperlukan RepoFoundry, jadi gunakannya hanya jika `read:org` tidak mencukupi.

### Langkah 5. Salin token sekarang

GitHub menunjukkan token **sekali sahaja**, dalam kotak hijau di bahagian atas (1). Klik ikon salin di sebelahnya. Ia bermula dengan `ghp_`. Simpan untuk [bahagian 3 panduan ini](#3-berikan-token-kepada-repofoundry).

Jika pemilik repositori baharu ialah organisasi yang menggunakan SAML single sign-on, token juga mesti dibenarkan untuk organisasi itu: dalam senarai token, klik **Configure SSO** (2) di sebelah token dan kemudian **Authorize** untuk organisasi.

![Langkah 5: kotak hijau dengan token baharu dan ikon salin, serta Configure SSO dalam senarai token](https://git.tirsystem.com/TirSystem-BashScript/repo-foundry/raw/branch/main/docs/wiki/img/github-5-copy-token.svg)

---

## 3. Berikan token kepada RepoFoundry

Pilih satu cara. Kedua-duanya mengekalkan token di luar `config.env` (token di situ ditolak).

**Pilihan A: taip apabila ditanya (tiada apa disimpan).** Jangan buat apa-apa terlebih dahulu. RepoFoundry meminta `Gitea access token` pada permulaan, dan `GitHub personal access token` serta `GitHub account name` setelah anda memilih GitHub. Apa yang anda taip tidak dipaparkan pada skrin. Tampal token sahaja, tanpa ruang, pemisah baris atau tanda petik.

**Pilihan B: simpan dalam `.env` (mudah, teks biasa pada cakera).** Dalam folder RepoFoundry:

```bash
cp .env.example .env
chmod 600 .env          # Linux dan macOS: hanya anda boleh membacanya
```

Buka `.env` dan isi nilai; gantikan teks dalam kurungan sudut dan buang kurungan itu:

```text
GITEA_TOKEN=<token Gitea>
GITHUB_PAT=<token GitHub>
GITHUB_USER=<nama akaun GitHub anda>
TOKEN_FOR_GITEA_WIKI=<token Gitea untuk wiki, skop tulis repositori sahaja>
```

`GITHUB_PAT` dan `GITHUB_USER` hanya diperlukan apabila anda memilih GitHub (cermin); tinggalkannya jika tidak. `TOKEN_FOR_GITEA_WIKI` ialah pilihan dan hanya diperlukan untuk menerbitkan wiki. Git mengabaikan `.env`. Jangan sekali-kali commit, hantar atau tampal ia dalam sembang atau issue.

Kemudian semak persediaan dengan larian percubaan, yang hanya membaca daripada hos dan tidak mencipta apa-apa:

```bash
src/create-project.sh
```

---

## 4. Simpan token dengan selamat

- Token ialah kata laluan. Sesiapa yang memilikinya boleh melakukan apa yang dibenarkannya.
- Berikan setiap token hanya akses yang terdapat dalam panduan ini, dan tarikh luput.
- Jangan tampal token dalam baris perintah, URL, commit, issue atau sembang.
- Jika token mungkin telah bocor, padamnya serta-merta dan cipta yang baharu:
  - Gitea: **Settings**, **Applications**, kemudian **Delete** pada token itu.
  - GitHub: **Settings**, **Developer settings**, **Personal access tokens**, **Tokens (classic)**, kemudian **Delete** pada token itu.
- Apabila token tamat tempoh, cipta yang baharu dengan cara yang sama dan gantikannya dalam `.env`.

---

## 5. Jika sesuatu tidak berjalan lancar

| Apa yang anda lihat | Punca yang mungkin | Apa yang perlu dibuat |
| --- | --- | --- |
| `authentication failed: the token is missing, expired or invalid` | token tersalah taip, telah tamat tempoh atau telah dipadam | cipta token baharu dan gunakannya |
| `the token is valid but not allowed to do this (check its scopes)` | sesuatu permission tiada | Gitea: tetapkan `organization`, `repository` dan `user` kepada **Read and Write**. GitHub: tandakan `repo` |
| Gitea menjawab `required=[write:user]` | projek dicipta di bawah akaun anda sendiri | tetapkan `user` kepada **Read and Write** |
| `Gitea owner '...' is neither your account (...) nor an organization the token can see` | token terhad kepada **Public only**, atau nama pemilik salah | jadikan token **All (public, private, and limited)**, atau betulkan pemilik |
| `GitHub owner '...' is neither your account (...) nor an organization you belong to (or the token lacks the read:org scope)` | token tidak dapat melihat organisasi | tandakan `read:org`, dan benarkan token untuk organisasi jika ia menggunakan single sign-on |
| token yang ditampal ditolak berulang kali | ruang, pemisah baris atau tanda petik turut tertampal | salin semula dan tampal token sahaja |
| `GITHUB_USER is '...' but the token belongs to '...'` | amaran: nama dalam `.env` bukan akaun pemilik token | tiada tindakan diperlukan; RepoFoundry menggunakan akaun yang memiliki token |
