<!-- translation of UpdatingTheFramework.md, source sha256 3e450f6c8f34 -->

> Ini ialah terjemahan [`UpdatingTheFramework`](UpdatingTheFramework). Halaman bahasa Inggeris ialah teks yang sah, dan perubahan di sini akan ditimpa pada penerbitan wiki yang seterusnya.

[English](UpdatingTheFramework) | [Dansk](UpdatingTheFramework.da) | Bahasa Melayu

# Mengemas kini framework

Projek yang dicipta oleh Repo Foundry menyimpan SQA-QC-Framework sebagai submodul git `framework`. Clone atau `git pull` tidak menggerakkannya: projek kekal pada commit framework yang direkodkannya. Untuk memastikan framework sentiasa terkini, jalankan ini dalam projek, dari akarnya:

```bash
git submodule update --init --remote --recursive framework
```

| Bahagian | Sebab |
| --- | --- |
| `--init` | mengambil submodul jika ia belum ada |
| `--remote` | menggerakkan `framework` ke commit terkini repositori framework, bukannya commit yang direkodkan oleh projek |
| `--recursive` | turut mengemas kini submodul yang dimiliki framework sendiri (`framework/qc`, senarai semak) |

## Selepas kemas kini

1. Pasang semula skill, supaya salinan dalam `.claude/skills/` dan `.agents/skills/` sepadan dengan framework baharu:

   ```bash
   bash framework/scripts/install-skills.sh
   ```

2. Semak apa yang berubah, kemudian commit commit framework baharu pada sebuah branch (hook framework menolak commit pada `main`):

   ```bash
   git status
   git switch -c update-framework
   git add framework
   git commit -m "Update the framework"
   ```

3. Kemas kini `AGENTS.md` (bahagian seterusnya).

## Kemas kini AGENTS.md kepada templat terkini

`AGENTS.md` dalam projek anda disalin daripada `framework/templates/AGENTS-template.md` semasa projek dicipta. Ia ialah salinan, jadi ia tidak berubah apabila framework berubah. Templat itu mengandungi peraturan yang dijangka oleh skill dan hook framework (contohnya mod diselia dan mod autonomi), jadi kemas kininya selepas setiap kemas kini framework.

1. Lihat apa yang berbeza:

   ```bash
   diff -u AGENTS.md framework/templates/AGENTS-template.md
   ```

2. Jika anda tidak pernah mengedit `AGENTS.md`, gantikannya:

   ```bash
   cp framework/templates/AGENTS-template.md AGENTS.md
   ```

3. Jika anda menambah peraturan sendiri, salin bahagian templat yang baharu atau berubah ke dalam `AGENTS.md` secara manual dan kekalkan peraturan anda. Menggantikan fail akan menghilangkannya.

Repo Foundry menambah `/AGENTS.md` ke `.git/info/exclude` dalam projek baharu, jadi git tidak menyenaraikan fail itu dan perubahan itu bukan commit: ia hanya memberi kesan kepada salinan kerja anda. Jangan gantikan `docs/artifact-registry.md` dengan cara yang sama: ia mengandungi baris projek anda sendiri, jadi bandingkannya sahaja dengan `framework/templates/artifact-registry-template.md` dan salin apa yang anda perlukan.

## Nota

- `--remote` mengikuti branch lalai repositori framework, bukan tag keluaran. Untuk kekal pada keluaran, checkout tag di dalam submodul: `git -C framework checkout <tag>`, kemudian commit `framework` seperti di atas.
- Orang lain yang meng-clone projek, atau menarik commit anda, mendapat commit framework yang direkodkan dengan `git submodule update --init --recursive`.
- Submodul diambil melalui SSH pada port 10022, jadi [persediaan SSH](SshAndTokens.ms) juga terpakai untuk kemas kini.
